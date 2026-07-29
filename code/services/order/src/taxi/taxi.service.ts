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
import { haversineKm } from '../common/geo';
import { roundFare } from '../common/money';
import {
  buildVerticalReport,
  buildVerticalReportRange,
  buildVerticalStats,
  ReportPeriod,
} from '../common/reporting';
import { NotificationClient } from '../notification-client/notification.client';
import { Tariff, TariffService } from '../tariff/tariff.service';
import { DriverLocation, NearbyDriver } from '../tracking/entities';
import { DriverLocationService } from '../tracking/driver-location.service';
import { CompleteTaxiDto, RequestTaxiDto } from './dto/request-taxi.dto';
import {
  AssignPricing,
  ChatRole,
  GeoPoint,
  TaxiMessage,
  TaxiStatusEntry,
  TaxiTariffClass,
  TaxiTrip,
  TaxiTripLive,
} from './entities';
import { TaxiMessageRepository } from './taxi-message.repository';
import { TaxiRepository } from './taxi.repository';

/** Suhbatning birinchi xabari oldidan majburiy salom. */
const CHAT_GREETING = 'Assalomu alaykum, ';

/** Taksi safari — narx SERVER tomonda (tarif + masofa). plan/06-driver-app.md */
@Injectable()
export class TaxiService implements OnModuleInit {
  constructor(
    private readonly repo: TaxiRepository,
    private readonly messages: TaxiMessageRepository,
    private readonly tariff: TariffService,
    private readonly notifications: NotificationClient,
    private readonly driverLocations: DriverLocationService,
    private readonly dispatch: DispatchService,
    private readonly driverInfo: DriverInfoClient,
  ) {}

  private readonly logger = new Logger(TaxiService.name);

  /** Restart tiklanishi: PENDING safarlarni qayta dispatch qilish. */
  onModuleInit(): void {
    setTimeout(() => {
      this.recoverPendingTrips().catch((e) =>
        this.logger.warn(`Taksi dispatch tiklanishi xatosi: ${(e as Error).message}`),
      );
    }, 2000);
  }

  private async recoverPendingTrips(): Promise<void> {
    const pending = await this.repo.findAvailable();
    if (pending.length === 0) return;
    this.logger.log(
      `Dispatch tiklanishi: ${pending.length} ta taksi safari qayta yuborilmoqda`,
    );
    await Promise.all(pending.map((t) => this.offerTrip(t)));
  }

  /** Yangi safarni eng yaqin online haydovchiga taklif qiladi. */
  private async offerTrip(trip: TaxiTrip): Promise<void> {
    await this.dispatch.offer({
      orderId: trip.id,
      vertical: 'taxi',
      pickupLat: trip.pickup.lat,
      pickupLng: trip.pickup.lng,
      pickupName: trip.pickup.text || 'Taksi buyurtmasi',
      dropoffLat: trip.destination?.lat ?? null,
      dropoffLng: trip.destination?.lng ?? null,
      dropoffText: trip.destination?.text ?? null,
      amount: trip.fare,
      earning: trip.driverEarning,
      tariffClass: trip.tariffClass,
    });
  }

  /** Taksi tarifi (mijoz ilovasi boshlang'ich haq/minimal narxni ko'rsatishi uchun). */
  async taxiTariff() {
    const t = await this.tariff.getTariff();
    return {
      baseFare: t.taxiBaseFare,
      perKm: t.taxiPerKm,
      minFare: t.taxiMinFare,
      waitPerMin: t.taxiWaitPerMin,
      commissionPercent: t.taxiCommissionPercent,
      // Comfort: Start narxiga km va boshlang'ich haq ustamalari
      comfortPerKmExtra: t.taxiComfortPerKmExtra,
      comfortBaseExtra: t.taxiComfortBaseExtra,
      minFareComfort: roundFare(t.taxiMinFare + t.taxiComfortBaseExtra),
      // Tarif tanlash tugmalarida ko'rsatiladigan boshlang'ich haq (minimal emas).
      baseFareComfort: roundFare(t.taxiBaseFare + t.taxiComfortBaseExtra),
    };
  }

