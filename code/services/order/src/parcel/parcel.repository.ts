import {
  NewParcelDelivery,
  ParcelDelivery,
  ParcelStatus,
  StatusActor,
} from './entities';

export interface UpdateStatusMeta {
  by?: StatusActor;
  driverId?: string;
  reason?: string;
}

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
    meta?: UpdateStatusMeta,
  ): Promise<ParcelDelivery>;
  /** Biriktirilgan kuryerni bo'shatib PENDING'ga qaytaradi (kuryer bekor qildi). */
  abstract releaseToPending(
    id: string,
    reason?: string,
    note?: string,
  ): Promise<ParcelDelivery>;
  /** Mijoz bahosi (1-5) + izoh. */
  abstract setRating(
    id: string,
    rating: number,
    comment?: string,
  ): Promise<ParcelDelivery>;
  /** Kuryerning o'rtacha bahosi va baholar soni. */
  abstract driverRatingStats(
    driverId: string,
  ): Promise<{ avg: number; count: number }>;
}
