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
  abstract updateStatus(id: string, status: OrderStatus): Promise<Order>;
}