  /** Klass bo'yicha bitta safar narxi (baza + km, minimal chegara bilan). */
  private classFare(
    t: Tariff,
    distanceKm: number,
    tariffClass: TaxiTariffClass,
  ): number {
    const base =
      t.taxiBaseFare + (tariffClass === 'comfort' ? t.taxiComfortBaseExtra : 0);
    const perKm =
      t.taxiPerKm + (tariffClass === 'comfort' ? t.taxiComfortPerKmExtra : 0);
    const min =
      t.taxiMinFare + (tariffClass === 'comfort' ? t.taxiComfortBaseExtra : 0);
    return roundFare(Math.max(min, base + Math.round(perKm * distanceKm)));
  }

  /**
   * Narx hisoblash (yaratmasdan): masofa + ikkala tarif narxi + taxminiy vaqt.
   * `fare` — Start (orqaga moslik); `fareComfort` — Comfort.
   */
  async estimate(pickup: GeoPoint, destination: GeoPoint) {
    const t = await this.tariff.getTariff();
    const distanceKm = Math.round(haversineKm(pickup, destination) * 100) / 100;
    const fare = this.classFare(t, distanceKm, 'start');
    const fareComfort = this.classFare(t, distanceKm, 'comfort');
    const commission = Math.round((fare * t.taxiCommissionPercent) / 100);
    // Taxminiy yurish vaqti — shahar ichida ~30 km/soat (zaxira; mijoz OSRM'dan aniqrog'ini oladi).
    const etaMinutes = Math.max(2, Math.round((distanceKm / 30) * 60));
    return {
      distanceKm,
      fare,
      fareComfort,
      etaMinutes,
      commission,
      driverEarning: fare - commission,
    };
  }

  // ---------- Narx / kutish / jonli ko'rinish yordamchilari ----------

  /** Olib ketish masofasi ustamasi: chegaradan oshgan har km uchun qo'shimcha. */
  private pickupSurchargeFor(pickupDistanceKm: number, t: Tariff): number {
    const extra = pickupDistanceKm - t.taxiPickupSurchargeThresholdKm;
    if (extra <= 0) return 0;
    return Math.round(extra * t.taxiPickupSurchargePerKm);
  }

  /** Haydovchining joriy joylashuvidan olib ketish nuqtasigacha ustama. */
  private async pickupPricing(
    driverId: string,
    pickup: GeoPoint,
  ): Promise<AssignPricing> {
    const t = await this.tariff.getTariff();
    const loc = await this.driverLocations.get(driverId);
    if (!loc) return { pickupDistanceKm: 0, pickupSurcharge: 0 };
    const km =
      Math.round(
        haversineKm(
          { text: '', lat: loc.lat, lng: loc.lng },
          { text: '', lat: pickup.lat, lng: pickup.lng },
        ) * 100,
      ) / 100;
    return {
      pickupDistanceKm: km,
      pickupSurcharge: this.pickupSurchargeFor(km, t),
    };
  }

  /** Jami kutilgan vaqt (soniya) — jamlangan segmentlar + joriy ochiq segment. */
  private totalWaitSec(trip: TaxiTrip): number {
    let sec = trip.waitAccumSec ?? 0;
    if (trip.waitStartedAt) {
      sec += Math.max(0, (Date.now() - Date.parse(trip.waitStartedAt)) / 1000);
    }
    return sec;
  }

  /** Hisoblanadigan (pulli) kutish daqiqalari — bepul oynadan keyingi. */
  private billableWaitMinutes(trip: TaxiTrip, t: Tariff): number {
    const totalMin = Math.floor(this.totalWaitSec(trip) / 60);
    return Math.max(0, totalMin - t.taxiWaitFreeMin);
  }

  /** Safar davomiyligi (daqiqa) — IN_PROGRESS dan COMPLETED/hozirgacha. */
  private durationMinutes(trip: TaxiTrip): number {
    const hist = trip.statusHistory ?? [];
    const startEntry = hist.find((h) => h.status === 'IN_PROGRESS');
    if (!startEntry) return 0;
    const endEntry = hist.find((h: TaxiStatusEntry) => h.status === 'COMPLETED');
    const start = Date.parse(startEntry.at);
    const end = endEntry ? Date.parse(endEntry.at) : Date.now();
    return Math.max(0, Math.round((end - start) / 60000));
  }

