import { Injectable } from '@nestjs/common';
import { Prisma } from '../../prisma/generated/client';
import { PolygonCoords } from '../common/polygon';
import { PrismaService } from '../prisma/prisma.service';
import {
  NewPlace,
  NewServiceArea,
  Place,
  ServiceArea,
  ServiceAreaWithPlaces,
} from './entities';
import { GeoRepository } from './geo.repository';

type Row = Record<string, unknown>;

/** PostgreSQL (order_db) implementatsiyasi. */
@Injectable()
export class PrismaGeoRepository extends GeoRepository {
  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async listAreas(activeOnly: boolean): Promise<ServiceAreaWithPlaces[]> {
    const rows = await this.prisma.serviceArea.findMany({
      where: activeOnly ? { isActive: true } : undefined,
      include: { places: { orderBy: { sortOrder: 'asc' } } },
      orderBy: { createdAt: 'asc' },
    });
    return rows.map((r) => ({
      ...this.toArea(r as Row),
      places: ((r as { places: Row[] }).places ?? []).map((p) => this.toPlace(p)),
    }));
  }

  async findArea(id: string): Promise<ServiceArea | null> {
    const r = await this.prisma.serviceArea.findUnique({ where: { id } });
    return r ? this.toArea(r as Row) : null;
  }

  async createArea(data: NewServiceArea): Promise<ServiceArea> {
    const r = await this.prisma.serviceArea.create({
      data: {
        name: data.name,
        centerLat: data.centerLat,
        centerLng: data.centerLng,
        boundary: data.boundary as unknown as Prisma.InputJsonValue,
        isActive: data.isActive ?? true,
      },
    });
    return this.toArea(r as Row);
  }

  async updateArea(
    id: string,
    patch: Partial<NewServiceArea>,
  ): Promise<ServiceArea> {
    const r = await this.prisma.serviceArea.update({
      where: { id },
      data: {
        ...(patch.name !== undefined ? { name: patch.name } : {}),
        ...(patch.centerLat !== undefined ? { centerLat: patch.centerLat } : {}),
        ...(patch.centerLng !== undefined ? { centerLng: patch.centerLng } : {}),
        ...(patch.boundary !== undefined
          ? { boundary: patch.boundary as unknown as Prisma.InputJsonValue }
          : {}),
        ...(patch.isActive !== undefined ? { isActive: patch.isActive } : {}),
      },
    });
    return this.toArea(r as Row);
  }

  async deleteArea(id: string): Promise<void> {
    await this.prisma.serviceArea.delete({ where: { id } });
  }

  async listPlaces(areaId: string): Promise<Place[]> {
    const rows = await this.prisma.place.findMany({
      where: { areaId },
      orderBy: { sortOrder: 'asc' },
    });
    return rows.map((p) => this.toPlace(p as Row));
  }

  async createPlace(data: NewPlace): Promise<Place> {
    const p = await this.prisma.place.create({
      data: {
        areaId: data.areaId,
        label: data.label,
        lat: data.lat,
        lng: data.lng,
        category: data.category,
        sortOrder: data.sortOrder ?? 0,
      },
    });
    return this.toPlace(p as Row);
  }

  async deletePlace(id: string): Promise<void> {
    await this.prisma.place.delete({ where: { id } });
  }

  areaCount(): Promise<number> {
    return this.prisma.serviceArea.count();
  }

  private toArea(r: Row): ServiceArea {
    return {
      id: r.id as string,
      name: r.name as string,
      centerLat: r.centerLat as number,
      centerLng: r.centerLng as number,
      boundary: r.boundary as unknown as PolygonCoords,
      isActive: r.isActive as boolean,
    };
  }

  private toPlace(p: Row): Place {
    return {
      id: p.id as string,
      areaId: p.areaId as string,
      label: p.label as string,
      lat: p.lat as number,
      lng: p.lng as number,
      category: (p.category as string) ?? undefined,
      sortOrder: (p.sortOrder as number) ?? 0,
    };
  }
}
