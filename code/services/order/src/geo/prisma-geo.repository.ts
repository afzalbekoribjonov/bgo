import { Injectable } from '@nestjs/common';
import { Prisma } from '../../prisma/generated/client';
import { PolygonCoords } from '../common/polygon';
import { PrismaService } from '../prisma/prisma.service';
import {
  MapRoad,
  NewMapRoad,
  NewPlace,
  NewServiceArea,
  Place,
  RoadKind,
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

  async listRoads(activeOnly: boolean): Promise<MapRoad[]> {
    const rows = await this.prisma.mapRoad.findMany({
      where: activeOnly ? { area: { isActive: true } } : undefined,
      orderBy: { createdAt: 'asc' },
    });
    return rows.map((r) => this.toRoad(r as Row));
  }

  async createRoad(data: NewMapRoad): Promise<MapRoad> {
    const r = await this.prisma.mapRoad.create({
      data: {
        areaId: data.areaId,
        name: data.name,
        kind: data.kind,
        points: data.points as unknown as Prisma.InputJsonValue,
      },
    });
    return this.toRoad(r as Row);
  }

  async deleteRoad(id: string): Promise<void> {
    await this.prisma.mapRoad.delete({ where: { id } });
  }

  roadCount(): Promise<number> {
    return this.prisma.mapRoad.count();
  }

  async deleteAllRoads(): Promise<void> {
    await this.prisma.mapRoad.deleteMany({});
  }

  async createManyRoads(data: NewMapRoad[]): Promise<number> {
    if (data.length === 0) return 0;
    const res = await this.prisma.mapRoad.createMany({
      data: data.map((d) => ({
        areaId: d.areaId,
        name: d.name,
        kind: d.kind,
        points: d.points as unknown as Prisma.InputJsonValue,
      })),
    });
    return res.count;
  }

  private toRoad(r: Row): MapRoad {
    return {
      id: r.id as string,
      areaId: r.areaId as string,
      name: r.name as string,
      kind: (r.kind as RoadKind) ?? 'street',
      points: r.points as unknown as number[][],
    };
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
