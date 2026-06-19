import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '../../prisma/generated/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  Order,
  OrderAddress,
  OrderItem,
  OrderStatus,
  OrderStatusEntry,
  OrderType,
  PaymentType,
} from './entities';
import { NewOrderData, OrderRepository } from './order.repository';

type Row = Record<string, unknown>;

/** PostgreSQL (order_db) implementatsiyasi. plan/03-databases.md */
@Injectable()
export class PrismaOrderRepository extends OrderRepository {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async create(data: NewOrderData): Promise<Order> {
    const now = new Date().toISOString();
    const history: OrderStatusEntry[] = [{ status: 'PENDING', at: now }];
    const created = await this.prisma.order.create({
      data: {
        customerId: data.customerId,
        type: data.type,
        restaurantId: data.restaurantId,
        items: data.items as unknown as Prisma.InputJsonValue,
        itemsTotal: data.itemsTotal,
        deliveryFee: data.deliveryFee,
        total: data.total,
        paymentType: data.paymentType,
        address: data.address as unknown as Prisma.InputJsonValue,
        status: 'PENDING',
        statusHistory: history as unknown as Prisma.InputJsonValue,
      },
    });
    return this.toOrder(created as Row);
  }

  async findById(id: string): Promise<Order | null> {
    const o = await this.prisma.order.findUnique({ where: { id } });
    return o ? this.toOrder(o as Row) : null;
  }

  async findByCustomer(customerId: string): Promise<Order[]> {
    const rows = await this.prisma.order.findMany({
      where: { customerId },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((o) => this.toOrder(o as Row));
  }

  async findByRestaurant(restaurantId: string): Promise<Order[]> {
    const rows = await this.prisma.order.findMany({
      where: { restaurantId },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((o) => this.toOrder(o as Row));
  }

  async updateStatus(id: string, status: OrderStatus): Promise<Order> {
    const existing = await this.prisma.order.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Buyurtma topilmadi');
    const history = [
      ...((existing.statusHistory as unknown as OrderStatusEntry[]) ?? []),
      { status, at: new Date().toISOString() },
    ];
    const updated = await this.prisma.order.update({
      where: { id },
      data: {
        status,
        statusHistory: history as unknown as Prisma.InputJsonValue,
      },
    });
    return this.toOrder(updated as Row);
  }

  private toOrder(o: Row): Order {
    return {
      id: o.id as string,
      publicNo: o.publicNo as number,
      customerId: o.customerId as string,
      type: o.type as OrderType,
      restaurantId: o.restaurantId as string,
      items: o.items as unknown as OrderItem[],
      itemsTotal: o.itemsTotal as number,
      deliveryFee: o.deliveryFee as number,
      total: o.total as number,
      paymentType: o.paymentType as PaymentType,
      address: o.address as unknown as OrderAddress,
      status: o.status as OrderStatus,
      statusHistory: o.statusHistory as unknown as OrderStatusEntry[],
      createdAt: (o.createdAt as Date).toISOString(),
    };
  }
}
