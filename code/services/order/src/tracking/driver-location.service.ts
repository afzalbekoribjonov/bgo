import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { haversineKm } from '../common/geo';
import { DriverLocationRepository } from './driver-location.repository';
import { DriverLocation, NearbyDriver, NewDriverLocation } from './entities';
import { TripDistanceTracker } from './trip-distance-tracker.service';

/**
 * Ping'lar orasidagi masofani haqiqiy safar deb hisoblash chegaralari —
 * GPS jitter (juda kichik) va sakrash/uzilish (juda katta, masalan ilova
 * fonda uzoq vaqt yopiq bo'lgach qayta ulanganda) hisobga qo'shilmaydi.
 */
const MIN_PLAUSIBLE_DELTA_KM = 0.003; // ~3 metr
const MAX_PLAUSIBLE_DELTA_KM = 2; // bir ping oralig'ida 2km'dan ko'p — shubhali sakrash

/**
 * GPS shovqinini bosish (yumshatish): telefon GPS'i bir joyda tursa ham
 * ping'lar orasida bir necha metr chayqaladi — bu saqlangan/translatsiya
 * qilinadigan nuqtada ko'rinib, xaritadagi mashina belgisi asossiz
 * "qimirlab" ketishiga sabab bo'ladi. Kichik siljish (shovqinga o'xshash)
 * bo'lsa yangi nuqtaga ozgina, katta siljish (haqiqiy harakat) bo'lsa
 * deyarli to'liq tortiladi — shu bilan haqiqiy harakat kechikmaydi.
 */
const JITTER_DAMP_KM = 0.008; // ~8 metr — bundan kichik siljish ko'proq shovqin
const JITTER_WEIGHT = 0.3; // shovqin holatida yangi nuqtaga tortilish ulushi
const MOVE_WEIGHT = 0.9; // haqiqiy harakatda yangi nuqtaga tortilish ulushi

/**
 * Yo'lga yopishtirish (map-matching, OSRM /nearest): shovqin bosilgan nuqta
 * eng yaqin yo'l segmentiga tortiladi — mashina xaritada haqiqatda yo'lda
 * turadi, dala/hovli/binolar ustida "muallaq" ko'rinmaydi. Yopishtirilgan
 * nuqta manba nuqtadan juda uzoq (haydovchi haqiqatan yo'ldan tashqarida —
 * hovli, bozor, avtoturargoh) bo'lsa yopishtirilmaydi (noto'g'ri yo'lga
 * tortib qo'ymasin).
 */
const SNAP_MAX_DISTANCE_M = 60;
const SNAP_TIMEOUT_MS = 1200;

/** Haydovchini "online" deb hisoblash oynasi (soniya). */
const ONLINE_MAX_AGE_SEC = 120;
/** "Yaqin mashinalar" qidiruv radiusi (km) va soni (xaritada ko'rsatish uchun). */
const NEARBY_RADIUS_KM = 6;
const NEARBY_LIMIT = 12;
/**
 * Dispatch radiusi (km) — buyurtmani eng yaqin haydovchiga taklif qilishda.
 * Yaqinda mashina bo'lmasa 7-8km, hatto undan uzoqdagi haydovchiga ham
 * taklif qilinadi (tuman bo'ylab eng yaqini).
 */
const DISPATCH_RADIUS_KM = 25;

/**
 * Haydovchi/kuryerning jonli joylashuvi — taksi/dostavka kuzatuvi va
 * "yaqin mashinalar" uchun. plan/12-maps-navigation.md
 */
@Injectable()
export class DriverLocationService {
  private readonly logger = new Logger(DriverLocationService.name);
  private readonly osrmUrl: string;

  constructor(
    private readonly repo: DriverLocationRepository,
    private readonly distanceTracker: TripDistanceTracker,
    config: ConfigService,
  ) {
    this.osrmUrl = (
      config.get<string>('OSRM_URL') ?? 'http://localhost:5000'
    ).replace(/\/+$/, '');
  }

