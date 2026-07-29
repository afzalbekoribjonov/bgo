import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  OnModuleInit,
} from '@nestjs/common';
import {
  CANCEL_REASON_CUSTOMER_FAULT,
  DriverCancelReason,
  isDriverCancelReason,
} from '../common/cancel-reasons';
import { DispatchService } from '../orders/dispatch.service';
import { DriverInfoClient } from '../driver-client/driver-info.client';
import { EarningsSummary, summarizeEarnings } from '../common/earnings';
import { GeoPoint, haversineKm } from '../common/geo';
import { roundFare } from '../common/money';
import {
  buildVerticalReport,
  buildVerticalReportRange,
  buildVerticalStats,
  ReportPeriod,
} from '../common/reporting';
import { NotificationClient } from '../notification-client/notification.client';
import { TariffService } from '../tariff/tariff.service';
import { DriverLocation } from '../tracking/entities';
import { DriverLocationService } from '../tracking/driver-location.service';
import { EstimateParcelDto, RequestParcelDto } from './dto/request-parcel.dto';
import {
  ChatRole,
  ParcelDelivery,
  ParcelDeliveryLive,
  ParcelMessage,
  ParcelSize,
  ParcelStatusEntry,
} from './entities';
import { ParcelMessageRepository } from './parcel-message.repository';
import { ParcelRepository } from './parcel.repository';

/** O'lcham koeffitsienti — yirik posilka qimmatroq. */
const SIZE_MULTIPLIER: Record<ParcelSize, number> = {
  SMALL: 1.0,
  MEDIUM: 1.3,
  LARGE: 1.6,
};

/** Suhbatning birinchi xabari oldidan qo'yiladigan salom. */
const CHAT_GREETING = 'Assalomu alaykum, ';

/** Dostavka (pochta) — narx SERVER tomonda (tarif + masofa + o'lcham). */
@Injectable()
export class ParcelService implements OnModuleInit {
  constructor(
    private readonly repo: ParcelRepository,
    private readonly tariff: TariffService,
    private readonly notifications: NotificationClient,
    private readonly dispatch: DispatchService,
    private readonly driverInfo: DriverInfoClient,
    private readonly messages: ParcelMessageRepository,
    private readonly driverLocations: DriverLocationService,
  ) {}

  private readonly logger = new Logger(ParcelService.name);

  /** Restart tiklanishi: PENDING dostavkalarni qayta dispatch qilish. */
  onModuleInit(): void {
    setTimeout(() => {
      this.recoverPendingParcels().catch((e) =>
        this.logger.warn(`Dostavka dispatch tiklanishi xatosi: ${(e as Error).message}`),
      );
    }, 2000);
  }

  private async recoverPendingParcels(): Promise<void> {
    const pending = await this.repo.findAvailable();
    if (pending.length === 0) return;
    this.logger.log(
      `Dispatch tiklanishi: ${pending.length} ta dostavka qayta yuborilmoqda`,
    );
    await Promise.all(pending.map((p) => this.offerParcel(p)));
  }

  /** Biriktirilgan kuryerning jonli joylashuvi (xaritada ko'rsatish uchun). */
  async driverLocationForParcel(
    customerId: string,
    id: string,
  ): Promise<DriverLocation | null> {
    const parcel = await this.getOwned(customerId, id);
    if (!parcel.driverId) return null;
    return this.driverLocations.get(parcel.driverId);
  }

  /** Safar davomiyligi (daqiqa) — IN_TRANSIT dan DELIVERED/hozirgacha. */
  private durationMinutes(p: ParcelDelivery): number {
    const hist = p.statusHistory ?? [];
    const start = hist.find((h: ParcelStatusEntry) => h.status === 'IN_TRANSIT');
    if (!start) return 0;
    const end = hist.find((h: ParcelStatusEntry) => h.status === 'DELIVERED');
    const s = Date.parse(start.at);
    const e = end ? Date.parse(end.at) : Date.now();
    return Math.max(0, Math.round((e - s) / 60000));
  }

