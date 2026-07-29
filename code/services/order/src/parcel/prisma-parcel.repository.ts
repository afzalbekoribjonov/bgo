import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '../../prisma/generated/client';
import { GeoPoint } from '../common/geo';
import { PrismaService } from '../prisma/prisma.service';
import {
  NewParcelDelivery,
  ParcelDelivery,
  ParcelSize,
  ParcelStatus,
  ParcelStatusEntry,
} from './entities';
import { ParcelRepository, UpdateStatusMeta } from './parcel.repository';

type Row = Record<string, unknown>;

/** PostgreSQL (order_db) implementatsiyasi. plan/03-databases.md */
@Injectable()
export class PrismaParcelRepository extends ParcelRepository {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async create(data: NewParcelDelivery): Promise<ParcelDelivery> {
    const now = new Date().toISOString();
    const history: ParcelStatusEntry[] = [{ status: 'PENDING', at: now }];
    const created = await this.prisma.parcelDelivery.create({
      data: {
        customerId: data.customerId,
        pickup: data.pickup as unknown as Prisma.InputJsonValue,
        destination: data.destination as unknown as Prisma.InputJsonValue,
        distanceKm: data.distanceKm,
        size: data.size,
        recipientName: data.recipientName,
        recipientPhone: data.recipientPhone,
        note: data.note,
        fare: data.fare,
        commission: data.commission,
        driverEarning: data.driverEarning,
        status: 'PENDING',
        statusHistory: history as unknown as Prisma.InputJsonValue,
      },
    });
    return this.toParcel(created as Row);
  }

  async findById(id: string): Promise<ParcelDelivery | null> {
    const p = await this.prisma.parcelDelivery.findUnique({ where: { id } });
    return p ? this.toParcel(p as Row) : null;
  }

