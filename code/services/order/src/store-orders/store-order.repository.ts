import {
  NewStoreOrder,
  StatusActor,
  StoreDeliveryMethod,
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

/** DB darajasidagi filtr — admin buyurtmalar ro'yxati (sahifalangan). */
export interface StoreOrderAdminFilter {
  status?: StoreOrderStatus;
  deliveryMethod?: StoreDeliveryMethod;
  fromTs?: number;
  toTs?: number;
  /** Berilsa — faqat READY_FOR_PICKUP VA readyAt shu vaqtdan oldin bo'lganlar. */
  overdueBefore?: number;
  /** Aniq buyurtma raqami (qidiruv — sof raqamli so'rov). */
  publicNo?: number;
  /** Erkin-matn qidiruv (mahsulot nomi/o'lcham/manzil) — JSON ustunlar ichida. */
  textQuery?: string;
}

/** Market buyurtmasi repository interfeysi (abstrakt). */
export abstract class StoreOrderRepository {
  abstract create(data: NewStoreOrder): Promise<StoreOrder>;
  abstract findById(id: string): Promise<StoreOrder | null>;
  abstract findAllPaged(
    filter: StoreOrderAdminFilter,
    page: number,
    pageSize: number,
  ): Promise<{ items: StoreOrder[]; total: number; revenueSum: number; activeCount: number }>;
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
