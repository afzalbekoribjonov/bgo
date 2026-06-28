import { Injectable } from '@nestjs/common';
import { haversineKm } from '../common/geo';
import { DriverLocationRepository } from './driver-location.repository';
import { DriverLocation, NearbyDriver, NewDriverLocation } from './entities';

/** Haydovchini "online" deb hisoblash oynasi (soniya). */
const ONLINE_MAX_AGE_SEC = 120;
/** "Yaqin mashinalar" qidiruv radiusi (km) va soni. */
const NEARBY_RADIUS_KM = 6;
const NEARBY_LIMIT = 12;

/**
 * Haydovchi/kuryerning jonli joylashuvi — taksi/dostavka kuzatuvi va
 * "yaqin mashinalar" uchun. plan/12-maps-navigation.md
 */
@Injectable()
export class DriverLocationService {
  constructor(private readonly repo: DriverLocationRepository) {}

  /** Haydovchi joylashuvini yangilaydi. */
  ping(driverId: string, dto: NewDriverLocation): Promise<DriverLocation> {
    return this.repo.upsert(driverId, dto);
  }

  /** Haydovchining oxirgi joylashuvi (offline bo'lsa null bo'lishi mumkin). */
  get(driverId: string): Promise<DriverLocation | null> {
    return this.repo.find(driverId);
  }

  /** Haydovchi offline bo'ldi (joylashuvni o'chiradi). */
  goOffline(driverId: string): Promise<void> {
    return this.repo.remove(driverId);
  }

  /**
   * Nuqtaga eng yaqin online haydovchi id'lari (masofa bo'yicha; exclude tashqari).
   * Dispatch (buyurtmani eng yaqin haydovchiga taklif qilish) uchun.
   */
  async nearestDriverIds(
    lat: number,
    lng: number,
    exclude: Set<string> = new Set(),
  ): Promise<string[]> {
    const since = new Date(Date.now() - ONLINE_MAX_AGE_SEC * 1000);
    const recent = await this.repo.listSince(since);
    const origin = { text: '', lat, lng };
    return recent
      .filter((d) => !exclude.has(d.driverId))
      .map((d) => ({
        id: d.driverId,
        dist: haversineKm(origin, { text: '', lat: d.lat, lng: d.lng }),
      }))
      .filter((d) => d.dist <= NEARBY_RADIUS_KM)
      .sort((a, b) => a.dist - b.dist)
      .map((d) => d.id);
  }

  /** Nuqta atrofidagi online haydovchilar (anonim), masofa bo'yicha tartiblangan. */
  async nearby(lat: number, lng: number): Promise<NearbyDriver[]> {
    const since = new Date(Date.now() - ONLINE_MAX_AGE_SEC * 1000);
    const now = Date.now();
    const recent = await this.repo.listSince(since);
    const origin = { text: '', lat, lng };
    return recent
      .map((d) => ({
        lat: d.lat,
        lng: d.lng,
        heading: d.heading,
        distanceKm:
          Math.round(haversineKm(origin, { text: '', lat: d.lat, lng: d.lng }) * 100) /
          100,
        ageSeconds: Math.round((now - new Date(d.updatedAt).getTime()) / 1000),
      }))
      .filter((d) => d.distanceKm <= NEARBY_RADIUS_KM)
      .sort((a, b) => a.distanceKm - b.distanceKm)
      .slice(0, NEARBY_LIMIT);
  }
}