  async findAll(): Promise<ParcelDelivery[]> {
    const rows = await this.prisma.parcelDelivery.findMany({
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((p) => this.toParcel(p as Row));
  }

  async findByCustomer(customerId: string): Promise<ParcelDelivery[]> {
    const rows = await this.prisma.parcelDelivery.findMany({
      where: { customerId },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((p) => this.toParcel(p as Row));
  }

  async findByDriver(driverId: string): Promise<ParcelDelivery[]> {
    const rows = await this.prisma.parcelDelivery.findMany({
      where: { driverId },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((p) => this.toParcel(p as Row));
  }

  async findByDriverAndPublicNo(driverId: string, publicNo: number): Promise<ParcelDelivery | null> {
    const p = await this.prisma.parcelDelivery.findFirst({ where: { driverId, publicNo } });
    return p ? this.toParcel(p as Row) : null;
  }

  async findAvailable(): Promise<ParcelDelivery[]> {
    const rows = await this.prisma.parcelDelivery.findMany({
      where: { status: 'PENDING', driverId: null },
      orderBy: { createdAt: 'asc' },
    });
    return rows.map((p) => this.toParcel(p as Row));
  }

  async assignDriver(id: string, driverId: string): Promise<ParcelDelivery> {
    const existing = await this.prisma.parcelDelivery.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Dostavka topilmadi');
    const history = [
      ...((existing.statusHistory as unknown as ParcelStatusEntry[]) ?? []),
      { status: 'ACCEPTED' as ParcelStatus, at: new Date().toISOString() },
    ];
    const updated = await this.prisma.parcelDelivery.update({
      where: { id },
      data: {
        driverId,
        status: 'ACCEPTED',
        statusHistory: history as unknown as Prisma.InputJsonValue,
      },
    });
    return this.toParcel(updated as Row);
  }

  async updateStatus(
    id: string,
    status: ParcelStatus,
    meta?: UpdateStatusMeta,
  ): Promise<ParcelDelivery> {
    const existing = await this.prisma.parcelDelivery.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Dostavka topilmadi');
    const entry: ParcelStatusEntry = { status, at: new Date().toISOString() };
    if (meta?.by) entry.by = meta.by;
    if (meta?.driverId) entry.driverId = meta.driverId;
    if (meta?.reason) entry.reason = meta.reason;
    const history = [
      ...((existing.statusHistory as unknown as ParcelStatusEntry[]) ?? []),
      entry,
    ];
    const updated = await this.prisma.parcelDelivery.update({
      where: { id },
      data: {
        status,
        statusHistory: history as unknown as Prisma.InputJsonValue,
        // IN_TRANSIT boshlanganda GPS masofa hisoblagichi 0'dan boshlanadi
        // (increment NULL ustida ishlamaydi).
        ...(status === 'IN_TRANSIT' ? { actualDistanceKm: 0 } : {}),
        // DELIVERED — ko'rsatiladigan masofa GPS bo'yicha haqiqiy bosib
        // o'tilganga yangilanadi (boshlang'ich chiziqli/havodan taxmin emas).
        // Narxga ta'sir qilmaydi (fare yaratishda hisoblangan holicha qoladi).
        ...(status === 'DELIVERED' &&
        typeof existing.actualDistanceKm === 'number' &&
        existing.actualDistanceKm > 0.05
          ? { distanceKm: Math.round(existing.actualDistanceKm * 100) / 100 }
          : {}),
      },
    });
    return this.toParcel(updated as Row);
  }

  async releaseToPending(id: string, reason?: string, note?: string): Promise<ParcelDelivery> {
    const existing = await this.prisma.parcelDelivery.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Dostavka topilmadi');
    const history = [
      ...((existing.statusHistory as unknown as ParcelStatusEntry[]) ?? []),
      {
        status: 'PENDING' as ParcelStatus,
        at: new Date().toISOString(),
        by: 'driver' as const,
        ...(existing.driverId ? { driverId: existing.driverId } : {}),
        ...(reason ? { reason: note ? `${reason}: ${note}` : reason } : {}),
      },
    ];
    const updated = await this.prisma.parcelDelivery.update({
      where: { id },
      data: {
        driverId: null,
        status: 'PENDING',
        statusHistory: history as unknown as Prisma.InputJsonValue,
      },
    });
    return this.toParcel(updated as Row);
  }

  async setRating(
    id: string,
    rating: number,
    comment?: string,
  ): Promise<ParcelDelivery> {
    const updated = await this.prisma.parcelDelivery.update({
      where: { id },
      data: { rating, ratingComment: comment ?? null },
    });
    return this.toParcel(updated as Row);
  }

  async driverRatingStats(
    driverId: string,
  ): Promise<{ avg: number; count: number }> {
    const agg = await this.prisma.parcelDelivery.aggregate({
      where: { driverId, rating: { not: null } },
      _avg: { rating: true },
      _count: { rating: true },
    });
    const avg = agg._avg.rating ?? 0;
    return { avg: Math.round(avg * 10) / 10, count: agg._count.rating };
  }

  private toParcel(p: Row): ParcelDelivery {
    return {
      id: p.id as string,
      publicNo: p.publicNo as number,
      customerId: p.customerId as string,
      driverId: (p.driverId as string) ?? undefined,
      pickup: p.pickup as unknown as GeoPoint,
      destination: p.destination as unknown as GeoPoint,
      distanceKm: p.distanceKm as number,
      actualDistanceKm: (p.actualDistanceKm as number | null) ?? undefined,
      size: p.size as ParcelSize,
      recipientName: p.recipientName as string,
      recipientPhone: p.recipientPhone as string,
      note: (p.note as string) ?? undefined,
      fare: p.fare as number,
      commission: (p.commission as number) ?? 0,
      driverEarning: (p.driverEarning as number) ?? 0,
      status: p.status as ParcelStatus,
      paymentType: 'CASH',
      statusHistory: p.statusHistory as unknown as ParcelStatusEntry[],
      rating: (p.rating as number) ?? undefined,
      ratingComment: (p.ratingComment as string) ?? undefined,
      createdAt: (p.createdAt as Date).toISOString(),
      updatedAt: (p.updatedAt as Date).toISOString(),
    };
  }
}
