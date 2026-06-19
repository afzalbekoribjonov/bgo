import { Order, OrderStatus } from './entities';

export type NewOrderData = Omit<
  Order,
  'id' | 'publicNo' | 'status' | 'statusHistory' | 'createdAt'
>;

/**
 * Buyurtma repository interfeysi. Hozir: in-memory (dev).
 * Keyin: Prisma/PostgreSQL (order_db) — plan/03-databases.md.
 */
export abstract class OrderRepository {
  abstract create(data: NewOrderData): Promise<Order>;
  abstract findById(id: string): Promise<Order | null>;
  abstract findByCustomer(customerId: string): Promise<Order[]>;
  abstract findByRestaurant(restaurantId: string): Promise<Order[]>;
  /** Yetkazishga tayyor, hali haydovchi biriktirilmagan buyurtmalar (READY). */
  abstract findAvailableForDelivery(): Promise<Order[]>;
  abstract findByDriver(driverId: string): Promise<Order[]>;
  /** Haydovchini biriktiradi va ASSIGNED holatga o'tkazadi. */
  abstract assignDriver(id: string, driverId: string): Promise<Order>;
  abstract updateStatus(id: string, status: OrderStatus): Promise<Order>;
}