  /** Jonli ko'rinish — narx + faol dostavkada kuryer ma'lumoti (mijozga). */
  async toLive(parcel: ParcelDelivery): Promise<ParcelDeliveryLive> {
    let driverName: string | null | undefined;
    let driverCar: string | null | undefined;
    let driverPlate: string | null | undefined;
    let driverPhone: string | null | undefined;
    let customerPhone: string | null | undefined;
    let driverRating: number | undefined;
    let driverRatingCount: number | undefined;
    const active = ['ACCEPTED', 'ARRIVED', 'PICKED_UP', 'IN_TRANSIT'].includes(
      parcel.status,
    );
    if (parcel.driverId && active) {
      const [info, stats, dPhone, cPhone] = await Promise.all([
        this.driverInfo.getPublic(parcel.driverId),
        this.repo.driverRatingStats(parcel.driverId),
        this.driverInfo.getUserPhone(parcel.driverId),
        this.driverInfo.getUserPhone(parcel.customerId),
      ]);
      if (info) {
        driverName = info.fullName;
        driverCar = info.carName ?? null;
        driverPlate = info.plateNumber ?? null;
      }
      driverPhone = dPhone;
      customerPhone = cPhone;
      driverRating = stats.avg;
      driverRatingCount = stats.count;
    }
    return {
      ...parcel,
      currentFare: parcel.fare,
      durationMinutes: this.durationMinutes(parcel),
      driverName,
      driverCar,
      driverPlate,
      driverPhone,
      customerPhone,
      driverRating,
      driverRatingCount,
    };
  }

  async liveForCustomer(
    customerId: string,
    id: string,
  ): Promise<ParcelDeliveryLive> {
    return this.toLive(await this.getOwned(customerId, id));
  }

  async liveForDriver(driverId: string, id: string): Promise<ParcelDeliveryLive> {
    return this.toLive(await this.requireDriverParcel(id, driverId));
  }

  /** Kuryerning faol dostavkalari (jonli) — ilova qayta ochilganda tiklash. */
  async listActiveDriverParcels(driverId: string): Promise<ParcelDeliveryLive[]> {
    const parcels = await this.repo.findByDriver(driverId);
    const active = parcels.filter((p) =>
      ['ACCEPTED', 'ARRIVED', 'PICKED_UP', 'IN_TRANSIT'].includes(p.status),
    );
    return Promise.all(active.map((p) => this.toLive(p)));
  }

  /** Yangi dostavkani eng yaqin online haydovchiga taklif qiladi. */
  private async offerParcel(parcel: ParcelDelivery): Promise<void> {
    await this.dispatch.offer({
      orderId: parcel.id,
      vertical: 'parcel',
      pickupLat: parcel.pickup.lat,
      pickupLng: parcel.pickup.lng,
      pickupName: parcel.pickup.text || 'Dostavka',
      dropoffLat: parcel.destination?.lat ?? null,
      dropoffLng: parcel.destination?.lng ?? null,
      dropoffText: parcel.destination?.text ?? null,
      amount: parcel.fare,
      earning: parcel.driverEarning,
    });
  }

  async estimate(pickup: GeoPoint, destination: GeoPoint, size: ParcelSize) {
    const t = await this.tariff.getTariff();
    const distanceKm = Math.round(haversineKm(pickup, destination) * 100) / 100;
    const base = Math.max(
      t.parcelMinFare,
      t.parcelBaseFare + Math.round(t.parcelPerKm * distanceKm),
    );
    const fare = roundFare(Math.round(base * SIZE_MULTIPLIER[size]));
    const commission = Math.round((fare * t.parcelCommissionPercent) / 100);
    return { distanceKm, size, fare, commission, driverEarning: fare - commission };
  }

