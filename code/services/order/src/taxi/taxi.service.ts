import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { EarningsSummary, summarizeEarnings } from '../common/earnings';
import { haversineKm } from '../common/geo';
import {
  buildVerticalReport,
  buildVerticalStats,
  ReportPeriod,
} from '../common/reporting';
import { NotificationClient } from '../notification-client/notification.client';
import { TariffService } from '../tariff/tariff.service';
import { CompleteTaxiDto, RequestTaxiDto } from './dto/request-taxi.dto';
import { ChatRole, GeoPoint, TaxiMessage, TaxiTrip } from './entities';
import { TaxiMessageRepository } from './taxi-message.repository';
import { TaxiRepository } from './taxi.repository';

/** Suhbatning birinchi xabari oldidan majburiy salom. */
const CHAT_GREETING = 'Assalomu alaykum, ';

/** Taksi safari — narx SERVER tomonda (tarif + masofa). plan/06-driver-app.md */
@Injectable()
export class TaxiService {
  constructor(
    private readonly repo: TaxiRepository,
    private readonly messages: TaxiMessageRepository,
    private readonly tariff: TariffService,
    private readonly notifications: NotificationClient,
  ) {}

  /** Taksi tarifi (mijoz ilovasi minimal narxni ko'rsatishi uchun). */
  async taxiTariff() {
    const t = await this.tariff.getTariff();
    return {
      baseFare: t.taxiBaseFare,
      perKm: t.taxiPerKm,
      minFare: t.taxiMinFare,
      waitPerMin: t.taxiWaitPerMin,
      commissionPercent: t.taxiCommissionPercent,
    };
  }

  /** Narx hisoblash (yaratmasdan): masofa + haq. */
  async estimate(pickup: GeoPoint, destination: GeoPoint) {
    const t = await this.tariff.getTariff();
    const distanceKm = Math.round(haversineKm(pickup, destination) * 100) / 100;
    const raw = t.taxiBaseFare + Math.round(t.taxiPerKm * distanceKm);
    const fare = Math.max(t.taxiMinFare, raw);
    const commission = Math.round((fare * t.taxiCommissionPercent) / 100);
    return {
      distanceKm,
      fare,
      commission,
      driverEarning: fare - commission,
    };
  }

  async create(customerId: string, dto: RequestTaxiDto): Promise<TaxiTrip> {
    // Manzil belgilangan -> narx oldindan (FIXED). Belgilanmagan -> metered
    // (narx safar yakunida masofa + kutishdan hisoblanadi).
    if (dto.destination) {
      const e = await this.estimate(dto.pickup, dto.destination);
      return this.repo.create({
        customerId,
        pickup: dto.pickup,
        destination: dto.destination,
        metered: false,
        distanceKm: e.distanceKm,
        fare: e.fare,
        commission: e.commission,
        driverEarning: e.driverEarning,
      });
    }
    return this.repo.create({
      customerId,
      pickup: dto.pickup,
      metered: true,
      distanceKm: 0,
      fare: 0,
      commission: 0,
      driverEarning: 0,
    });
  }

  listMine(customerId: string) {
    return this.repo.findByCustomer(customerId);
  }

  async getOwned(customerId: string, id: string): Promise<TaxiTrip> {
    const trip = await this.repo.findById(id);
    if (!trip) throw new NotFoundException('Safar topilmadi');
    if (trip.customerId !== customerId) {
      throw new ForbiddenException('Bu safar sizga tegishli emas');
    }
    return trip;
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

  /** Mijoz bekor qiladi — faqat PENDING yoki ACCEPTED holatda. */
  async cancel(customerId: string, id: string): Promise<TaxiTrip> {
    const trip = await this.getOwned(customerId, id);
    if (!['PENDING', 'ACCEPTED'].includes(trip.status)) {
      throw new BadRequestException('Safarni bu bosqichda bekor qilib bo\'lmaydi');
    }
    return this.repo.updateStatus(id, 'CANCELLED');
  }

  // ---------- Haydovchi ----------

  listAvailable() {
    return this.repo.findAvailable();
  }

  listDriverTrips(driverId: string) {
    return this.repo.findByDriver(driverId);
  }

  // ---------- Admin hisobot ----------

  /** Taksi davr hisoboti (admin jamlash uchun). */
  async adminReport(period: ReportPeriod) {
    const trips = await this.repo.findAll();
    return buildVerticalReport(trips, period, {
      createdAtOf: (t) => t.createdAt,
      isDone: (t) => t.status === 'COMPLETED',
      isCancelled: (t) => t.status === 'CANCELLED',
      revenueOf: (t) => t.fare,
      profitOf: (t) => t.commission,
    });
  }

  /** Taksi umumiy statistikasi (aylanma/foyda). */
  async adminStats() {
    const trips = await this.repo.findAll();
    return buildVerticalStats(trips, {
      isDone: (t) => t.status === 'COMPLETED',
      revenueOf: (t) => t.fare,
      profitOf: (t) => t.commission,
    });
  }

  /** Haydovchi taksi daromadi (EarningsSummary). */
  async driverEarnings(driverId: string): Promise<EarningsSummary> {
    const trips = await this.repo.findByDriver(driverId);
    return summarizeEarnings(
      trips,
      (t) => t.status === 'COMPLETED',
      (t) => ['ACCEPTED', 'IN_PROGRESS'].includes(t.status),
      (t) => t.driverEarning,
      (t) => t.createdAt,
    );
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
    const updated = await this.repo.assignDriver(id, driverId);
    await this.notifications.notify(
      updated.customerId,
      'Taksi',
      "Haydovchi qabul qildi va yo'lda",
      { type: 'taxi', id: updated.id, status: 'ACCEPTED' },
    );
    return updated;
  }

  /** Yo'lovchini oldi (ACCEPTED -> IN_PROGRESS). */
  async start(id: string, driverId: string): Promise<TaxiTrip> {
    const trip = await this.requireDriverTrip(id, driverId);
    if (trip.status !== 'ACCEPTED') {
      throw new BadRequestException('Safar boshlashga tayyor emas');
    }
    const updated = await this.repo.updateStatus(id, 'IN_PROGRESS');
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
    const waitMinutes = dto.waitMinutes ?? trip.waitMinutes ?? 0;

    let distanceKm = trip.distanceKm;
    let baseFare: number;
    if (trip.metered) {
      distanceKm = dto.distanceKm ?? trip.distanceKm;
      baseFare = Math.max(
        t.taxiMinFare,
        t.taxiBaseFare + Math.round(t.taxiPerKm * distanceKm),
      );
    } else {
      baseFare = trip.fare; // FIXED — yaratishda belgilangan
    }
    const waitFee = Math.round(t.taxiWaitPerMin * waitMinutes);
    const fare = baseFare + waitFee;
    const commission = Math.round((fare * t.taxiCommissionPercent) / 100);

    const updated = await this.repo.finalize(id, {
      distanceKm,
      waitMinutes,
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
