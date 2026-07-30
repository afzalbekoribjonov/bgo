import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GeoPoint } from './geo';

const ROUTE_TIMEOUT_MS = 5000;

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