  async create(customerId: string, dto: RequestParcelDto): Promise<ParcelDelivery> {
    const e = await this.estimate(dto.pickup, dto.destination, dto.size);
    const parcel = await this.repo.create({
      customerId,
      pickup: dto.pickup,
      destination: dto.destination,
      distanceKm: e.distanceKm,
      size: dto.size,
      recipientName: dto.recipientName,
      recipientPhone: dto.recipientPhone,
      note: dto.note,
      fare: e.fare,
      commission: e.commission,
      driverEarning: e.driverEarning,
    });
    this.offerParcel(parcel).catch((err) =>
      this.logger.warn(`Dostavka taklif xatosi: ${(err as Error).message}`),
    );
    return parcel;
  }

  estimateDto(dto: EstimateParcelDto) {
    return this.estimate(dto.pickup, dto.destination, dto.size);
  }

  async listMine(customerId: string): Promise<ParcelDeliveryLive[]> {
    const parcels = await this.repo.findByCustomer(customerId);
    return Promise.all(parcels.map((p) => this.toLive(p)));
  }

  /** Mijoz uchun bitta dostavka (jonli). */
  async getOwnedLive(customerId: string, id: string): Promise<ParcelDeliveryLive> {
    return this.toLive(await this.getOwned(customerId, id));
  }

  /** Mijoz dostavkani baholaydi (yetkazilgandan keyin). */
  async rate(
    customerId: string,
    id: string,
    rating: number,
    comment?: string,
  ): Promise<ParcelDelivery> {
    const parcel = await this.getOwned(customerId, id);
    if (parcel.status !== 'DELIVERED') {
      throw new BadRequestException('Faqat yetkazilgan dostavkani baholash mumkin');
    }
    if (rating < 1 || rating > 5) {
      throw new BadRequestException('Baho 1-5 oralig\'ida bo\'lishi kerak');
    }
    return this.repo.setRating(id, rating, comment);
  }

  async getOwned(customerId: string, id: string): Promise<ParcelDelivery> {
    const parcel = await this.repo.findById(id);
    if (!parcel) throw new NotFoundException('Dostavka topilmadi');
    if (parcel.customerId !== customerId) {
      throw new ForbiddenException('Bu dostavka sizga tegishli emas');
    }
    return parcel;
  }

  /** Mijoz bekor qiladi — PENDING/ACCEPTED/ARRIVED (olinmaguncha). */
  async cancel(customerId: string, id: string): Promise<ParcelDelivery> {
    const parcel = await this.getOwned(customerId, id);
    if (!['PENDING', 'ACCEPTED', 'ARRIVED'].includes(parcel.status)) {
      throw new BadRequestException('Dostavkani bu bosqichda bekor qilib bo\'lmaydi');
    }
    this.dispatch.clear(id);
    const cancelled = await this.repo.updateStatus(id, 'CANCELLED', {
      by: 'customer',
      driverId: parcel.driverId,
    });
    if (parcel.driverId) {
      await this.notifications.notify(
        parcel.driverId,
        'Dostavka',
        'Mijoz dostavkani bekor qildi',
        { type: 'parcel', id, status: 'CANCELLED', cancelledBy: 'customer' },
      );
    }
    await this.messages.deleteByParcel(id).catch(() => undefined);
    return cancelled;
  }

  // ---------- Kuryer ----------

  listAvailable() {
    return this.repo.findAvailable();
  }

  listDriverParcels(driverId: string) {
    return this.repo.findByDriver(driverId);
  }

  // ---------- Admin hisobot ----------

  /** Dostavka davr hisoboti (admin jamlash uchun). */
  async adminReport(period: ReportPeriod) {
    const parcels = await this.repo.findAll();
    return buildVerticalReport(parcels, period, {
      createdAtOf: (p) => p.createdAt,
      isDone: (p) => p.status === 'DELIVERED',
      isCancelled: (p) => p.status === 'CANCELLED',
      revenueOf: (p) => p.fare,
      profitOf: (p) => p.commission,
    });
  }

  /** Dostavka hisoboti — ixtiyoriy sana oralig'i (istalgan kun/oy). */
  async adminReportRange(from: Date, to: Date) {
    const parcels = await this.repo.findAll();
    return buildVerticalReportRange(parcels, from, to, {
      createdAtOf: (p) => p.createdAt,
      isDone: (p) => p.status === 'DELIVERED',
      isCancelled: (p) => p.status === 'CANCELLED',
      revenueOf: (p) => p.fare,
      profitOf: (p) => p.commission,
    });
  }

