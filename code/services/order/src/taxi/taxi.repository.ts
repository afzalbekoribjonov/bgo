import {
  FinalizeTaxiTrip,
  NewTaxiTrip,
  TaxiStatus,
  TaxiTrip,
} from './entities';

/** Taksi safari repository interfeysi (abstrakt). */
export abstract class TaxiRepository {
  abstract create(data: NewTaxiTrip): Promise<TaxiTrip>;
  abstract findById(id: string): Promise<TaxiTrip | null>;
  /** Barcha safarlar (admin hisobot uchun). */
  abstract findAll(): Promise<TaxiTrip[]>;
  abstract findByCustomer(customerId: string): Promise<TaxiTrip[]>;
  abstract findByDriver(driverId: string): Promise<TaxiTrip[]>;
  /** Yangi (PENDING), hali haydovchi biriktirilmagan safarlar. */
  abstract findAvailable(): Promise<TaxiTrip[]>;
  /** Haydovchini biriktiradi va ACCEPTED holatga o'tkazadi. */
  abstract assignDriver(id: string, driverId: string): Promise<TaxiTrip>;
  abstract updateStatus(id: string, status: TaxiStatus): Promise<TaxiTrip>;
  /** Safarni yakunlash — yakuniy narx/masofa/kutish. */
  abstract finalize(id: string, data: FinalizeTaxiTrip): Promise<TaxiTrip>;
  /** Mijoz bahosi (1-5) + izoh. */
  abstract setRating(
    id: string,
    rating: number,
    comment?: string,
  ): Promise<TaxiTrip>;
}
