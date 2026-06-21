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
import { RequestTaxiDto } from './dto/request-taxi.dto';
import { GeoPoint, TaxiTrip } from './entities';
import { TaxiRepository } from './taxi.repository';

/** Taksi safari — narx SERVER tomonda (tarif + masofa). plan/06-driver-app.md */
@Injectable()
export class TaxiService {
  constructor(
    private readonly repo: TaxiRepository,
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
    const e = await this.estimate(dto.pickup, dto.destination);
    return this.repo.create({
      customerId,
      pickup: dto.pickup,
      destination: dto.destination,
      distanceKm: e.distanceKm,
      fare: e.fare,
      commission: e.commission,
      driverEarning: e.driverEarning,
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

  /** Yakunladi (IN_PROGRESS -> COMPLETED). */
  async complete(id: string, driverId: string): Promise<TaxiTrip> {
    const trip = await this.requireDriverTrip(id, driverId);
    if (trip.status !== 'IN_PROGRESS') {
      throw new BadRequestException('Safar yakunlash holatida emas');
    }
    return this.repo.updateStatus(id, 'COMPLETED');
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