  /** Dostavka umumiy statistikasi (aylanma/foyda). */
  async adminStats() {
    const parcels = await this.repo.findAll();
    return buildVerticalStats(parcels, {
      isDone: (p) => p.status === 'DELIVERED',
      revenueOf: (p) => p.fare,
      profitOf: (p) => p.commission,
    });
  }

  /** Admin: bitta dostavkani to'liq holida (barcha maydonlar). */
  async adminGetById(id: string): Promise<ParcelDelivery | null> {
    return this.repo.findById(id);
  }

  /** Admin: dostavkalarni filtrlangan ro'yxat. */
  async adminListDeliveries(filter: {
    status?: string;
    from?: string;
    to?: string;
    driverId?: string;
    q?: string;
  }): Promise<ParcelDelivery[]> {
    const fromTs = filter.from ? new Date(filter.from.length === 10 ? `${filter.from}T00:00:00.000` : filter.from).getTime() : undefined;
    const toTs = filter.to ? new Date(filter.to.length === 10 ? `${filter.to}T23:59:59.999` : filter.to).getTime() : undefined;
    const q = filter.q?.trim().toLowerCase();
    const parcels = await this.repo.findAll();
    return parcels.filter((p) => {
      if (filter.status && p.status !== filter.status) return false;
      if (filter.driverId && p.driverId !== filter.driverId) return false;
      const ts = new Date(p.createdAt).getTime();
      if (fromTs !== undefined && ts < fromTs) return false;
      if (toTs !== undefined && ts > toTs) return false;
      if (q) {
        const hay = `${p.publicNo} ${p.pickup?.text ?? ''}`.toLowerCase();
        if (!hay.includes(q)) return false;
      }
      return true;
    });
  }

  /** Admin: haydovchi faol dostavkasini bekor qiladi. */
  async adminCancel(id: string): Promise<ParcelDelivery | null> {
    const parcel = await this.repo.findById(id);
    if (!parcel) return null;
    if (['DELIVERED', 'CANCELLED'].includes(parcel.status)) return parcel;
    this.dispatch.clear(id);
    return this.repo.updateStatus(id, 'CANCELLED', {
      by: 'admin',
      driverId: parcel.driverId,
    });
  }

  /** Kuryer dostavka daromadi (EarningsSummary). */
  async driverEarnings(driverId: string): Promise<EarningsSummary> {
    const parcels = await this.repo.findByDriver(driverId);
    return summarizeEarnings(
      parcels,
      (p) => p.status === 'DELIVERED',
      (p) =>
        ['ACCEPTED', 'ARRIVED', 'PICKED_UP', 'IN_TRANSIT'].includes(p.status),
      (p) => p.driverEarning,
      (p) => p.updatedAt,
    );
  }

  /** Kuryer qabul qiladi (PENDING -> ACCEPTED). */
  async accept(id: string, driverId: string): Promise<ParcelDelivery> {
    const parcel = await this.repo.findById(id);
    if (!parcel) throw new NotFoundException('Dostavka topilmadi');
    if (parcel.status !== 'PENDING') {
      throw new BadRequestException('Dostavka qabul qilishga tayyor emas');
    }
    if (parcel.driverId) {
      throw new BadRequestException('Dostavka allaqachon biriktirilgan');
    }
    const updated = await this.repo.assignDriver(id, driverId);
    this.dispatch.clear(id);
    await this.notifyCustomer(updated, 'Kuryer dostavkani qabul qildi');
    return updated;
  }

  /** Jo'natuvchiga yetib keldi (ACCEPTED -> ARRIVED). "Yetib keldim" */
  async arrive(id: string, driverId: string): Promise<ParcelDelivery> {
    const parcel = await this.requireDriverParcel(id, driverId);
    if (parcel.status !== 'ACCEPTED') {
      throw new BadRequestException('Dostavka bu bosqichda emas');
    }
    const updated = await this.repo.updateStatus(id, 'ARRIVED');
    await this.notifyCustomer(updated, 'Kuryer jo\'natuvchiga yetib keldi');
    return updated;
  }

