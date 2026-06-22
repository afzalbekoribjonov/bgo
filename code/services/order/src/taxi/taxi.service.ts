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
  ) {}

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
    return this.messages.create({
      tripId,
      senderId: userId,
      senderRole: role,
      text,
    });
  }

  /** Matn allaqachon salom bilan boshlanganmi (takrorlamaslik uchun). */
  private hasGreeting(text: string): boolean {
    return text
      .toLocaleLowerCase('uz')
      .startsWith('assalomu alaykum');
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
    return this.repo.assignDriver(id, driverId);
  }

  /** Yo'lovchini oldi (ACCEPTED -> IN_PROGRESS). */
  async start(id: string, driverId: string): Promise<TaxiTrip> {
    const trip = await this.requireDriverTrip(id, driverId);
    if (trip.status !== 'ACCEPTED') {
      throw new BadRequestException('Safar boshlashga tayyor emas');
    }
    return this.repo.updateStatus(id, 'IN_PROGRESS');
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

    return this.repo.finalize(id, {
      distanceKm,
      waitMinutes,
      fare,
      commission,
      driverEarning: fare - commission,
    });
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
