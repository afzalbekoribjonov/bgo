import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '../../prisma/generated/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  AssignPricing,
  FinalizeTaxiTrip,
  GeoPoint,
  NewTaxiTrip,
  TaxiEarningsRow,
  TaxiStatsRow,
  TaxiStatus,
  TaxiStatusEntry,
  TaxiTrip,
} from './entities';
import { TaxiRepository, UpdateStatusMeta } from './taxi.repository';

type Row = Record<string, unknown>;

/** PostgreSQL (order_db) implementatsiyasi. plan/03-databases.md */
@Injectable()
export class PrismaTaxiRepository extends TaxiRepository {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async create(data: NewTaxiTrip): Promise<TaxiTrip> {
    const now = new Date().toISOString();
    const history: TaxiStatusEntry[] = [{ status: 'PENDING', at: now }];
    const created = await this.prisma.taxiTrip.create({
      data: {
        customerId: data.customerId,
        pickup: data.pickup as unknown as Prisma.InputJsonValue,
        destination: (data.destination ?? undefined) as unknown as Prisma.InputJsonValue,
        metered: data.metered,
        tariffClass: data.tariffClass,
        distanceKm: data.distanceKm,
        fare: data.fare,
        commission: data.commission,
        driverEarning: data.driverEarning,
        status: 'PENDING',
        statusHistory: history as unknown as Prisma.InputJsonValue,
      },
    });
    return this.toTrip(created as Row);
  }

  async findById(id: string): Promise<TaxiTrip | null> {
    const t = await this.prisma.taxiTrip.findUnique({ where: { id } });
    return t ? this.toTrip(t as Row) : null;
  }

