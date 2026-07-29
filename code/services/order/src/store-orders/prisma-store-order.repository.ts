import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '../../prisma/generated/client';
import { GeoPoint } from '../common/geo';
import { PrismaService } from '../prisma/prisma.service';
import {
  NewStoreOrder,
  StoreDeliveryMethod,
  StoreOrder,
  StoreOrderEarningsRow,
  StoreOrderItem,
  StoreOrderStatsRow,
  StoreOrderStatus,
  StoreOrderStatusEntry,
} from './entities';
import { StoreOrderRepository, UpdateStoreStatusMeta } from './store-order.repository';

type Row = Record<string, unknown>;

/** PostgreSQL (order_db) implementatsiyasi. */
@Injectable()
export class PrismaStoreOrderRepository extends StoreOrderRepository {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async create(data: NewStoreOrder): Promise<StoreOrder> {
    const now = new Date().toISOString();
    const initialStatus: StoreOrderStatus = 'PENDING';
    const history: StoreOrderStatusEntry[] = [{ status: initialStatus, at: now }];
    const created = await this.prisma.storeOrder.create({
      data: {
        customerId: data.customerId,
        pickupLocationId: data.pickupLocationId,
        deliveryMethod: data.deliveryMethod,
        address: data.address ? (data.address as unknown as Prisma.InputJsonValue) : Prisma.JsonNull,
        items: data.items as unknown as Prisma.InputJsonValue,
        itemsTotal: data.itemsTotal,
        deliveryFee: data.deliveryFee,
        courierEarning: data.courierEarning,
        total: data.total,
        status: initialStatus,
        statusHistory: history as unknown as Prisma.InputJsonValue,
      },
    });
    return this.toStoreOrder(created as Row);
  }

  async findById(id: string): Promise<StoreOrder | null> {
    const o = await this.prisma.storeOrder.findUnique({ where: { id } });
    return o ? this.toStoreOrder(o as Row) : null;
  }