  /** Posilkani oldi (ARRIVED -> PICKED_UP). "Dastavkani oldim" */
  async pickup(id: string, driverId: string): Promise<ParcelDelivery> {
    const parcel = await this.requireDriverParcel(id, driverId);
    if (!['ARRIVED', 'ACCEPTED'].includes(parcel.status)) {
      throw new BadRequestException('Dostavka olishga tayyor emas');
    }
    const updated = await this.repo.updateStatus(id, 'PICKED_UP');
    await this.notifyCustomer(updated, 'Kuryer posilkani oldi');
    return updated;
  }

  /** Qabul qiluvchiga yo'lga chiqdi (PICKED_UP -> IN_TRANSIT). "Yo'lga chiqish" */
  async startTransit(id: string, driverId: string): Promise<ParcelDelivery> {
    const parcel = await this.requireDriverParcel(id, driverId);
    if (parcel.status !== 'PICKED_UP') {
      throw new BadRequestException('Dostavka yo\'lga chiqishga tayyor emas');
    }
    const updated = await this.repo.updateStatus(id, 'IN_TRANSIT');
    await this.notifyCustomer(updated, 'Kuryer qabul qiluvchiga yo\'lda');
    return updated;
  }

  /** Yetkazdi (IN_TRANSIT -> DELIVERED). "Safarni yakunlash" */
  async delivered(id: string, driverId: string): Promise<ParcelDelivery> {
    const parcel = await this.requireDriverParcel(id, driverId);
    if (!['IN_TRANSIT', 'PICKED_UP'].includes(parcel.status)) {
      throw new BadRequestException('Dostavka yetkazish holatida emas');
    }
    const updated = await this.repo.updateStatus(id, 'DELIVERED');
    await this.notifyCustomer(
      updated,
      `Posilka yetkazildi. To'lov: ${updated.fare} so'm`,
    );
    // Komissiyani kuryer balansidan yechamiz — balans/daromad darhol to'g'ri
    // ko'rinishi uchun javobdan OLDIN kutamiz (xato bo'lsa ham yiqilmaydi).
    try {
      await this.driverInfo.charge(
        driverId,
        updated.commission,
        `Dostavka #${updated.publicNo}`,
      );
    } catch (e) {
      this.logger.warn(`Komissiya yechishda xato: ${(e as Error).message}`);
    }
    await this.messages.deleteByParcel(id).catch(() => undefined);
    await this.driverInfo.recordCompletion(driverId);
    return updated;
  }

  /**
   * Kuryer bekor qiladi (ACCEPTED/ARRIVED) -> qayta dispatch. Sabab majburiy
   * — balansdan jarima yechiladi; mijoz aybi bo'lsa sezdirmasdan qaytariladi.
   */
  async driverCancel(
    id: string,
    driverId: string,
    reason: DriverCancelReason,
    note?: string,
  ): Promise<ParcelDelivery> {
    if (!isDriverCancelReason(reason)) {
      throw new BadRequestException("Bekor qilish sababini tanlang");
    }
    const parcel = await this.requireDriverParcel(id, driverId);
    if (!['ACCEPTED', 'ARRIVED'].includes(parcel.status)) {
      throw new BadRequestException('Bu bosqichda bekor qilib bo\'lmaydi');
    }
    await this.notifications.notify(
      parcel.customerId,
      'Dostavka',
      'Kuryer kela olmadi. Boshqa kuryer qidirilmoqda',
      { type: 'parcel', id, status: 'PENDING', cancelledBy: 'driver' },
    );
    // Eski kuryer bilan suhbatni tozalaymiz (yangi kuryer ko'rmasligi uchun).
    await this.messages.deleteByParcel(id).catch(() => undefined);
    const released = await this.repo.releaseToPending(id, reason, note);
    this.offerParcel(released).catch((e) =>
      this.logger.warn(`Qayta taklif xatosi: ${(e as Error).message}`),
    );
    try {
      const t = await this.tariff.getTariff();
      const penalty = t.driverCancelPenalty;
      if (penalty > 0) {
        await this.driverInfo.charge(driverId, penalty, `Dostavka #${parcel.publicNo} bekor qilindi`);
        if (CANCEL_REASON_CUSTOMER_FAULT[reason]) {
          await this.driverInfo.silentRefund(driverId, penalty, `Tuzatish: Dostavka #${parcel.publicNo}`);
        }
      }
    } catch (e) {
      this.logger.warn(`Bekor qilish jarimasi xatosi: ${(e as Error).message}`);
    }
    await this.driverInfo.recordCancellation(driverId);
    return released;
  }