  async findAll(): Promise<TaxiTrip[]> {
    const rows = await this.prisma.taxiTrip.findMany({
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((t) => this.toTrip(t as Row));
  }

  async findByCustomer(customerId: string): Promise<TaxiTrip[]> {
    const rows = await this.prisma.taxiTrip.findMany({
      where: { customerId },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((t) => this.toTrip(t as Row));
  }

  async findByDriver(driverId: string): Promise<TaxiTrip[]> {
    const rows = await this.prisma.taxiTrip.findMany({
      where: { driverId },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((t) => this.toTrip(t as Row));
  }

  async findAllForStats(): Promise<TaxiStatsRow[]> {
    const rows = await this.prisma.taxiTrip.findMany({
      select: { status: true, createdAt: true, fare: true, commission: true, driverId: true },
    });
    return rows.map((r) => ({
      status: r.status as TaxiStatus,
      createdAt: r.createdAt.toISOString(),
      fare: r.fare,
      commission: r.commission,
      driverId: r.driverId ?? undefined,
    }));
  }

  async findByDriverForEarnings(driverId: string): Promise<TaxiEarningsRow[]> {
    const rows = await this.prisma.taxiTrip.findMany({
      where: { driverId },
      select: { status: true, createdAt: true, fare: true, driverEarning: true, updatedAt: true },
    });
    return rows.map((r) => ({
      status: r.status as TaxiStatus,
      createdAt: r.createdAt.toISOString(),
      fare: r.fare,
      driverEarning: r.driverEarning,
      updatedAt: r.updatedAt.toISOString(),
    }));
  }

  async findByDriverAndPublicNo(driverId: string, publicNo: number): Promise<TaxiTrip | null> {
    const t = await this.prisma.taxiTrip.findFirst({ where: { driverId, publicNo } });
    return t ? this.toTrip(t as Row) : null;
  }

  async findAvailable(): Promise<TaxiTrip[]> {
    const rows = await this.prisma.taxiTrip.findMany({
      where: { status: 'PENDING', driverId: null },
      orderBy: { createdAt: 'asc' },
    });
    return rows.map((t) => this.toTrip(t as Row));
  }

  async assignDriver(
    id: string,
    driverId: string,
    pricing?: AssignPricing,
  ): Promise<TaxiTrip> {
    const existing = await this.prisma.taxiTrip.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Safar topilmadi');
    const history = [
      ...((existing.statusHistory as unknown as TaxiStatusEntry[]) ?? []),
      { status: 'ACCEPTED' as TaxiStatus, at: new Date().toISOString() },
    ];
    const updated = await this.prisma.taxiTrip.update({
      where: { id },
      data: {
        driverId,
        status: 'ACCEPTED',
        statusHistory: history as unknown as Prisma.InputJsonValue,
        ...(pricing
          ? {
              pickupDistanceKm: pricing.pickupDistanceKm,
              pickupSurcharge: pricing.pickupSurcharge,
            }
          : {}),
      },
    });
    return this.toTrip(updated as Row);
  }

  async markArrived(id: string): Promise<TaxiTrip> {
    const existing = await this.prisma.taxiTrip.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Safar topilmadi');
    const history = [
      ...((existing.statusHistory as unknown as TaxiStatusEntry[]) ?? []),
      { status: 'ARRIVED' as TaxiStatus, at: new Date().toISOString() },
    ];
    const updated = await this.prisma.taxiTrip.update({
      where: { id },
      data: {
        status: 'ARRIVED',
        waitStartedAt: new Date(), // kutish avtomatik boshlanadi
        waitAccumSec: 0,
        statusHistory: history as unknown as Prisma.InputJsonValue,
      },
    });
    return this.toTrip(updated as Row);
  }

  async setWaiting(
    id: string,
    startedAt: Date | null,
    accumSec: number,
  ): Promise<TaxiTrip> {
    const updated = await this.prisma.taxiTrip.update({
      where: { id },
      data: { waitStartedAt: startedAt, waitAccumSec: accumSec },
    });
    return this.toTrip(updated as Row);
  }

  async beginTrip(id: string, accumSec: number): Promise<TaxiTrip> {
    const existing = await this.prisma.taxiTrip.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Safar topilmadi');
    const history = [
      ...((existing.statusHistory as unknown as TaxiStatusEntry[]) ?? []),
      { status: 'IN_PROGRESS' as TaxiStatus, at: new Date().toISOString() },
    ];
    const updated = await this.prisma.taxiTrip.update({
      where: { id },
      data: {
        status: 'IN_PROGRESS',
        waitAccumSec: accumSec,
        waitStartedAt: null, // yo'lovchi olindi — kutish to'xtaydi
        // GPS masofa hisoblagichi shu yerdan 0'dan boshlanadi (increment NULL
        // ustida ishlamaydi).
        actualDistanceKm: 0,
        statusHistory: history as unknown as Prisma.InputJsonValue,
      },
    });
    return this.toTrip(updated as Row);
  }

  async releaseToPending(id: string, reason?: string, note?: string): Promise<TaxiTrip> {
    const existing = await this.prisma.taxiTrip.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Safar topilmadi');
    const history = [
      ...((existing.statusHistory as unknown as TaxiStatusEntry[]) ?? []),
      {
        status: 'PENDING' as TaxiStatus,
        at: new Date().toISOString(),
        by: 'driver' as const,
        ...(existing.driverId ? { driverId: existing.driverId } : {}),
        ...(reason ? { reason: note ? `${reason}: ${note}` : reason } : {}),
      },
    ];
    const updated = await this.prisma.taxiTrip.update({
      where: { id },
      data: {
        driverId: null,
        status: 'PENDING',
        waitStartedAt: null,
        waitAccumSec: 0,
        // olib ketish ustamasi keyingi haydovchiga qayta hisoblanadi
        pickupDistanceKm: 0,
        pickupSurcharge: 0,
        statusHistory: history as unknown as Prisma.InputJsonValue,
      },
    });
    return this.toTrip(updated as Row);
  }

  async updateStatus(
    id: string,
    status: TaxiStatus,
    meta?: UpdateStatusMeta,
  ): Promise<TaxiTrip> {
    const existing = await this.prisma.taxiTrip.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Safar topilmadi');
    const entry: TaxiStatusEntry = { status, at: new Date().toISOString() };
    if (meta?.by) entry.by = meta.by;
    if (meta?.driverId) entry.driverId = meta.driverId;
    if (meta?.reason) entry.reason = meta.reason;
    const history = [
      ...((existing.statusHistory as unknown as TaxiStatusEntry[]) ?? []),
      entry,
    ];
    const updated = await this.prisma.taxiTrip.update({
      where: { id },
      data: {
        status,
        statusHistory: history as unknown as Prisma.InputJsonValue,
      },
    });
    return this.toTrip(updated as Row);
  }

  async finalize(id: string, data: FinalizeTaxiTrip): Promise<TaxiTrip> {
    const existing = await this.prisma.taxiTrip.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Safar topilmadi');
    const history = [
      ...((existing.statusHistory as unknown as TaxiStatusEntry[]) ?? []),
      { status: 'COMPLETED' as TaxiStatus, at: new Date().toISOString() },
    ];
    const updated = await this.prisma.taxiTrip.update({
      where: { id },
      data: {
        status: 'COMPLETED',
        distanceKm: data.distanceKm,
        waitMinutes: data.waitMinutes,
        pickupSurcharge: data.pickupSurcharge,
        fare: data.fare,
        commission: data.commission,
        driverEarning: data.driverEarning,
        waitStartedAt: null,
        statusHistory: history as unknown as Prisma.InputJsonValue,
      },
    });
    return this.toTrip(updated as Row);
  }

  async setRating(
    id: string,
    rating: number,
    comment?: string,
  ): Promise<TaxiTrip> {
    const updated = await this.prisma.taxiTrip.update({
      where: { id },
      data: { rating, ratingComment: comment ?? null },
    });
    return this.toTrip(updated as Row);
  }

  async driverRatingStats(
    driverId: string,
  ): Promise<{ avg: number; count: number }> {
    const agg = await this.prisma.taxiTrip.aggregate({
      where: { driverId, rating: { not: null } },
      _avg: { rating: true },
      _count: { rating: true },
    });
    const avg = agg._avg.rating ?? 0;
    return { avg: Math.round(avg * 10) / 10, count: agg._count.rating };
  }

  private toTrip(t: Row): TaxiTrip {
    return {
      id: t.id as string,
      publicNo: t.publicNo as number,
      customerId: t.customerId as string,
      driverId: (t.driverId as string) ?? undefined,
      pickup: t.pickup as unknown as GeoPoint,
      destination: (t.destination as unknown as GeoPoint) ?? undefined,
      metered: (t.metered as boolean) ?? false,
      tariffClass:
          ((t.tariffClass as string) === 'comfort' ? 'comfort' : 'start'),
      distanceKm: (t.distanceKm as number) ?? 0,
      actualDistanceKm: (t.actualDistanceKm as number | null) ?? undefined,
      waitMinutes: (t.waitMinutes as number) ?? 0,
      waitStartedAt: (t.waitStartedAt as Date | null)?.toISOString() ?? null,
      waitAccumSec: (t.waitAccumSec as number) ?? 0,
      pickupDistanceKm: (t.pickupDistanceKm as number) ?? 0,
      pickupSurcharge: (t.pickupSurcharge as number) ?? 0,
      fare: t.fare as number,
      commission: (t.commission as number) ?? 0,
      driverEarning: (t.driverEarning as number) ?? 0,
      status: t.status as TaxiStatus,
      paymentType: 'CASH',
      statusHistory: t.statusHistory as unknown as TaxiStatusEntry[],
      rating: (t.rating as number) ?? undefined,
      ratingComment: (t.ratingComment as string) ?? undefined,
      createdAt: (t.createdAt as Date).toISOString(),
      updatedAt: (t.updatedAt as Date).toISOString(),
    };
  }
}