  /** Jonli ko'rinish — server hisoblagan narx/kutish (poll uchun). */
  async toLive(trip: TaxiTrip): Promise<TaxiTripLive> {
    const t = await this.tariff.getTariff();
    const waitMin =
      trip.status === 'COMPLETED'
        ? trip.waitMinutes
        : this.billableWaitMinutes(trip, t);
    const waitFee = waitMin * t.taxiWaitPerMin;
    const currentFare =
      trip.status === 'COMPLETED'
        ? trip.fare
        : trip.fare + (trip.pickupSurcharge ?? 0) + waitFee;

    // Faol safarda — biriktirilgan haydovchi ma'lumoti (ism/mashina/reyting).
    let driverName: string | null | undefined;
    let driverCar: string | null | undefined;
    let driverPlate: string | null | undefined;
    let driverPhone: string | null | undefined;
    let customerPhone: string | null | undefined;
    let driverRating: number | undefined;
    let driverRatingCount: number | undefined;
    if (
      trip.driverId &&
      ['ACCEPTED', 'ARRIVED', 'IN_PROGRESS'].includes(trip.status)
    ) {
      const [info, stats, dPhone, cPhone] = await Promise.all([
        this.driverInfo.getPublic(trip.driverId),
        this.repo.driverRatingStats(trip.driverId),
        this.driverInfo.getUserPhone(trip.driverId),
        this.driverInfo.getUserPhone(trip.customerId),
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
      ...trip,
      currentWaitMinutes: waitMin,
      currentWaitFee: waitFee,
      currentFare,
      durationMinutes: this.durationMinutes(trip),
      waitFreeMin: t.taxiWaitFreeMin,
      driverName,
      driverCar,
      driverPlate,
      driverPhone,
      customerPhone,
      driverRating,
      driverRatingCount,
    };
  }

  /** Mijoz uchun jonli safar (egalik tekshiruvi bilan). */
  async liveForCustomer(customerId: string, id: string): Promise<TaxiTripLive> {
    return this.toLive(await this.getOwned(customerId, id));
  }

  /** Haydovchi uchun jonli safar. */
  async liveForDriver(driverId: string, id: string): Promise<TaxiTripLive> {
    return this.toLive(await this.requireDriverTrip(id, driverId));
  }

  async create(customerId: string, dto: RequestTaxiDto): Promise<TaxiTrip> {
    // Manzil belgilangan -> narx oldindan (FIXED). Belgilanmagan -> metered
    // (narx safar yakunida masofa + kutishdan hisoblanadi).
    const tariffClass: TaxiTariffClass =
        dto.tariffClass === 'comfort' ? 'comfort' : 'start';
    let trip: TaxiTrip;
    if (dto.destination) {
      const t = await this.tariff.getTariff();
      const distanceKm =
          Math.round(haversineKm(dto.pickup, dto.destination) * 100) / 100;
      const fare = this.classFare(t, distanceKm, tariffClass);
      const commission = Math.round((fare * t.taxiCommissionPercent) / 100);
      trip = await this.repo.create({
        customerId,
        pickup: dto.pickup,
        destination: dto.destination,
        metered: false,
        tariffClass,
        distanceKm,
        fare,
        commission,
        driverEarning: fare - commission,
      });
    } else {
      trip = await this.repo.create({
        customerId,
        pickup: dto.pickup,
        metered: true,
        tariffClass,
        distanceKm: 0,
        fare: 0,
        commission: 0,
        driverEarning: 0,
      });
    }
    this.offerTrip(trip).catch((e) =>
      this.logger.warn(`Taksi taklif xatosi: ${(e as Error).message}`),
    );
    return trip;
  }

  async listMine(customerId: string): Promise<TaxiTripLive[]> {
    const trips = await this.repo.findByCustomer(customerId);
    return Promise.all(trips.map((t) => this.toLive(t)));
  }

  async getOwned(customerId: string, id: string): Promise<TaxiTrip> {
    const trip = await this.repo.findById(id);
    if (!trip) throw new NotFoundException('Safar topilmadi');
    if (trip.customerId !== customerId) {
      throw new ForbiddenException('Bu safar sizga tegishli emas');
    }
    return trip;
  }

  // ---------- Jonli kuzatuv (mijoz ko'rishi uchun) ----------

  /**
   * Mijozning safariga biriktirilgan haydovchining jonli joylashuvi.
   * Haydovchi biriktirilmagan yoki hali joylashuv yubormagan bo'lsa — null.
   */
  async driverLocationForTrip(
    customerId: string,
    id: string,
  ): Promise<DriverLocation | null> {
    const trip = await this.getOwned(customerId, id);
    if (!trip.driverId) return null;
    return this.driverLocations.get(trip.driverId);
  }

  /** Berilgan nuqta atrofidagi online haydovchilar (anonim) — "yaqin mashinalar". */
  nearbyDrivers(lat: number, lng: number): Promise<NearbyDriver[]> {
    return this.driverLocations.nearby(lat, lng);
  }

  // ---------- Suhbat (mijoz↔haydovchi) ----------

  /** Safar ishtirokchisi (mijoz yoki biriktirilgan haydovchi) rolini aniqlaydi. */
  private async requireParticipant(
    tripId: string,
    userId: string,
  ): Promise<{ trip: TaxiTrip; role: ChatRole }> {
    const trip = await this.repo.findById(tripId);
    if (!trip) throw new NotFoundException('Safar topilmadi');
    if (trip.customerId === userId) return { trip, role: 'customer' };
    if (trip.driverId === userId) return { trip, role: 'driver' };
    throw new ForbiddenException('Bu safar suhbatiga ruxsat yo\'q');
  }

  /** Safar suhbati xabarlari (vaqt bo'yicha). */
  async listMessages(tripId: string, userId: string): Promise<TaxiMessage[]> {
    await this.requireParticipant(tripId, userId);
    return this.messages.listByTrip(tripId);
  }

  /**
   * Xabar yuborish. Haydovchi biriktirilgach mumkin. Suhbatning birinchi
   * xabari oldidan majburiy "Assalomu alaykum, " qo'yiladi (agar yo'q bo'lsa).
   */
  async sendMessage(
    tripId: string,
    userId: string,
    rawText: string,
  ): Promise<TaxiMessage> {
    const { trip, role } = await this.requireParticipant(tripId, userId);
    if (!trip.driverId) {
      throw new BadRequestException('Hali haydovchi biriktirilmagan');
    }
    if (['COMPLETED', 'CANCELLED'].includes(trip.status)) {
      throw new BadRequestException('Yakunlangan safarda yozib bo\'lmaydi');
    }
    let text = rawText.trim();
    const count = await this.messages.countByTrip(tripId);
    if (count === 0 && !this.hasGreeting(text)) {
      text = CHAT_GREETING + text;
    }
    const message = await this.messages.create({
      tripId,
      senderId: userId,
      senderRole: role,
      text,
    });
    // Qarshi tomonga (mijoz<->haydovchi) push xabar
    const recipient = role === 'customer' ? trip.driverId : trip.customerId;
    if (recipient) {
      await this.notifications.notify(recipient, 'Yangi xabar', text, {
        type: 'taxi_chat',
        id: tripId,
      });
    }
    return message;
  }

  /** Matn allaqachon salom bilan boshlanganmi (takrorlamaslik uchun). */
  private hasGreeting(text: string): boolean {
    return text
      .toLocaleLowerCase('uz')
      .startsWith('assalomu alaykum');
  }

  /** Mijoz safarni baholaydi (1-5) — faqat yakunlangan safar. */
  async rate(
    customerId: string,
    id: string,
    rating: number,
    comment?: string,
  ): Promise<TaxiTrip> {
    const trip = await this.getOwned(customerId, id);
    if (trip.status !== 'COMPLETED') {
      throw new BadRequestException('Faqat yakunlangan safarni baholash mumkin');
    }
    if (rating < 1 || rating > 5) {
      throw new BadRequestException('Baho 1-5 oralig\'ida bo\'lishi kerak');
    }
    return this.repo.setRating(id, rating, comment);
  }

  /**
   * Mijoz bekor qiladi — PENDING/ACCEPTED/ARRIVED holatda (safar boshlangach yo'q).
   * Haydovchi biriktirilgan bo'lsa — unga ogohlantirish boradi.
   */
  async cancel(customerId: string, id: string): Promise<TaxiTrip> {
    const trip = await this.getOwned(customerId, id);
    if (!['PENDING', 'ACCEPTED', 'ARRIVED'].includes(trip.status)) {
      throw new BadRequestException('Safar boshlangach bekor qilib bo\'lmaydi');
    }
    this.dispatch.clear(id);
    const cancelled = await this.repo.updateStatus(id, 'CANCELLED', {
      by: 'customer',
      driverId: trip.driverId,
    });
    if (trip.driverId) {
      await this.notifications.notify(
        trip.driverId,
        'Taksi',
        'Mijoz safarni bekor qildi',
        { type: 'taxi', id, status: 'CANCELLED', cancelledBy: 'customer' },
      );
    }
    await this.messages.deleteByTrip(id).catch(() => undefined);
    return cancelled;
  }

  // ---------- Haydovchi ----------

  /**
   * Yangi (PENDING) safarlar — haydovchi tarifiga ko'ra: Comfort safarlar
   * faqat Comfort tarifi yoqilgan haydovchilarga ko'rinadi.
   */
  async listAvailable(driverId?: string): Promise<TaxiTrip[]> {
    const trips = await this.repo.findAvailable();
    if (!driverId) return trips;
    if (!trips.some((t) => t.tariffClass === 'comfort')) return trips;
    const isComfort = await this.driverInfo.isComfortDriver(driverId);
    return isComfort
      ? trips
      : trips.filter((t) => t.tariffClass !== 'comfort');
  }

  listDriverTrips(driverId: string) {
    return this.repo.findByDriver(driverId);
  }

  /** Haydovchining faol safarlari (jonli) — ilova qayta ochilganda tiklash. */
  async listActiveDriverTrips(driverId: string): Promise<TaxiTripLive[]> {
    const trips = await this.repo.findByDriver(driverId);
    const active = trips.filter((t) =>
      ['ACCEPTED', 'ARRIVED', 'IN_PROGRESS'].includes(t.status),
    );
    return Promise.all(active.map((t) => this.toLive(t)));
  }

  // ---------- Admin hisobot ----------

  /** Taksi davr hisoboti (admin jamlash uchun). */
  async adminReport(period: ReportPeriod) {
    const trips = await this.repo.findAllForStats();
    return buildVerticalReport(trips, period, {
      createdAtOf: (t) => t.createdAt,
      isDone: (t) => t.status === 'COMPLETED',
      isCancelled: (t) => t.status === 'CANCELLED',
      revenueOf: (t) => t.fare,
      profitOf: (t) => t.commission,
    });
  }

  /** Taksi hisoboti — ixtiyoriy sana oralig'i (istalgan kun/oy). */
  async adminReportRange(from: Date, to: Date) {
    const trips = await this.repo.findAllForStats();
    return buildVerticalReportRange(trips, from, to, {
      createdAtOf: (t) => t.createdAt,
      isDone: (t) => t.status === 'COMPLETED',
      isCancelled: (t) => t.status === 'CANCELLED',
      revenueOf: (t) => t.fare,
      profitOf: (t) => t.commission,
    });
  }

  /** Taksi umumiy statistikasi (aylanma/foyda). */
  async adminStats() {
    const trips = await this.repo.findAllForStats();
    return buildVerticalStats(trips, {
      isDone: (t) => t.status === 'COMPLETED',
      revenueOf: (t) => t.fare,
      profitOf: (t) => t.commission,
    });
  }

  /** Statistika-qatorlar (band-haydovchi hisoblash kabi yengil ehtiyojlar uchun). */
  statsRows() {
    return this.repo.findAllForStats();
  }

  /** Admin: bitta safarni to'liq holida (barcha maydonlar). */
  async adminGetById(id: string): Promise<TaxiTrip | null> {
    return this.repo.findById(id);
  }

  /** Bitta safar — haydovchi + publicNo bo'yicha (AI shikoyat qidiruvi). */
  findByDriverAndPublicNo(driverId: string, publicNo: number): Promise<TaxiTrip | null> {
    return this.repo.findByDriverAndPublicNo(driverId, publicNo);
  }

  /** Admin: taksi safarlarini filtrlangan ro'yxat. */
  async adminListTrips(filter: {
    status?: string;
    from?: string;
    to?: string;
    driverId?: string;
    q?: string;
  }): Promise<TaxiTrip[]> {
    const fromTs = filter.from ? new Date(filter.from.length === 10 ? `${filter.from}T00:00:00.000` : filter.from).getTime() : undefined;
    const toTs = filter.to ? new Date(filter.to.length === 10 ? `${filter.to}T23:59:59.999` : filter.to).getTime() : undefined;
    const q = filter.q?.trim().toLowerCase();
    const trips = await this.repo.findAll();
    return trips.filter((t) => {
      if (filter.status && t.status !== filter.status) return false;
      if (filter.driverId && t.driverId !== filter.driverId) return false;
      const ts = new Date(t.createdAt).getTime();
      if (fromTs !== undefined && ts < fromTs) return false;
      if (toTs !== undefined && ts > toTs) return false;
      if (q) {
        const hay = `${t.publicNo} ${t.pickup?.text ?? ''}`.toLowerCase();
        if (!hay.includes(q)) return false;
      }
      return true;
    });
  }

  /** Admin: haydovchi faol taksi safarini bekor qiladi. */
  async adminCancel(id: string): Promise<TaxiTrip | null> {
    const trip = await this.repo.findById(id);
    if (!trip) return null;
    if (['COMPLETED', 'CANCELLED'].includes(trip.status)) return trip;
    this.dispatch.clear(id);
    return this.repo.updateStatus(id, 'CANCELLED', {
      by: 'admin',
      driverId: trip.driverId,
    });
  }

  /** Haydovchi taksi daromadi (EarningsSummary). */
  async driverEarnings(driverId: string): Promise<EarningsSummary> {
    const trips = await this.repo.findByDriverForEarnings(driverId);
    return summarizeEarnings(
      trips,
      (t) => t.status === 'COMPLETED',
      (t) => ['ACCEPTED', 'IN_PROGRESS'].includes(t.status),
      (t) => t.driverEarning,
      (t) => t.updatedAt,
    );
  }

  /** Daromad-qatorlar (boshqa vertikal "Bugun" hisobotiga jamlash uchun — yengil select). */
  driverEarningsRows(driverId: string) {
    return this.repo.findByDriverForEarnings(driverId);
  }

  /** Haydovchi qabul qiladi (PENDING -> ACCEPTED). */
  async accept(id: string, driverId: string): Promise<TaxiTrip> {
    const trip = await this.repo.findById(id);
    if (!trip) throw new NotFoundException('Safar topilmadi');
    if (trip.status !== 'PENDING') {
      throw new BadRequestException('Safar qabul qilishga tayyor emas');
    }
    if (trip.driverId) {
      throw new BadRequestException('Safar allaqachon biriktirilgan');
    }
    // Comfort safar — faqat Comfort tarifi yoqilgan haydovchiga.
    if (
      trip.tariffClass === 'comfort' &&
      !(await this.driverInfo.isComfortDriver(driverId))
    ) {
      this.logger.warn(
        `Comfort bloklandi: haydovchi ${driverId} #${trip.publicNo} (Comfort) safarini olishga urindi`,
      );
      throw new BadRequestException(
        'Bu buyurtma Comfort tarifidagi mashinalar uchun',
      );
    }
    const pricing = await this.pickupPricing(driverId, trip.pickup);
    const updated = await this.repo.assignDriver(id, driverId, pricing);
    this.dispatch.clear(id);
    await this.notifications.notify(
      updated.customerId,
      'Taksi',
      "Haydovchi qabul qildi va yo'lda",
      { type: 'taxi', id: updated.id, status: 'ACCEPTED' },
    );
    return updated;
  }

  /**
   * Olib ketish nuqtasiga yetib keldi (ACCEPTED -> ARRIVED). Kutish AVTOMATIK
   * boshlanadi: bepul oyna (taxiWaitFreeMin), keyin pulli.
   */
  async arrive(id: string, driverId: string): Promise<TaxiTrip> {
    const trip = await this.requireDriverTrip(id, driverId);
    if (trip.status !== 'ACCEPTED') {
      throw new BadRequestException('Safar bu bosqichda emas');
    }
    const updated = await this.repo.markArrived(id);
    await this.notifications.notify(
      updated.customerId,
      'Taksi',
      'Haydovchi yetib keldi va sizni kutmoqda',
      { type: 'taxi', id: updated.id, status: 'ARRIVED' },
    );
    return updated;
  }

  /**
   * Yo'l davomidagi kutishni yoqish/o'chirish (faqat IN_PROGRESS — mashina
   * to'xtaganda). Har segment vaqti jamlanadi.
   */
  async toggleWait(id: string, driverId: string): Promise<TaxiTripLive> {
    const trip = await this.requireDriverTrip(id, driverId);
    if (trip.status !== 'IN_PROGRESS') {
      throw new BadRequestException('Kutishni faqat safar davomida boshqarish mumkin');
    }
    let accum = trip.waitAccumSec ?? 0;
    let started: Date | null;
    if (trip.waitStartedAt) {
      accum += Math.max(
        0,
        Math.round((Date.now() - Date.parse(trip.waitStartedAt)) / 1000),
      );
      started = null; // to'xtatildi
    } else {
      started = new Date(); // boshlandi
    }
    const updated = await this.repo.setWaiting(id, started, accum);
    return this.toLive(updated);
  }

  /**
   * Haydovchi safarni bekor qiladi (ACCEPTED/ARRIVED) -> qayta dispatch.
   * Sabab majburiy — balansdan jarima yechiladi; mijoz aybi bo'lsa jarima
   * sezdirmasdan qaytariladi (haydovchi buni bilmaydi).
   */
  async driverCancel(
    id: string,
    driverId: string,
    reason: DriverCancelReason,
    note?: string,
  ): Promise<TaxiTrip> {
    if (!isDriverCancelReason(reason)) {
      throw new BadRequestException("Bekor qilish sababini tanlang");
    }
    const trip = await this.requireDriverTrip(id, driverId);
    if (!['ACCEPTED', 'ARRIVED'].includes(trip.status)) {
      throw new BadRequestException("Bu bosqichda bekor qilib bo'lmaydi");
    }
    await this.notifications.notify(
      trip.customerId,
      'Taksi',
      'Haydovchi kela olmadi. Uzr — sizga boshqa haydovchi qidirilmoqda',
      { type: 'taxi', id, status: 'PENDING', cancelledBy: 'driver' },
    );
    await this.messages.deleteByTrip(id).catch(() => undefined);
    const released = await this.repo.releaseToPending(id, reason, note);
    this.offerTrip(released).catch((e) =>
      this.logger.warn(`Qayta taklif xatosi: ${(e as Error).message}`),
    );
    await this.applyCancelPenalty(driverId, `Taksi #${trip.publicNo} bekor qilindi`, reason);
    await this.driverInfo.recordCancellation(driverId);
    return released;
  }

  /** Bekor qilish jarimasi — mijoz aybi bo'lsa sezdirmasdan qaytariladi. */
  private async applyCancelPenalty(
    driverId: string,
    note: string,
    reason: DriverCancelReason,
  ): Promise<void> {
    try {
      const t = await this.tariff.getTariff();
      const penalty = t.driverCancelPenalty;
      if (penalty <= 0) return;
      await this.driverInfo.charge(driverId, penalty, note);
      if (CANCEL_REASON_CUSTOMER_FAULT[reason]) {
        await this.driverInfo.silentRefund(driverId, penalty, `Tuzatish: ${note}`);
      }
    } catch (e) {
      this.logger.warn(`Bekor qilish jarimasi xatosi: ${(e as Error).message}`);
    }
  }

  /**
   * Yo'lga chiqish (ARRIVED/ACCEPTED -> IN_PROGRESS). Yo'lovchi olindi — olib
   * ketishdagi kutish segmenti jamlanadi va kutish to'xtaydi.
   */
  async start(id: string, driverId: string): Promise<TaxiTrip> {
    const trip = await this.requireDriverTrip(id, driverId);
    if (!['ACCEPTED', 'ARRIVED'].includes(trip.status)) {
      throw new BadRequestException('Safar boshlashga tayyor emas');
    }
    let accum = trip.waitAccumSec ?? 0;
    if (trip.waitStartedAt) {
      accum += Math.max(
        0,
        Math.round((Date.now() - Date.parse(trip.waitStartedAt)) / 1000),
      );
    }
    const updated = await this.repo.beginTrip(id, accum);
    await this.notifications.notify(
      updated.customerId,
      'Taksi',
      'Safar boshlandi',
      { type: 'taxi', id: updated.id, status: 'IN_PROGRESS' },
    );
    return updated;
  }

  /**
   * Yakunladi (IN_PROGRESS -> COMPLETED). Metered bo'lsa yakuniy narx masofa
   * (haydovchi) + pulli kutishdan; FIXED bo'lsa belgilangan narx + kutish haqi.
   */
  async complete(
    id: string,
    driverId: string,
    dto: CompleteTaxiDto = {},
  ): Promise<TaxiTrip> {
    const trip = await this.requireDriverTrip(id, driverId);
    if (trip.status !== 'IN_PROGRESS') {
      throw new BadRequestException('Safar yakunlash holatida emas');
    }
    const t = await this.tariff.getTariff();
    // Yopilmagan kutish segmentini jamlaymiz, so'ng bepul oynani ayiramiz.
    let accumSec = trip.waitAccumSec ?? 0;
    if (trip.waitStartedAt) {
      accumSec += Math.max(
        0,
        Math.round((Date.now() - Date.parse(trip.waitStartedAt)) / 1000),
      );
    }
    const waitMinutes = Math.max(
      0,
      Math.floor(accumSec / 60) - t.taxiWaitFreeMin,
    );

    let distanceKm = trip.distanceKm;
    let baseFare: number;
    // GPS orqali kuzatilgan haqiqiy bosib o'tilgan masofa (safar davomida
    // ping'lardan jamlangan) — mavjud bo'lsa har doim shu ko'rsatiladi,
    // FIXED yo'nalishda ham boshlang'ich chiziqli (havodan) taxmin emas.
    const gpsDistance = trip.actualDistanceKm;
    const preciseDistance =
      gpsDistance && gpsDistance > 0.05
        ? Math.round(gpsDistance * 100) / 100
        : null;
    if (trip.metered) {
      // Haydovchi qo'lda kiritgan raqamga (o'zgartirilishi mumkin) faqat GPS
      // ma'lumoti yo'q/juda kichik bo'lsa (eski ilova, ruxsat berilmagan)
      // tayanamiz.
      distanceKm = preciseDistance ?? (dto.distanceKm ?? trip.distanceKm);
      // Tarif klassiga mos narx (Comfort — km/baza ustamalari bilan).
      baseFare = this.classFare(t, distanceKm, trip.tariffClass);
    } else {
      // FIXED — narx buyurtma vaqtida kelishilgan holicha qoladi (o'zgarmaydi);
      // faqat ko'rsatiladigan masofa haqiqiy bosib o'tilganga yangilanadi.
      distanceKm = preciseDistance ?? trip.distanceKm;
      baseFare = trip.fare; // yaratishda belgilangan (yaxlitlangan, ustamasiz)
    }
    // Asos yaxlitlangan; ustama va kutish aniq qo'shiladi (jonli narx bilan mos).
    const waitFee = Math.round(t.taxiWaitPerMin * waitMinutes);
    const surcharge = trip.pickupSurcharge ?? 0;
    const fare = baseFare + surcharge + waitFee;
    const commission = Math.round((fare * t.taxiCommissionPercent) / 100);

    const updated = await this.repo.finalize(id, {
      distanceKm,
      waitMinutes,
      pickupSurcharge: surcharge,
      fare,
      commission,
      driverEarning: fare - commission,
    });
    await this.notifications.notify(
      updated.customerId,
      'Taksi',
      `Safar yakunlandi. To'lov: ${fare} so'm`,
      { type: 'taxi', id: updated.id, status: 'COMPLETED' },
    );
    // Komissiyani haydovchi balansidan yechamiz — balans/daromad darhol to'g'ri
    // ko'rinishi uchun javobdan OLDIN kutamiz (xato bo'lsa ham safar yiqilmaydi).
    try {
      await this.driverInfo.charge(
        driverId,
        commission,
        `Taksi #${updated.publicNo}`,
      );
    } catch (e) {
      this.logger.warn(`Komissiya yechishda xato: ${(e as Error).message}`);
    }
    await this.driverInfo.recordCompletion(driverId);
    // Safar yakunlandi — suhbat saqlanib qolmaydi.
    await this.messages.deleteByTrip(id).catch(() => undefined);
    return updated;
  }

  private async requireDriverTrip(
    id: string,
    driverId: string,
  ): Promise<TaxiTrip> {
    const trip = await this.repo.findById(id);
    if (!trip) throw new NotFoundException('Safar topilmadi');
    if (trip.driverId !== driverId) {
      throw new ForbiddenException('Bu safar sizga biriktirilmagan');
    }
    return trip;
  }
}