  // ---------- Suhbat (mijoz↔kuryer) ----------

  /** Dostavka ishtirokchisi (mijoz yoki biriktirilgan kuryer) rolini aniqlaydi. */
  private async requireParticipant(
    parcelId: string,
    userId: string,
  ): Promise<{ parcel: ParcelDelivery; role: ChatRole }> {
    const parcel = await this.repo.findById(parcelId);
    if (!parcel) throw new NotFoundException('Dostavka topilmadi');
    if (parcel.customerId === userId) return { parcel, role: 'customer' };
    if (parcel.driverId === userId) return { parcel, role: 'driver' };
    throw new ForbiddenException('Bu dostavka suhbatiga ruxsat yo\'q');
  }

  /** Dostavka suhbati xabarlari (vaqt bo'yicha). */
  async listMessages(
    parcelId: string,
    userId: string,
  ): Promise<ParcelMessage[]> {
    await this.requireParticipant(parcelId, userId);
    return this.messages.listByParcel(parcelId);
  }

  /**
   * Xabar yuborish. Kuryer biriktirilgach mumkin. Suhbatning birinchi
   * xabari oldidan majburiy "Assalomu alaykum, " qo'yiladi (agar yo'q bo'lsa).
   */
  async sendMessage(
    parcelId: string,
    userId: string,
    rawText: string,
  ): Promise<ParcelMessage> {
    const { parcel, role } = await this.requireParticipant(parcelId, userId);
    if (!parcel.driverId) {
      throw new BadRequestException('Hali kuryer biriktirilmagan');
    }
    if (['DELIVERED', 'CANCELLED'].includes(parcel.status)) {
      throw new BadRequestException('Yakunlangan dostavkada yozib bo\'lmaydi');
    }
    let text = rawText.trim();
    const count = await this.messages.countByParcel(parcelId);
    if (count === 0 && !this.hasGreeting(text)) {
      text = CHAT_GREETING + text;
    }
    const message = await this.messages.create({
      parcelId,
      senderId: userId,
      senderRole: role,
      text,
    });
    // Qarshi tomonga (mijoz<->kuryer) push xabar
    const recipient = role === 'customer' ? parcel.driverId : parcel.customerId;
    if (recipient) {
      await this.notifications.notify(recipient, 'Yangi xabar', text, {
        type: 'parcel_chat',
        id: parcelId,
      });
    }
    return message;
  }

  /** Matn allaqachon salom bilan boshlanganmi (takrorlamaslik uchun). */
  private hasGreeting(text: string): boolean {
    return text.toLocaleLowerCase('uz').startsWith('assalomu alaykum');
  }

  private notifyCustomer(parcel: ParcelDelivery, body: string): Promise<void> {
    return this.notifications.notify(parcel.customerId, 'Dostavka', body, {
      type: 'parcel',
      id: parcel.id,
      status: parcel.status,
    });
  }

  private async requireDriverParcel(
    id: string,
    driverId: string,
  ): Promise<ParcelDelivery> {
    const parcel = await this.repo.findById(id);
    if (!parcel) throw new NotFoundException('Dostavka topilmadi');
    if (parcel.driverId !== driverId) {
      throw new ForbiddenException('Bu dostavka sizga biriktirilmagan');
    }
    return parcel;
  }
}
