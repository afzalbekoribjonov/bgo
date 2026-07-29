import { Order, OrderEarningsRow, OrderStatsRow, OrderStatus, StatusActor } from './entities';

export interface UpdateStatusMeta {
  by?: StatusActor;
  driverId?: string;
  reason?: string;
}

export type NewOrderData = Omit<
  Order,
  'id' | 'publicNo' | 'status' | 'statusHistory' | 'createdAt' | 'updatedAt'
>;

/**
 * Buyurtma repository interfeysi. Hozir: in-memory (dev).
 * Keyin: Prisma/PostgreSQL (order_db) — plan/03-databases.md.
 */
export abstract class OrderRepository {
  abstract create(data: NewOrderData): Promise<Order>;
  abstract findById(id: string): Promise<Order | null>;
  /** Barcha buyurtmalar (admin/hisobot uchun), eng yangisi birinchi. */
  abstract findAll(): Promise<Order[]>;
  /** Admin statistika/hisobot uchun qisqartirilgan qatorlar (select — items/address/statusHistory'siz). */
  abstract findAllForStats(): Promise<OrderStatsRow[]>;
  abstract findByCustomer(customerId: string): Promise<Order[]>;
  abstract findByRestaurant(restaurantId: string): Promise<Order[]>;
  /** Yetkazishga tayyor, hali haydovchi biriktirilmagan buyurtmalar (READY). */
  abstract findAvailableForDelivery(): Promise<Order[]>;
  abstract findByDriver(driverId: string): Promise<Order[]>;
  /** Bitta buyurtma — haydovchi + publicNo bo'yicha to'g'ridan-to'g'ri (AI shikoyat qidiruvi). */
  abstract findByDriverAndPublicNo(driverId: string, publicNo: number): Promise<Order | null>;
  /** Haydovchi daromadi/statistikasi uchun qisqartirilgan qatorlar. */
  abstract findByDriverForEarnings(driverId: string): Promise<OrderEarningsRow[]>;
  /** Haydovchini biriktiradi va ASSIGNED holatga o'tkazadi (eskirgan oqim). */
  abstract assignDriver(id: string, driverId: string): Promise<Order>;
  /** Haydovchi ovqat buyurtmasini qabul qildi — driverId + driverAcceptedAt (status o'zgармaydi). */
  abstract setDriverAccepted(id: string, driverId: string): Promise<Order>;
  /** Haydovchi voz kechdi — driverId + driverAcceptedAt tozalanadi (status qoladi). */
  abstract clearDriver(id: string, reason?: string, note?: string): Promise<Order>;
  /** Oshxona buyurtmani qabul qildi — kitchenAcceptedAt. */
  abstract setKitchenAccepted(id: string): Promise<Order>;
  abstract setRating(id: string, rating: number, comment?: string): Promise<Order>;
  abstract updateStatus(
    id: string,
    status: OrderStatus,
    meta?: UpdateStatusMeta,
  ): Promise<Order>;
}
