import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '../../prisma/generated/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  FinalizeTaxiTrip,
  GeoPoint,
  NewTaxiTrip,
  TaxiStatus,
  TaxiStatusEntry,
  TaxiTrip,
} from './entities';
import { TaxiRepository } from './taxi.repository';

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

  async findAvailable(): Promise<TaxiTrip[]> {
    const rows = await this.prisma.taxiTrip.findMany({
      where: { status: 'PENDING', driverId: null },
      orderBy: { createdAt: 'asc' },
    });
    return rows.map((t) => this.toTrip(t as Row));
  }

  async assignDriver(id: string, driverId: string): Promise<TaxiTrip> {
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
      },
    });
    return this.toTrip(updated as Row);
  }

  async updateStatus(id: string, status: TaxiStatus): Promise<TaxiTrip> {
    const existing = await this.prisma.taxiTrip.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Safar topilmadi');
    const history = [
      ...((existing.statusHistory as unknown as TaxiStatusEntry[]) ?? []),
      { status, at: new Date().toISOString() },
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
        fare: data.fare,
        commission: data.commission,
        driverEarning: data.driverEarning,
        statusHistory: history as unknown as Prisma.InputJsonValue,
      },
    });
    return this.toTrip(updated as Row);
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
      distanceKm: (t.distanceKm as number) ?? 0,
      waitMinutes: (t.waitMinutes as number) ?? 0,
      fare: t.fare as number,
      commission: (t.commission as number) ?? 0,
      driverEarning: (t.driverEarning as number) ?? 0,
      status: t.status as TaxiStatus,
      paymentType: 'CASH',
      statusHistory: t.statusHistory as unknown as TaxiStatusEntry[],
      createdAt: (t.createdAt as Date).toISOString(),
    };
  }
}
