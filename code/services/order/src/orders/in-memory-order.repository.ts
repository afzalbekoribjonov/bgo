import { Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { Order, OrderStatus } from './entities';
import { NewOrderData, OrderRepository } from './order.repository';

/**
 * Xotirada saqlovchi buyurtma repository — FAQAT dev/test uchun.
 * TODO(Docker): PrismaOrderRepository (PostgreSQL order_db).
 */
@Injectable()
export class InMemoryOrderRepository extends OrderRepository {
  private readonly orders = new Map<string, Order>();
  private nextPublicNo = 1001;

  async create(data: NewOrderData): Promise<Order> {
    const now = new Date().toISOString();
    const order: Order = {
      ...data,
      id: randomUUID(),
      publicNo: this.nextPublicNo++,
      status: 'PENDING',
      statusHistory: [{ status: 'PENDING', at: now }],
      createdAt: now,
    };
    this.orders.set(order.id, order);
    return { ...order };
  }

  async findById(id: string): Promise<Order | null> {
    const order = this.orders.get(id);
    return order ? { ...order } : null;
  }

  async findByCustomer(customerId: string): Promise<Order[]> {
    return [...this.orders.values()]
      .filter((o) => o.customerId === customerId)
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  }

  async findByRestaurant(restaurantId: string): Promise<Order[]> {
    return [...this.orders.values()]
      .filter((o) => o.restaurantId === restaurantId)
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  }

  async updateStatus(id: string, status: OrderStatus): Promise<Order> {
    const order = this.orders.get(id);
    if (!order) throw new NotFoundException('Buyurtma topilmadi');
    order.status = status;
    order.statusHistory.push({ status, at: new Date().toISOString() });
    this.orders.set(id, order);
    return { ...order };
  }
}
