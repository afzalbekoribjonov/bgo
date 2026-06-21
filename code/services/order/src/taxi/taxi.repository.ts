import { NewTaxiTrip, TaxiStatus, TaxiTrip } from './entities';

/** Taksi safari repository interfeysi (abstrakt). */
export abstract class TaxiRepository {
  abstract create(data: NewTaxiTrip): Promise<TaxiTrip>;
  abstract findById(id: string): Promise<TaxiTrip | null>;
  abstract findByCustomer(customerId: string): Promise<TaxiTrip[]>;
  abstract findByDriver(driverId: string): Promise<TaxiTrip[]>;
  /** Yangi (PENDING), hali haydovchi biriktirilmagan safarlar. */
  abstract findAvailable(): Promise<TaxiTrip[]>;
  /** Haydovchini biriktiradi va ACCEPTED holatga o'tkazadi. */
  abstract assignDriver(id: string, driverId: string): Promise<TaxiTrip>;
  abstract updateStatus(id: string, status: TaxiStatus): Promise<TaxiTrip>;
}
