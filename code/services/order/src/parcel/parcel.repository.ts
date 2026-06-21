import { NewParcelDelivery, ParcelDelivery, ParcelStatus } from './entities';

/** Dostavka repository interfeysi (abstrakt). */
export abstract class ParcelRepository {
  abstract create(data: NewParcelDelivery): Promise<ParcelDelivery>;
  abstract findById(id: string): Promise<ParcelDelivery | null>;
  /** Barcha dostavkalar (admin hisobot uchun). */
  abstract findAll(): Promise<ParcelDelivery[]>;
  abstract findByCustomer(customerId: string): Promise<ParcelDelivery[]>;
  abstract findByDriver(driverId: string): Promise<ParcelDelivery[]>;
  /** Yangi (PENDING), hali kuryer biriktirilmagan dostavkalar. */
  abstract findAvailable(): Promise<ParcelDelivery[]>;
  abstract assignDriver(id: string, driverId: string): Promise<ParcelDelivery>;
  abstract updateStatus(
    id: string,
    status: ParcelStatus,
  ): Promise<ParcelDelivery>;
}
