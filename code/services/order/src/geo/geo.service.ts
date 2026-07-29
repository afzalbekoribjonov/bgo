import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { pointInPolygon } from '../common/polygon';
import {
  CreateAreaDto,
  CreateMarkerDto,
  CreatePlaceDto,
  CreateRoadDto,
  UpdateAreaDto,
  UpdateRoadDto,
} from './dto/geo.dto';
import {
  MapMarker,
  MapRoad,
  NewMapRoad,
  RoadKind,
  ServiceAreaWithPlaces,
} from './entities';
import { GeoRepository } from './geo.repository';

/** Overpass API javobidagi yo'l (way) elementi. */
interface OverpassWay {
  type: string;
  geometry?: Array<{ lat: number; lon: number }>;
  tags?: { highway?: string; name?: string; ref?: string };
}

/** Overpass API javobidagi nuqta (node) elementi — nomli joy. */
interface OverpassNode {
  type: string;
  lat?: number;
  lon?: number;
  tags?: { name?: string; place?: string };
}

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

  async updateRoad(id: string, dto: UpdateRoadDto) {
    return this.repo.updateRoad(id, dto);
  }

  deleteRoad(id: string) {
    return this.repo.deleteRoad(id);
  }

  // ---------- Belgilar (markers) ----------

  listMarkers(areaId?: string): Promise<MapMarker[]> {
    return this.repo.listMarkers(areaId);
  }

  async addMarker(areaId: string, dto: CreateMarkerDto) {
    await this.requireArea(areaId);
    return this.repo.createMarker({ areaId, ...dto });
  }

  deleteMarker(id: string) {
    return this.repo.deleteMarker(id);
  }

  /**
   * Beshariq tumanidagi BARCHA haydaladigan yo'llarni OpenStreetMap (Overpass)
   * dan import qiladi — har bir ko'cha yashil chiziq sifatida saqlanadi.
   * Mavjud yo'llar almashtiriladi. Admin keyin qo'shimcha tahrirlashi mumkin.
   */
  async importOsmRoads(): Promise<{ imported: number }> {
    const areas = await this.repo.listAreas(false);
    if (areas.length === 0) {
      throw new BadRequestException('Avval xizmat hududi yarating');
    }
    const areaId = areas[0].id;
    // Beshariq bbox: south,west,north,east
    const bbox = '40.36,70.52,40.52,70.74';
    // Haqiqiy ko'chalar (mahalla yo'llari kiradi); driveway/parking (service),
    // noaniq (road) chiqarib tashlanadi — xarita yengilroq va aniqroq.
    const types =
      'motorway|trunk|primary|secondary|tertiary|unclassified|residential|living_street';
    const query =
      `[out:json][timeout:90];way["highway"~"^(${types})$"](${bbox});out geom;`;

    const res = await fetch('https://overpass-api.de/api/interpreter', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        Accept: 'application/json',
        'User-Agent': 'BeshariqSuperApp/1.0 (orifjonov0916@gmail.com)',
      },
      body: 'data=' + encodeURIComponent(query),
    });
    if (!res.ok) {
      throw new BadRequestException(`Overpass xatosi: ${res.status}`);
    }
    const json = (await res.json()) as { elements?: OverpassWay[] };
    const elements = json.elements ?? [];

    const roads: NewMapRoad[] = [];
    for (const el of elements) {
      if (el.type !== 'way' || !Array.isArray(el.geometry)) continue;
      const pts = el.geometry
        .filter((g) => typeof g.lat === 'number' && typeof g.lon === 'number')
        .map((g) => [g.lat, g.lon]);
      if (pts.length < 2) continue;
      const hw = el.tags?.highway ?? '';
      const kind: RoadKind = ['motorway', 'trunk', 'primary'].includes(hw)
        ? 'center'
        : ['secondary', 'tertiary'].includes(hw)
          ? 'main'
          : 'street';
      const name = el.tags?.name || el.tags?.ref || "Ko'cha";
      roads.push({ areaId, name, kind, points: pts });
    }

    await this.repo.deleteAllRoads();
    const imported = await this.repo.createManyRoads(roads);
    this.logger.log(`OSM yo'llari import qilindi: ${imported}`);
    return { imported };
  }

  /**
   * Beshariq tumanidagi nomli joylarni (qishloq/mahalla/shaharcha...) OSM'dan
   * import qiladi — xaritada ko'proq nom ko'rinadi. Yo'llardan farqli o'laroq,
   * joylar admin tomonidan ham qo'shiladi: shuning uchun BARCHASINI O'CHIRMAYMIZ,
   * faqat nomi bo'yicha hali yo'q joylarni qo'shamiz (dublikatsiz, idempotent).
   */
  async importOsmPlaces(): Promise<{ imported: number; skipped: number }> {
    const areas = await this.repo.listAreas(false);
    if (areas.length === 0) {
      throw new BadRequestException('Avval xizmat hududi yarating');
    }
    const areaId = areas[0].id;

    // Mavjud joy nomlari (admin/seed) — dublikatdan saqlanish uchun.
    const existing = new Set<string>();
    for (const a of areas) {
      for (const p of a.places ?? []) {
        existing.add(p.label.trim().toLowerCase());
      }
    }

    const bbox = '40.36,70.52,40.52,70.74';
    const types = 'city|town|village|hamlet|suburb|neighbourhood|quarter|locality';
    const query =
      `[out:json][timeout:90];node["place"~"^(${types})$"]["name"](${bbox});out;`;

    const res = await fetch('https://overpass-api.de/api/interpreter', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        Accept: 'application/json',
        'User-Agent': 'BeshariqSuperApp/1.0 (orifjonov0916@gmail.com)',
      },
      body: 'data=' + encodeURIComponent(query),
    });
    if (!res.ok) {
      throw new BadRequestException(`Overpass xatosi: ${res.status}`);
    }
    const json = (await res.json()) as { elements?: OverpassNode[] };
    const elements = json.elements ?? [];

    // Yangi joylar admin/seed dan keyin tursin (sortOrder katta).
    let order = 1000;
    let imported = 0;
    let skipped = 0;
    for (const el of elements) {
      if (
        el.type !== 'node' ||
        typeof el.lat !== 'number' ||
        typeof el.lon !== 'number'
      ) {
        continue;
      }
      const name = el.tags?.name?.trim();
      if (!name) continue;
      if (existing.has(name.toLowerCase())) {
        skipped++;
        continue;
      }
      const place = el.tags?.place ?? '';
      // Mahalla-tipidagilar 'mahalla', yirikroq aholi punktlari 'landmark'.
      const category = ['suburb', 'neighbourhood', 'quarter', 'hamlet'].includes(
        place,
      )
        ? 'mahalla'
        : 'landmark';
      await this.repo.createPlace({
        areaId,
        label: name,
        lat: el.lat,
        lng: el.lon,
        category,
        sortOrder: order++,
      });
      existing.add(name.toLowerCase());
      imported++;
    }

    this.logger.log(
      `OSM joylari import qilindi: ${imported} (o'tkazib yuborildi: ${skipped})`,
    );
    return { imported, skipped };
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
