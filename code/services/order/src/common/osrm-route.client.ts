import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GeoPoint } from './geo';

const ROUTE_TIMEOUT_MS = 5000;

/** Marshrut hisoblash uchun yetarli minimal nuqta (GeoPoint'ning `text`isiz). */
export interface RoutePoint {
  lat: number;
  lng: number;
}

/**
 * Bitta burilish (maneuver) — OSRM `steps` ma'lumotidan. Haydovchi ilovasi
 * shu asosda "200 metrdan so'ng o'ngga" kabi ogohlantirish beradi.
 */
export interface RouteStepDto {
  /** OSRM maneuver.type: depart|turn|new name|merge|fork|end of road|continue|roundabout|arrive... */
  type: string;
  /** OSRM maneuver.modifier: left|right|slight left|sharp right|straight|uturn... (bo'lmasligi mumkin) */
  modifier: string | null;
  /** SHU qadam uzunligi — ya'ni burilishgacha bosib o'tiladigan masofa. */
  distanceMeters: number;
  durationSeconds: number;
  /** Burilish nuqtasi [lat, lng]. */
  location: [number, number];
  streetName: string | null;
  /** Aylanma yo'ldan chiqish raqami (bo'lmasa null). */
  exit: number | null;
}

/** To'liq marshrut — geometriya + burilishlar ro'yxati. */
export interface RouteWithStepsDto {
  /** [lat, lng] juftliklari (overview=full). */
  points: [number, number][];
  distanceMeters: number;
  durationSeconds: number;
  steps: RouteStepDto[];
}

/** OSRM javobining bizga kerakli qismi (xom JSON shakli). */
interface OsrmStepJson {
  distance?: number;
  duration?: number;
  name?: string;
  maneuver?: {
    type?: string;
    modifier?: string;
    location?: number[];
    exit?: number;
  };
}

/**
 * "Uyga" rejimi uchun OSRM marshrut-masofa yordamchisi. Faqat home-mode
 * faol VA dispatch radiusidagi haydovchilar uchun chaqiriladi (odatda
 * 0-3 kishi bir vaqtda) — xarajat xavfi yo'q. Har qanday xato/timeoutda
 * `null` qaytaradi, dispatch TO'XTAMASDAN oddiy tartibda davom etadi.
 */
@Injectable()
export class OsrmRouteClient {
  private readonly logger = new Logger(OsrmRouteClient.name);
  private readonly osrmUrl: string;

  constructor(config: ConfigService) {
    this.osrmUrl = (
      config.get<string>('OSRM_URL') ?? 'http://localhost:5000'
    ).replace(/\/+$/, '');
  }

  /**
   * "Uyga" mosligi: haydovchi -> [buyurtma nuqtalari] -> uy yo'li (BITTA
   * ko'p-nuqtali OSRM chaqiruvida), haydovchi -> uy to'g'ridan-to'g'ri
   * yo'li bilan solishtiriladi. Natija — chetlanish foizi (0 = aynan yo'lda,
   * katta son = uydan uzoqlashtiruvchi). Hisoblab bo'lmasa — `null`.
   */
  async detourPercent(
    driver: GeoPoint,
    waypoints: GeoPoint[],
    home: GeoPoint,
  ): Promise<number | null> {
    if (waypoints.length === 0) return null;
    try {
      const [viaMeters, directMeters] = await Promise.all([
        this.routeDistanceMeters([driver, ...waypoints, home]),
        this.routeDistanceMeters([driver, home]),
      ]);
      if (viaMeters == null || directMeters == null || directMeters <= 0) {
        return null;
      }
      return ((viaMeters - directMeters) / directMeters) * 100;
    } catch (e) {
      this.logger.debug(
        `Uyga rejimi marshrut hisoblash o'tkazib yuborildi: ${(e as Error).message}`,
      );
      return null;
    }
  }

  /**
   * Haydovchi navigatsiyasi uchun to'liq marshrut: geometriya + burilishlar
   * (`steps=true`). O'ZIMIZNING self-hosted OSRM'dan olinadi (ilova ochiq
   * demo-serverga chiqmasin). Har qanday xato/timeoutda `null` — chaqiruvchi
   * (driver_app) mavjud "to'g'ri chiziq" zaxirasiga tushadi.
   */
  async routeWithSteps(
    from: RoutePoint,
    to: RoutePoint,
  ): Promise<RouteWithStepsDto | null> {
    try {
      const coords = `${from.lng},${from.lat};${to.lng},${to.lat}`;
      const res = await fetch(
        `${this.osrmUrl}/route/v1/driving/${coords}` +
          `?overview=full&geometries=geojson&steps=true`,
        { signal: AbortSignal.timeout(ROUTE_TIMEOUT_MS) },
      );
      if (!res.ok) return null;
      const json = (await res.json()) as {
        code: string;
        routes?: {
          distance?: number;
          duration?: number;
          geometry?: { coordinates?: number[][] };
          legs?: { steps?: OsrmStepJson[] }[];
        }[];
      };
      if (json.code !== 'Ok' || !json.routes?.length) return null;
      const route = json.routes[0];
      // OSRM [lng, lat] beradi — ilova [lat, lng] kutadi.
      const points: [number, number][] = (route.geometry?.coordinates ?? [])
        .filter((c) => c.length >= 2)
        .map((c) => [c[1], c[0]] as [number, number]);
      if (points.length < 2) return null;
      const steps: RouteStepDto[] = (route.legs ?? []).flatMap((leg) =>
        (leg.steps ?? []).map((s) => ({
          type: s.maneuver?.type ?? 'turn',
          modifier: s.maneuver?.modifier ?? null,
          distanceMeters: s.distance ?? 0,
          durationSeconds: s.duration ?? 0,
          location: [
            s.maneuver?.location?.[1] ?? 0,
            s.maneuver?.location?.[0] ?? 0,
          ] as [number, number],
          streetName: s.name?.trim() ? s.name : null,
          exit: s.maneuver?.exit ?? null,
        })),
      );
      return {
        points,
        distanceMeters: route.distance ?? 0,
        durationSeconds: route.duration ?? 0,
        steps,
      };
    } catch (e) {
      this.logger.debug(
        `Marshrut (steps) olinmadi: ${(e as Error).message}`,
      );
      return null;
    }
  }

  private async routeDistanceMeters(points: GeoPoint[]): Promise<number | null> {
    const coords = points.map((p) => `${p.lng},${p.lat}`).join(';');
    const res = await fetch(
      `${this.osrmUrl}/route/v1/driving/${coords}?overview=false`,
      { signal: AbortSignal.timeout(ROUTE_TIMEOUT_MS) },
    );
    if (!res.ok) return null;
    const json = (await res.json()) as {
      code: string;
      routes?: { distance: number }[];
    };
    if (json.code !== 'Ok' || !json.routes?.length) return null;
    return json.routes[0].distance;
  }
}
