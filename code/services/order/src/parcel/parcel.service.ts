import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { EarningsSummary, summarizeEarnings } from '../common/earnings';
import { GeoPoint, haversineKm } from '../common/geo';
import {
  buildVerticalReport,
  buildVerticalStats,
  ReportPeriod,
} from '../common/reporting';
import { TariffService } from '../tariff/tariff.service';
import { EstimateParcelDto, RequestParcelDto } from './dto/request-parcel.dto';
import { ParcelDelivery, ParcelSize } from './entities';
import { ParcelRepository } from './parcel.repository';

/** O'lcham koeffitsienti — yirik posilka qimmatroq. */
const SIZE_MULTIPLIER: Record<ParcelSize, number> = {
  SMALL: 1.0,
  MEDIUM: 1.3,
  LARGE: 1.6,
};

/** Dostavka (pochta) — narx SERVER tomonda (tarif + masofa + o'lcham). */
@Injectable()
export class ParcelService {
  constructor(
    private readonly repo: ParcelRepository,
    private readonly tariff: TariffService,
  ) {}

  async estimate(pickup: GeoPoint, destination: GeoPoint, size: ParcelSize) {
    const t = await this.tariff.getTariff();
    const distanceKm = Math.round(haversineKm(pickup, destination) * 100) / 100;
    const base = Math.max(
      t.parcelMinFare,
      t.parcelBaseFare + Math.round(t.parcelPerKm * distanceKm),
    );
    const fare = Math.round(base * SIZE_MULTIPLIER[size]);
    const commission = Math.round((fare * t.parcelCommissionPercent) / 100);
    return { distanceKm, size, fare, commission, driverEarning: fare - commission };
  }

  async create(customerId: string, dto: RequestParcelDto): Promise<ParcelDelivery> {
    const e = await this.estimate(dto.pickup, dto.destination, dto.size);
    return this.repo.create({
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
  }

  estimateDto(dto: EstimateParcelDto) {
    return this.estimate(dto.pickup, dto.destination, dto.size);
  }

  listMine(customerId: string) {
    return this.repo.findByCustomer(customerId);
  }

  async getOwned(customerId: string, id: string): Promise<ParcelDelivery> {
    const parcel = await this.repo.findById(id);
    if (!parcel) throw new NotFoundException('Dostavka topilmadi');
    if (parcel.customerId !== customerId) {
      throw new ForbiddenException('Bu dostavka sizga tegishli emas');
    }
    return parcel;
  }

  /** Mijoz bekor qiladi — faqat PENDING yoki ACCEPTED holatda. */
  async cancel(customerId: string, id: string): Promise<ParcelDelivery> {
    const parcel = await this.getOwned(customerId, id);
    if (!['PENDING', 'ACCEPTED'].includes(parcel.status)) {
      throw new BadRequestException('Dostavkani bu bosqichda bekor qilib bo\'lmaydi');
    }
    return this.repo.updateStatus(id, 'CANCELLED');
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

  /** Dostavka umumiy statistikasi (aylanma/foyda). */
  async adminStats() {
    const parcels = await this.repo.findAll();
    return buildVerticalStats(parcels, {
      isDone: (p) => p.status === 'DELIVERED',
      revenueOf: (p) => p.fare,
      profitOf: (p) => p.commission,
    });
  }

  /** Kuryer dostavka daromadi (EarningsSummary). */
  async driverEarnings(driverId: string): Promise<EarningsSummary> {
    const parcels = await this.repo.findByDriver(driverId);
    return summarizeEarnings(
      parcels,
      (p) => p.status === 'DELIVERED',
      (p) => ['ACCEPTED', 'PICKED_UP'].includes(p.status),
      (p) => p.driverEarning,
      (p) => p.createdAt,
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
    return this.repo.assignDriver(id, driverId);
  }

  /** Jo'natuvchidan oldi (ACCEPTED -> PICKED_UP). */
  async pickup(id: string, driverId: string): Promise<ParcelDelivery> {
    const parcel = await this.requireDriverParcel(id, driverId);
    if (parcel.status !== 'ACCEPTED') {
      throw new BadRequestException('Dostavka olishga tayyor emas');
    }
    return this.repo.updateStatus(id, 'PICKED_UP');
  }

  /** Qabul qiluvchiga yetkazdi (PICKED_UP -> DELIVERED). */
  async delivered(id: string, driverId: string): Promise<ParcelDelivery> {
    const parcel = await this.requireDriverParcel(id, driverId);
    if (parcel.status !== 'PICKED_UP') {
      throw new BadRequestException('Dostavka yetkazish holatida emas');
    }
    return this.repo.updateStatus(id, 'DELIVERED');
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
