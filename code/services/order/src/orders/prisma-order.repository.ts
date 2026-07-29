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
import { NewOrderData, OrderRepository, UpdateStatusMeta } from './order.repository';

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
        serviceFee: data.serviceFee,
        deliveryFee: data.deliveryFee,
        commission: data.commission,
        courierEarning: data.courierEarning,
        promoCode: data.promoCode,
        discount: data.discount,
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

  async findAll(): Promise<Order[]> {
    const rows = await this.prisma.order.findMany({
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((o) => this.toOrder(o as Row));
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

  async findAvailableForDelivery(): Promise<Order[]> {
    const rows = await this.prisma.order.findMany({
      where: { status: 'READY', driverId: null, type: 'FOOD' },
      orderBy: { createdAt: 'asc' },
    });
    return rows.map((o) => this.toOrder(o as Row));
  }

  async findByDriver(driverId: string): Promise<Order[]> {
    const rows = await this.prisma.order.findMany({
      where: { driverId },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((o) => this.toOrder(o as Row));
  }

  async assignDriver(id: string, driverId: string): Promise<Order> {
    const existing = await this.prisma.order.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Buyurtma topilmadi');
    const history = [
      ...((existing.statusHistory as unknown as OrderStatusEntry[]) ?? []),
      { status: 'ASSIGNED' as OrderStatus, at: new Date().toISOString() },
    ];
    const updated = await this.prisma.order.update({
      where: { id },
      data: {
        driverId,
        status: 'ASSIGNED',
        statusHistory: history as unknown as Prisma.InputJsonValue,
      },
    });
    return this.toOrder(updated as Row);
  }

  async setDriverAccepted(id: string, driverId: string): Promise<Order> {
    const updated = await this.prisma.order.update({
      where: { id },
      data: { driverId, driverAcceptedAt: new Date() },
    });
    return this.toOrder(updated as Row);
  }

  async clearDriver(id: string, reason?: string, note?: string): Promise<Order> {
    let historyPatch: { statusHistory: Prisma.InputJsonValue } | Record<string, never> = {};
    if (reason) {
      const existing = await this.prisma.order.findUnique({ where: { id } });
      if (existing) {
        const history = [
          ...((existing.statusHistory as unknown as OrderStatusEntry[]) ?? []),
          {
            status: existing.status as OrderStatus,
            at: new Date().toISOString(),
            by: 'driver' as const,
            ...(existing.driverId ? { driverId: existing.driverId } : {}),
            reason: note ? `${reason}: ${note}` : reason,
          },
        ];
        historyPatch = { statusHistory: history as unknown as Prisma.InputJsonValue };
      }
    }
    const updated = await this.prisma.order.update({
      where: { id },
      data: { driverId: null, driverAcceptedAt: null, ...historyPatch },
    });
    return this.toOrder(updated as Row);
  }

  async setKitchenAccepted(id: string): Promise<Order> {
    const updated = await this.prisma.order.update({
      where: { id },
      data: { kitchenAcceptedAt: new Date() },
    });
    return this.toOrder(updated as Row);
  }

  async setRating(id: string, rating: number, comment?: string): Promise<Order> {
    const updated = await this.prisma.order.update({
      where: { id },
      data: { rating, ratingComment: comment },
    });
    return this.toOrder(updated as Row);
  }

  async updateStatus(
    id: string,
    status: OrderStatus,
    meta?: UpdateStatusMeta,
  ): Promise<Order> {
    const existing = await this.prisma.order.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Buyurtma topilmadi');
    const entry: OrderStatusEntry = { status, at: new Date().toISOString() };
    if (meta?.by) entry.by = meta.by;
    if (meta?.driverId) entry.driverId = meta.driverId;
    if (meta?.reason) entry.reason = meta.reason;
    const history = [
      ...((existing.statusHistory as unknown as OrderStatusEntry[]) ?? []),
      entry,
    ];
    const updated = await this.prisma.order.update({
      where: { id },
      data: {
        status,
        statusHistory: history as unknown as Prisma.InputJsonValue,
        // PICKED_UP boshlanganda GPS masofa hisoblagichi 0'dan boshlanadi
        // (increment NULL ustida ishlamaydi).
        ...(status === 'PICKED_UP' ? { actualDistanceKm: 0 } : {}),
      },
    });
    return this.toOrder(updated as Row);
  }

  private toOrder(o: Row): Order {
    return {
      id: o.id as string,
      publicNo: o.publicNo as number,
      customerId: o.customerId as string,
      driverId: (o.driverId as string) ?? undefined,
      type: o.type as OrderType,
      restaurantId: o.restaurantId as string,
      items: o.items as unknown as OrderItem[],
      itemsTotal: o.itemsTotal as number,
      serviceFee: (o.serviceFee as number) ?? 0,
      deliveryFee: o.deliveryFee as number,
      commission: (o.commission as number) ?? 0,
      courierEarning: (o.courierEarning as number) ?? 0,
      promoCode: (o.promoCode as string) ?? undefined,
      discount: (o.discount as number) ?? 0,
      total: o.total as number,
      paymentType: o.paymentType as PaymentType,
      address: o.address as unknown as OrderAddress,
      actualDistanceKm: (o.actualDistanceKm as number | null) ?? undefined,
      status: o.status as OrderStatus,
      kitchenAcceptedAt: (o.kitchenAcceptedAt as Date | null)?.toISOString() ?? null,
      driverAcceptedAt: (o.driverAcceptedAt as Date | null)?.toISOString() ?? null,
      rating: (o.rating as number | null) ?? null,
      ratingComment: (o.ratingComment as string | null) ?? null,
      statusHistory: o.statusHistory as unknown as OrderStatusEntry[],
      createdAt: (o.createdAt as Date).toISOString(),
      updatedAt: (o.updatedAt as Date).toISOString(),
    };
  }
}
