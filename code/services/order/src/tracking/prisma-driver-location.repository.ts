import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { DriverLocation, NewDriverLocation } from './entities';
import { DriverLocationRepository } from './driver-location.repository';

type Row = Record<string, unknown>;

/** PostgreSQL (order_db) implementatsiyasi. */
@Injectable()
export class PrismaDriverLocationRepository extends DriverLocationRepository {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async upsert(
    driverId: string,
    data: NewDriverLocation,
  ): Promise<DriverLocation> {
    const row = await this.prisma.driverLocation.upsert({
      where: { driverId },
      create: {
        driverId,
        lat: data.lat,
        lng: data.lng,
        heading: data.heading ?? null,
      },
      update: {
        lat: data.lat,
        lng: data.lng,
        heading: data.heading ?? null,
      },
    });
    return this.toLocation(row as Row);
  }

  async find(driverId: string): Promise<DriverLocation | null> {
    const row = await this.prisma.driverLocation.findUnique({
      where: { driverId },
    });
    return row ? this.toLocation(row as Row) : null;
  }

  async remove(driverId: string): Promise<void> {
    await this.prisma.driverLocation
      .delete({ where: { driverId } })
      .catch(() => undefined);
  }

  async listSince(since: Date): Promise<DriverLocation[]> {
    const rows = await this.prisma.driverLocation.findMany({
      where: { updatedAt: { gte: since } },
    });
    return rows.map((r) => this.toLocation(r as Row));
  }

  private toLocation(r: Row): DriverLocation {
    return {
      driverId: r.driverId as string,
      lat: r.lat as number,
      lng: r.lng as number,
      heading: (r.heading as number) ?? undefined,
      updatedAt: (r.updatedAt as Date).toISOString(),
    };
  }
}