  async findAll(): Promise<StoreOrder[]> {
    const rows = await this.prisma.storeOrder.findMany({
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((o) => this.toStoreOrder(o as Row));
  }

  async findByCustomer(customerId: string): Promise<StoreOrder[]> {
    const rows = await this.prisma.storeOrder.findMany({
      where: { customerId },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((o) => this.toStoreOrder(o as Row));
  }

  async findByDriver(driverId: string): Promise<StoreOrder[]> {
    const rows = await this.prisma.storeOrder.findMany({
      where: { driverId },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((o) => this.toStoreOrder(o as Row));
  }

  async findAllForStats(): Promise<StoreOrderStatsRow[]> {
    const rows = await this.prisma.storeOrder.findMany({
      select: { status: true, createdAt: true, total: true },
    });
    return rows.map((r) => ({
      status: r.status as StoreOrderStatus,
      createdAt: r.createdAt.toISOString(),
      total: r.total,
    }));
  }

  async findByDriverForEarnings(driverId: string): Promise<StoreOrderEarningsRow[]> {
    const rows = await this.prisma.storeOrder.findMany({
      where: { driverId },
      select: { status: true, createdAt: true, total: true, courierEarning: true, updatedAt: true },
    });
    return rows.map((r) => ({
      status: r.status as StoreOrderStatus,
      createdAt: r.createdAt.toISOString(),
      total: r.total,
      courierEarning: r.courierEarning,
      updatedAt: r.updatedAt.toISOString(),
    }));
  }

  async findAvailable(): Promise<StoreOrder[]> {
    const rows = await this.prisma.storeOrder.findMany({
      where: { status: 'PENDING', driverId: null, deliveryMethod: 'DELIVERY' },
      orderBy: { createdAt: 'asc' },
    });
    return rows.map((o) => this.toStoreOrder(o as Row));
  }

  async assignDriver(id: string, driverId: string): Promise<StoreOrder> {
    const existing = await this.prisma.storeOrder.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Buyurtma topilmadi');
    const history = [
      ...((existing.statusHistory as unknown as StoreOrderStatusEntry[]) ?? []),
      { status: 'ACCEPTED' as StoreOrderStatus, at: new Date().toISOString() },
    ];
    const updated = await this.prisma.storeOrder.update({
      where: { id },
      data: {
        driverId,
        status: 'ACCEPTED',
        statusHistory: history as unknown as Prisma.InputJsonValue,
      },
    });
    return this.toStoreOrder(updated as Row);
  }

  async updateStatus(
    id: string,
    status: StoreOrderStatus,
    meta?: UpdateStoreStatusMeta,
  ): Promise<StoreOrder> {
    const existing = await this.prisma.storeOrder.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Buyurtma topilmadi');
    const entry: StoreOrderStatusEntry = { status, at: new Date().toISOString() };
    if (meta?.by) entry.by = meta.by;
    if (meta?.driverId) entry.driverId = meta.driverId;
    if (meta?.reason) entry.reason = meta.reason;
    const history = [
      ...((existing.statusHistory as unknown as StoreOrderStatusEntry[]) ?? []),
      entry,
    ];
    const updated = await this.prisma.storeOrder.update({
      where: { id },
      data: { status, statusHistory: history as unknown as Prisma.InputJsonValue },
    });
    return this.toStoreOrder(updated as Row);
  }

  async releaseToPending(id: string): Promise<StoreOrder> {
    const existing = await this.prisma.storeOrder.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Buyurtma topilmadi');
    const history = [
      ...((existing.statusHistory as unknown as StoreOrderStatusEntry[]) ?? []),
      {
        status: 'PENDING' as StoreOrderStatus,
        at: new Date().toISOString(),
        by: 'driver' as const,
        ...(existing.driverId ? { driverId: existing.driverId } : {}),
      },
    ];
    const updated = await this.prisma.storeOrder.update({
      where: { id },
      data: {
        driverId: null,
        status: 'PENDING',
        statusHistory: history as unknown as Prisma.InputJsonValue,
      },
    });
    return this.toStoreOrder(updated as Row);
  }

  async setRating(id: string, rating: number, comment?: string): Promise<StoreOrder> {
    const updated = await this.prisma.storeOrder.update({
      where: { id },
      data: { rating, ratingComment: comment ?? null },
    });
    return this.toStoreOrder(updated as Row);
  }

  async driverRatingStats(driverId: string): Promise<{ avg: number; count: number }> {
    const agg = await this.prisma.storeOrder.aggregate({
      where: { driverId, rating: { not: null } },
      _avg: { rating: true },
      _count: { rating: true },
    });
    const avg = agg._avg.rating ?? 0;
    return { avg: Math.round(avg * 10) / 10, count: agg._count.rating };
  }

  private toStoreOrder(o: Row): StoreOrder {
    return {
      id: o.id as string,
      publicNo: o.publicNo as number,
      customerId: o.customerId as string,
      driverId: (o.driverId as string) ?? undefined,
      pickupLocationId: o.pickupLocationId as string,
      deliveryMethod: o.deliveryMethod as StoreDeliveryMethod,
      address: (o.address as unknown as GeoPoint) ?? undefined,
      items: o.items as unknown as StoreOrderItem[],
      itemsTotal: o.itemsTotal as number,
      deliveryFee: (o.deliveryFee as number) ?? 0,
      courierEarning: (o.courierEarning as number) ?? 0,
      total: o.total as number,
      status: o.status as StoreOrderStatus,
      paymentType: 'CASH',
      statusHistory: o.statusHistory as unknown as StoreOrderStatusEntry[],
      rating: (o.rating as number) ?? undefined,
      ratingComment: (o.ratingComment as string) ?? undefined,
      createdAt: (o.createdAt as Date).toISOString(),
      updatedAt: (o.updatedAt as Date).toISOString(),
    };
  }
}
