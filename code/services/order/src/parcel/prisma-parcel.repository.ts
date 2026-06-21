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
import { ParcelRepository } from './parcel.repository';

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

  async updateStatus(id: string, status: ParcelStatus): Promise<ParcelDelivery> {
    const existing = await this.prisma.parcelDelivery.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Dostavka topilmadi');
    const history = [
      ...((existing.statusHistory as unknown as ParcelStatusEntry[]) ?? []),
      { status, at: new Date().toISOString() },
    ];
    const updated = await this.prisma.parcelDelivery.update({
      where: { id },
      data: {
        status,
        statusHistory: history as unknown as Prisma.InputJsonValue,
      },
    });
    return this.toParcel(updated as Row);
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
      createdAt: (p.createdAt as Date).toISOString(),
    };
  }
}