  /**
   * Haydovchi joylashuvini yangilaydi. Oldingi nuqtadan farqni (mantiqiy
   * chegarada) faol safarning haqiqiy bosib o'tilgan masofasiga qo'shadi
   * (narxga ta'sir qilmaydi — faqat ko'rsatish uchun).
   */
  async ping(driverId: string, dto: NewDriverLocation): Promise<DriverLocation> {
    const prev = await this.repo.find(driverId);
    let toStore = dto;
    if (prev) {
      const deltaKm = haversineKm(
        { text: '', lat: prev.lat, lng: prev.lng },
        { text: '', lat: dto.lat, lng: dto.lng },
      );
      // Shubhali sakrash (uzoq vaqt uzilib qayta ulanish) bo'lmasa — yumshatish.
      if (deltaKm <= MAX_PLAUSIBLE_DELTA_KM) {
        const w = deltaKm < JITTER_DAMP_KM ? JITTER_WEIGHT : MOVE_WEIGHT;
        toStore = {
          ...dto,
          lat: prev.lat + (dto.lat - prev.lat) * w,
          lng: prev.lng + (dto.lng - prev.lng) * w,
        };
      }
      // Masofa hisobini HAQIQIY (yumshatilmagan) GPS siljishidan olamiz —
      // safar masofasi aniqligi ko'rinishga bog'liq bo'lmasin.
      if (deltaKm >= MIN_PLAUSIBLE_DELTA_KM && deltaKm <= MAX_PLAUSIBLE_DELTA_KM) {
        this.distanceTracker.accumulate(driverId, deltaKm).catch(() => undefined);
      }
    }
    const snapped = await this.snapToRoad(toStore);
    return this.repo.upsert(driverId, snapped);
  }

  /**
   * OSRM /nearest orqali eng yaqin yo'l nuqtasiga yopishtiradi. OSRM
   * ishlamasa, javob bermasa yoki nuqta yo'ldan judayam uzoq bo'lsa —
   * xatosiz, o'zgarishsiz nuqtani qaytaradi (best-effort, translatsiyani
   * to'xtatib qo'ymaydi).
   */
  private async snapToRoad(loc: NewDriverLocation): Promise<NewDriverLocation> {
    try {
      const res = await fetch(
        `${this.osrmUrl}/nearest/v1/driving/${loc.lng},${loc.lat}`,
        { signal: AbortSignal.timeout(SNAP_TIMEOUT_MS) },
      );
      if (!res.ok) return loc;
      const json = (await res.json()) as {
        code: string;
        waypoints?: { location: [number, number]; distance: number }[];
      };
      const wp = json.waypoints?.[0];
      // OSRM waypoints[].distance metrda (km emas).
      if (json.code !== 'Ok' || !wp || wp.distance > SNAP_MAX_DISTANCE_M) {
        return loc;
      }
      return { ...loc, lat: wp.location[1], lng: wp.location[0] };
    } catch (e) {
      this.logger.debug(`Yo'lga yopishtirish o'tkazib yuborildi: ${(e as Error).message}`);
      return loc;
    }
  }

  /** Haydovchining oxirgi joylashuvi (offline bo'lsa null bo'lishi mumkin). */
  get(driverId: string): Promise<DriverLocation | null> {
    return this.repo.find(driverId);
  }

  /** Haydovchi offline bo'ldi (joylashuvni o'chiradi). */
  goOffline(driverId: string): Promise<void> {
    return this.repo.remove(driverId);
  }

  /** Barcha online haydovchilar (admin jonli xaritasi uchun). */
  async listOnline(): Promise<DriverLocation[]> {
    const since = new Date(Date.now() - ONLINE_MAX_AGE_SEC * 1000);
    return this.repo.listSince(since);
  }

  /**
   * Nuqtaga eng yaqin online haydovchilar (masofa bilan; exclude tashqari),
   * masofa bo'yicha o'sish tartibida. Dispatch (buyurtmani eng yaqin
   * haydovchiga taklif qilish, reyting-tiebreak klasterlash) uchun.
   */
  async nearestDrivers(
    lat: number,
    lng: number,
    exclude: Set<string> = new Set(),
  ): Promise<{ id: string; distanceKm: number }[]> {
    const since = new Date(Date.now() - ONLINE_MAX_AGE_SEC * 1000);
    const recent = await this.repo.listSince(since);
    const origin = { text: '', lat, lng };
    return recent
      .filter((d) => !exclude.has(d.driverId))
      .map((d) => ({
        id: d.driverId,
        distanceKm: haversineKm(origin, { text: '', lat: d.lat, lng: d.lng }),
      }))
      .filter((d) => d.distanceKm <= DISPATCH_RADIUS_KM)
      .sort((a, b) => a.distanceKm - b.distanceKm);
  }

  /** Faqat id'lar (masofa bo'yicha) — {@link nearestDrivers}ning qulay qisqartmasi. */
  async nearestDriverIds(
    lat: number,
    lng: number,
    exclude: Set<string> = new Set(),
  ): Promise<string[]> {
    return (await this.nearestDrivers(lat, lng, exclude)).map((d) => d.id);
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
