import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { pointInPolygon } from '../common/polygon';
import {
  CreateAreaDto,
  CreatePlaceDto,
  CreateRoadDto,
  UpdateAreaDto,
} from './dto/geo.dto';
import { MapRoad, ServiceAreaWithPlaces } from './entities';
import { GeoRepository } from './geo.repository';

/**
 * Xizmat hududlari (tumanlar) + nomli joylar. Admin boshqaradi, kengaytiriladi.
 * plan/12-maps-navigation.md
 */
@Injectable()
export class GeoService {
  private readonly logger = new Logger(GeoService.name);

  constructor(private readonly repo: GeoRepository) {}

  /** Faol hududlar + joylar (ilovalar uchun). */
  listActiveAreas(): Promise<ServiceAreaWithPlaces[]> {
    return this.repo.listAreas(true);
  }

  /** Barcha hududlar (admin). */
  listAllAreas(): Promise<ServiceAreaWithPlaces[]> {
    return this.repo.listAreas(false);
  }

  /** Nuqta biror faol xizmat hududi ichidami. */
  async check(
    lat: number,
    lng: number,
  ): Promise<{ inside: boolean; areaId?: string; areaName?: string }> {
    const areas = await this.repo.listAreas(true);
    for (const area of areas) {
      if (pointInPolygon(lat, lng, area.boundary)) {
        return { inside: true, areaId: area.id, areaName: area.name };
      }
    }
    return { inside: false };
  }

  // ---------- Admin CRUD ----------

  createArea(dto: CreateAreaDto) {
    return this.repo.createArea(dto);
  }

  async updateArea(id: string, dto: UpdateAreaDto) {
    await this.requireArea(id);
    return this.repo.updateArea(id, dto);
  }

  async deleteArea(id: string) {
    await this.requireArea(id);
    await this.repo.deleteArea(id);
  }

  async addPlace(areaId: string, dto: CreatePlaceDto) {
    await this.requireArea(areaId);
    return this.repo.createPlace({ areaId, ...dto });
  }

  deletePlace(id: string) {
    return this.repo.deletePlace(id);
  }

  // ---------- Yo'llar (Beshariq-maxsus xarita qatlami) ----------

  /** Faol hududlardagi yo'llar (ilovalar — rangli overlay uchun). */
  listRoads(): Promise<MapRoad[]> {
    return this.repo.listRoads(true);
  }

  async addRoad(areaId: string, dto: CreateRoadDto) {
    await this.requireArea(areaId);
    return this.repo.createRoad({ areaId, ...dto });
  }

  deleteRoad(id: string) {
    return this.repo.deleteRoad(id);
  }

  private async requireArea(id: string) {
    const area = await this.repo.findArea(id);
    if (!area) throw new NotFoundException('Hudud topilmadi');
    return area;
  }

  /**
   * Boshlang'ich Beshariq hududi + namunaviy joylar (bo'sh bo'lsa). Taxminiy
   * poligon — admin keyin aniq OSM chegarasi bilan almashtiradi.
   */
  async seedIfEmpty(): Promise<void> {
    if ((await this.repo.areaCount()) > 0) return;

    // Beshariq markazi atrofidagi taxminiy poligon (lng, lat juftliklari).
    const boundary: number[][][] = [
      [
        [70.55, 40.36],
        [70.72, 40.36],
        [70.74, 40.45],
        [70.66, 40.52],
        [70.55, 40.5],
        [70.52, 40.43],
        [70.55, 40.36],
      ],
    ];
    const area = await this.repo.createArea({
      name: 'Beshariq tumani',
      centerLat: 40.4236,
      centerLng: 70.6094,
      boundary,
      isActive: true,
    });

    const places: Array<[string, number, number, string]> = [
      ['Markaziy bozor', 40.4236, 70.6094, 'landmark'],
      ['Avtostansiya', 40.4185, 70.6042, 'landmark'],
      ['Tuman kasalxonasi', 40.4291, 70.6158, 'landmark'],
      ['Stadion', 40.4258, 70.6201, 'landmark'],
      ["Temir yo'l bekati", 40.4112, 70.5983, 'landmark'],
      ['Yangiobod mahallasi', 40.436, 70.627, 'mahalla'],
      ['Sanoat zonasi', 40.405, 70.63, 'landmark'],
      ['Universitet', 40.4205, 70.6155, 'landmark'],
    ];
    let order = 0;
    for (const [label, lat, lng, category] of places) {
      await this.repo.createPlace({
        areaId: area.id,
        label,
        lat,
        lng,
        category,
        sortOrder: order++,
      });
    }

    this.logger.log('Beshariq xizmat hududi + joylar yuklandi (seed)');
    await this.seedRoadsIfEmpty();
  }

  /**
   * Namunaviy yo'llar (taxminiy) — yo'llar bo'sh bo'lsa, birinchi hududga.
   * Admin keyin aniq ko'chalarni qo'shadi/o'zgartiradi.
   */
  async seedRoadsIfEmpty(): Promise<void> {
    if ((await this.repo.roadCount()) > 0) return;
    const areas = await this.repo.listAreas(false);
    if (areas.length === 0) return;
    const areaId = areas[0].id;

    const roads: Array<{ name: string; kind: string; points: number[][] }> = [
      {
        name: "Markaziy ko'cha",
        kind: 'center',
        points: [
          [40.4185, 70.6042],
          [40.4236, 70.6094],
          [40.4291, 70.6158],
        ],
      },
      {
        name: "Navoiy ko'chasi",
        kind: 'main',
        points: [
          [40.4236, 70.6094],
          [40.4258, 70.6201],
          [40.436, 70.627],
        ],
      },
      {
        name: "Bekat yo'li",
        kind: 'street',
        points: [
          [40.4112, 70.5983],
          [40.4185, 70.6042],
        ],
      },
      {
        name: "Sanoat yo'li",
        kind: 'street',
        points: [
          [40.4236, 70.6094],
          [40.405, 70.63],
        ],
      },
    ];
    for (const r of roads) {
      await this.repo.createRoad({
        areaId,
        name: r.name,
        kind: r.kind as never,
        points: r.points,
      });
    }
    this.logger.log("Namunaviy yo'llar yuklandi (seed)");
  }
}
