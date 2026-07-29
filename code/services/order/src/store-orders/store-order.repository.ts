import {
  NewStoreOrder,
  StatusActor,
  StoreOrder,
  StoreOrderEarningsRow,
  StoreOrderStatsRow,
  StoreOrderStatus,
} from './entities';

export interface UpdateStoreStatusMeta {
  by?: StatusActor;
  driverId?: string;
  reason?: string;
}

/** Market buyurtmasi repository interfeysi (abstrakt). */
export abstract class StoreOrderRepository {
  abstract create(data: NewStoreOrder): Promise<StoreOrder>;
  abstract findById(id: string): Promise<StoreOrder | null>;
  abstract findAll(): Promise<StoreOrder[]>;
  /** Admin statistika/hisobot uchun qisqartirilgan qatorlar (select — items/address/statusHistory'siz). */
  abstract findAllForStats(): Promise<StoreOrderStatsRow[]>;
  abstract findByCustomer(customerId: string): Promise<StoreOrder[]>;
  abstract findByDriver(driverId: string): Promise<StoreOrder[]>;
  /** Kuryer daromadi/statistikasi uchun qisqartirilgan qatorlar. */
  abstract findByDriverForEarnings(driverId: string): Promise<StoreOrderEarningsRow[]>;
  /** Yangi (PENDING), hali kuryer biriktirilmagan DELIVERY buyurtmalar. */
  abstract findAvailable(): Promise<StoreOrder[]>;
  abstract assignDriver(id: string, driverId: string): Promise<StoreOrder>;
  abstract updateStatus(
    id: string,
    status: StoreOrderStatus,
    meta?: UpdateStoreStatusMeta,
  ): Promise<StoreOrder>;
  /** Biriktirilgan kuryerni bo'shatib PENDING'ga qaytaradi (kuryer bekor qildi). */
  abstract releaseToPending(id: string): Promise<StoreOrder>;
  abstract setRating(id: string, rating: number, comment?: string): Promise<StoreOrder>;
  abstract driverRatingStats(driverId: string): Promise<{ avg: number; count: number }>;
}
