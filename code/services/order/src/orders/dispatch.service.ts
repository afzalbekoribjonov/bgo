import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { GeoPoint, haversineKm } from '../common/geo';
import { OsrmRouteClient } from '../common/osrm-route.client';
import { DriverInfoClient } from '../driver-client/driver-info.client';
import { NotificationClient } from '../notification-client/notification.client';
import { TariffService } from '../tariff/tariff.service';
import { DriverLocationService } from '../tracking/driver-location.service';

/** Yangi buyurtma signali — local bildirishnoma kanali (ilova tomonda). */
const OFFER_CHANNEL = 'beshariq_offer';

/** Vertikal -> haydovchiga ko'rinadigan tarif nomi. */
const VERTICAL_LABEL: Record<DispatchVertical, string> = {
  food: 'Ovqat',
  taxi: 'Taksi',
  parcel: 'Dostavka',
  market: 'Market',
};

export type DispatchVertical = 'food' | 'taxi' | 'parcel' | 'market';

/** Buyurtma taklifi (haydovchiga yuboriladigan ma'lumot). */
export interface DispatchOffer {
  orderId: string;
  vertical: DispatchVertical;
  pickupLat: number;
  pickupLng: number;
  pickupName: string;
  dropoffLat?: number | null;
  dropoffLng?: number | null;
  dropoffText?: string | null;
  amount: number; // buyurtma narxi (mijoz to'lovi)
  earning: number; // haydovchi ulushi
  foodItemsTotal?: number; // ovqat: oshxonaga to'lanadigan summa (naqd)
  foodServiceFee?: number; // ovqat: xizmat haqi (balansdan)
  /** Taksi tarif klassi — 'comfort' bo'lsa faqat Comfort haydovchilarga. */
  tariffClass?: 'start' | 'comfort';
  /**
   * "Uyga" rejimi mosligi — hozir taklif qilingan (yoki so'ragan) haydovchi
   * uchun uyga boruvchi yo'lga mos keladimi (tavsiya/ustuvorlik, qattiq
   * filtr emas). Taxi/Parcel'da B6 komissiya qayta hisoblashda ishlatiladi.
   */
  homeModeMatch?: boolean;
}

interface OfferState extends DispatchOffer {
  offeredTo: string | null;
  expiresAt: number; // ms
  tried: Set<string>;
  attempt: number; // nechta haydovchiga taklif qilindi
  status: 'offering' | 'pool';
  createdAt: number;
}

/**
 * Buyurtmani eng yaqin online haydovchiga 20s ga taklif qiladi; olmasa keyingi
 * eng yaqiniga; 2 marta olinmasa "pool" (hammaga ko'rinadi). plan/06-driver-app.md
 * In-memory (bitta instans, MVP).
 */
@Injectable()
export class DispatchService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(DispatchService.name);
  private readonly offers = new Map<string, OfferState>();
  private timer?: ReturnType<typeof setInterval>;

  static readonly OFFER_SEC = 20;
  static readonly MAX_ATTEMPTS = 2; // 2 ta haydovchiga, keyin pool
  /**
   * Reyting-tiebreak klasterlash: masofa bo'yicha saralangan ro'yxatda
   * ketma-ket ikki haydovchi orasidagi farq shu qiymatdan kam bo'lsa —
   * "bir joyda" hisoblanadi va reyting bo'yicha (yuqorisi birinchi) tartiblanadi.
   */
  static readonly RATING_CLUSTER_GAP_KM = 0.15;
  static readonly POOL_FAIL_SEC = 120; // food/market: pool'da haydovchi topilmasa fail
  /** @deprecated {@link POOL_FAIL_SEC} nomiga o'tkazildi — moslik uchun qoldirildi. */
  static readonly FOOD_FAIL_SEC = DispatchService.POOL_FAIL_SEC;
  /** Fail-timeout tekshiriladigan vertikallar (food/market — kuryer topilmasa mijozga xabar). */
  private static readonly POOL_FAIL_VERTICALS: DispatchVertical[] = ['food', 'market'];

  /**
   * Har bir vertikal o'z fail-handlerini ro'yxatdan o'tkazadi (circular DI'siz);
   * har biri o'z vertikalini ichida tekshiradi, shu sabab bir nechtasi bir vaqtda
   * ishlashi mumkin (masalan food + market).
   */
  private readonly failHandlers: Array<(orderId: string, vertical: DispatchVertical) => void> = [];

  constructor(
    private readonly tracking: DriverLocationService,
    private readonly notifications: NotificationClient,
    private readonly driverInfo: DriverInfoClient,
    private readonly osrm: OsrmRouteClient,
    private readonly tariff: TariffService,
  ) {}

  /** "Haydovchi topilmadi" fail callback qo'shadi (bir nechta vertikal mustaqil ro'yxatdan o'tishi mumkin). */
  setFailHandler(
    fn: (orderId: string, vertical: DispatchVertical) => void,
  ): void {
    this.failHandlers.push(fn);
  }

  onModuleInit() {
    this.timer = setInterval(() => {
      this.sweep().catch((e) =>
        this.logger.warn(`Dispatch sweep xatosi: ${(e as Error).message}`),
      );
    }, 2000);
  }

  onModuleDestroy() {
    if (this.timer) clearInterval(this.timer);
  }

  /** Yangi buyurtma — eng yaqin haydovchiga taklif qiladi. */
  async offer(data: DispatchOffer): Promise<void> {
    if (this.offers.has(data.orderId)) return;
    const state: OfferState = {
      ...data,
      offeredTo: null,
      expiresAt: 0,
      tried: new Set<string>(),
      attempt: 0,
      status: 'offering',
      createdAt: Date.now(),
      homeModeMatch: false,
    };
    this.offers.set(data.orderId, state);
    await this.assignNext(state);
    this.logger.log(
      `Dispatch: #${data.orderId} -> ${state.offeredTo ?? 'pool'} (${state.status})`,
    );
  }

  /** Keyingi eng yaqin haydovchiga taklif (yoki pool'ga). */
  private async assignNext(state: OfferState): Promise<void> {
    if (state.attempt >= DispatchService.MAX_ATTEMPTS) {
      state.status = 'pool';
      state.offeredTo = null;
      return;
    }
    let candidates = await this.tracking.nearestDrivers(
      state.pickupLat,
      state.pickupLng,
      state.tried,
    );
    // Comfort buyurtma — faqat Comfort tarifi yoqilgan haydovchilarga.
    if (state.tariffClass === 'comfort') {
      const comfort = await this.driverInfo.getComfortIds();
      candidates = candidates.filter((c) => comfort.has(c.id));
    }
    if (candidates.length === 0) {
      state.status = 'pool';
      state.offeredTo = null;
      state.homeModeMatch = false;
      return;
    }
    // "Uyga" rejimi — endi QATTIQ FILTR (tavsiya emas): mos kelmagan "uyga
    // rejimi" faol haydovchilar ro'yxatdan BUTUNLAY olib tashlanadi, mos
    // kelganlari esa boshiga ko'chiriladi. Boshqa (oddiy) haydovchilarga
    // bu bosqich tegmaydi.
    const { ids, matches } = await this.applyHomeModeFilterAndRatingSort(
      candidates,
      state,
    );
    if (ids.length === 0) {
      state.status = 'pool';
      state.offeredTo = null;
      state.homeModeMatch = false;
      return;
    }
    state.offeredTo = ids[0];
    state.homeModeMatch = matches.has(ids[0]);
    state.attempt += 1;
    state.expiresAt = Date.now() + DispatchService.OFFER_SEC * 1000;
    state.status = 'offering';
    // Haydovchini darhol uyg'otish: yuqori muhimlik, data-only (to'liq ekran
    // signalni ilovaning O'ZI ko'rsatadi — fon/yopiq holatda ham ishlaydi).
    this.pushOffer(state, ids[0]).catch((e) =>
      this.logger.warn(`Offer push xatosi: ${(e as Error).message}`),
    );
  }

  /** Taklif qilingan haydovchiga FCM signal (yangi buyurtma keldi). */
  private async pushOffer(state: OfferState, driverId: string): Promise<void> {
    const label = VERTICAL_LABEL[state.vertical];
    await this.notifications.notify(
      driverId,
      'Yangi buyurtma',
      `${label} • ${state.pickupName}`,
      {
        type: 'offer',
        orderId: state.orderId,
        vertical: state.vertical,
        label,
        pickupName: state.pickupName,
        amount: String(state.amount),
        earning: String(state.earning),
      },
      { dataOnly: true, channelId: OFFER_CHANNEL, priority: 'high' },
    );
  }

  /** Muddati o'tgan takliflarni keyingisiga/pool'ga o'tkazadi. */
  private async sweep(): Promise<void> {
    for (const state of this.offers.values()) {
      if (state.status === 'offering' && Date.now() > state.expiresAt) {
        if (state.offeredTo) state.tried.add(state.offeredTo);
        await this.assignNext(state);
      }
      // Food/market: pool'da belgilangan vaqtdan uzoq turgan (haydovchi
      // topilmagan) buyurtmani bekor qilamiz — mijozga "kuryer topilmadi".
      if (
        DispatchService.POOL_FAIL_VERTICALS.includes(state.vertical) &&
        state.status === 'pool' &&
        Date.now() - state.createdAt > DispatchService.POOL_FAIL_SEC * 1000
      ) {
        this.offers.delete(state.orderId);
        for (const handler of this.failHandlers) {
          try {
            handler(state.orderId, state.vertical);
          } catch (e) {
            this.logger.warn(`Fail handler xatosi: ${(e as Error).message}`);
          }
        }
      }
    }
  }

  /** Haydovchiga hozir taklif qilingan buyurtma (masofa + qolgan vaqt bilan). */
  async getOfferFor(
    driverId: string,
  ): Promise<(DispatchOffer & { distanceKm: number; secondsLeft: number }) | null> {
    for (const s of this.offers.values()) {
      if (
        s.status === 'offering' &&
        s.offeredTo === driverId &&
        Date.now() < s.expiresAt
      ) {
        const loc = await this.tracking.get(driverId);
        const distanceKm = loc
          ? Math.round(
              haversineKm(
                { text: '', lat: loc.lat, lng: loc.lng },
                { text: '', lat: s.pickupLat, lng: s.pickupLng },
              ) * 100,
            ) / 100
          : 0;
        return {
          ...this.toOffer(s),
          distanceKm,
          secondsLeft: Math.max(0, Math.ceil((s.expiresAt - Date.now()) / 1000)),
        };
      }
    }
    return null;
  }

  /**
   * Pool (qabul qilinmagan) buyurtmalar — haydovchiga ko'ra: Comfort
   * buyurtmalar faqat Comfort tarifi yoqilgan haydovchilarga ko'rinadi.
   * So'ragan haydovchi "uyga rejimi" faol bo'lsa — QATTIQ FILTR: faqat
   * mos kelgan buyurtmalar qaytariladi (boshqalari umuman ko'rinmaydi,
   * bezovta qilmaydi). Oddiy haydovchilarga bu filtr tegmaydi.
   */
  async poolFor(driverId: string): Promise<DispatchOffer[]> {
    const all = [...this.offers.values()]
      .filter((s) => s.status === 'pool')
      .sort((a, b) => b.createdAt - a.createdAt);
    const hasComfortOffers = all.some((s) => s.tariffClass === 'comfort');
    const comfort = hasComfortOffers
      ? await this.driverInfo.getComfortIds()
      : new Set<string>();
    const filtered = all.filter(
      (s) => s.tariffClass !== 'comfort' || comfort.has(driverId),
    );
    if (filtered.length === 0) return [];

    const homeModeDrivers = await this.driverInfo.getHomeModeDrivers();
    const home = homeModeDrivers.get(driverId);
    if (!home) return filtered.map((s) => this.toOffer(s));
    const loc = await this.tracking.get(driverId);
    // Fail-closed: haydovchining o'z joylashuvi noma'lum bo'lsa, mosligini
    // aniqlab bo'lmaydi — hech narsa ko'rsatilmaydi (bezovta qilmasin).
    if (!loc) return [];

    const t = await this.tariff.getTariff();
    const results = await Promise.all(
      filtered.map(async (s) => ({
        s,
        match: await this.isHomeModeMatch(
          loc,
          home,
          this.orderWaypoints(s),
          t.homeModeMaxDetourPercent,
          t.homeModeMaxHomeDistanceKm,
        ),
      })),
    );
    return results
      .filter((r) => r.match)
      .map((r) => ({ ...this.toOffer(r.s), homeModeMatch: true }));
  }

  /**
   * Qabul qilayotgan aniq haydovchi uchun "uyga mos"lik (B6: komissiya
   * qayta hisoblash). 'offering' holatida taklif paytida hisoblangan qiymat
   * qayta ishlatiladi (izchillik — nima ko'rsatilgan bo'lsa, shu hisoblanadi);
   * 'pool'da har bir qabul qiluvchi uchun jonli hisoblanadi (ko'pga ochiq).
   */
  async homeModeMatchFor(driverId: string, orderId: string): Promise<boolean> {
    const s = this.offers.get(orderId);
    if (!s) return false;
    if (s.status === 'offering') {
      return s.offeredTo === driverId ? (s.homeModeMatch ?? false) : false;
    }
    const homeModeDrivers = await this.driverInfo.getHomeModeDrivers();
    const home = homeModeDrivers.get(driverId);
    if (!home) return false;
    const loc = await this.tracking.get(driverId);
    if (!loc) return false;
    const t = await this.tariff.getTariff();
    return this.isHomeModeMatch(
      loc,
      home,
      this.orderWaypoints(s),
      t.homeModeMaxDetourPercent,
      t.homeModeMaxHomeDistanceKm,
    );
  }

  /** Buyurtma nuqtalari (pickup + bo'lsa dropoff) — OSRM marshrut uchun. */
  private orderWaypoints(s: OfferState): GeoPoint[] {
    const points: GeoPoint[] = [{ text: '', lat: s.pickupLat, lng: s.pickupLng }];
    if (s.dropoffLat != null && s.dropoffLng != null) {
      points.push({ text: '', lat: s.dropoffLat, lng: s.dropoffLng });
    }
    return points;
  }

  /**
   * "Uyga mos"lik yagona ta'rifi — IKKALA shart ham TO'G'RI bo'lishi shart:
   * (a) uyga boruvchi yo'ldan chetlanish `maxDetourPercent`dan kam, VA
   * (b) buyurtmaning oxirgi nuqtasi (dropoff, bo'lmasa pickup) uydan
   * `maxHomeDistanceKm`dan yaqin. OSRM ishlamasa/xato bersa — FAIL-CLOSED
   * (`false`, "mos emas") — bu ATAYLAB: "uyga rejimi" foydalanuvchi buni
   * aniq so'ragan (boshqa buyurtmalar bezovta qilmasin), noaniq holatda
   * jim turish noto'g'ri buyurtma kelishidan yaxshiroq. Bitta joyda
   * ishlatiladi va 4 chaqiruvchida (assignNext, poolFor,
   * homeModeMatchFor, canAccept) BIR XIL natija berishi shart — B6
   * komissiya qayta hisoblash aynan shu qiymatga bog'liq.
   */
  private async isHomeModeMatch(
    driverLoc: { lat: number; lng: number },
    home: { lat: number; lng: number },
    waypoints: GeoPoint[],
    maxDetourPercent: number,
    maxHomeDistanceKm: number,
  ): Promise<boolean> {
    const driverPoint: GeoPoint = { text: '', lat: driverLoc.lat, lng: driverLoc.lng };
    const homePoint: GeoPoint = { text: '', lat: home.lat, lng: home.lng };
    const detour = await this.osrm.detourPercent(driverPoint, waypoints, homePoint);
    if (detour == null || detour > maxDetourPercent) return false;
    const finalPoint = waypoints[waypoints.length - 1];
    return haversineKm(finalPoint, homePoint) <= maxHomeDistanceKm;
  }

  /**
   * `candidates` ichidan "uyga rejimi" faol VA {@link isHomeModeMatch}ga
   * ko'ra MOS KELMAGAN haydovchilar ro'yxatdan BUTUNLAY olib tashlanadi
   * (qattiq filtr — boshqa buyurtmalar bilan bezovta qilinmasin). Oddiy
   * (uyga rejimi faol bo'lmagan) haydovchilarga bu bosqich tegmaydi.
   * Qolgan ro'yxatga reyting-klaster tiebreak qo'llanadi (bir joyda
   * turgan haydovchilar orasida reytingi yuqorisiga ustuvorlik), so'ng
   * mos kelgan "uyga rejimi" haydovchilar ro'yxat boshiga ko'chiriladi.
   */
  private async applyHomeModeFilterAndRatingSort(
    candidates: { id: string; distanceKm: number }[],
    state: OfferState,
  ): Promise<{ ids: string[]; matches: Set<string> }> {
    const matches = new Set<string>();
    const homeModeDrivers = await this.driverInfo.getHomeModeDrivers();
    let filtered = candidates;

    if (homeModeDrivers.size > 0) {
      const t = await this.tariff.getTariff();
      const waypoints = this.orderWaypoints(state);
      const results = await Promise.all(
        candidates.map(async (c) => {
          const home = homeModeDrivers.get(c.id);
          if (!home) return { c, keep: true, match: false };
          const loc = await this.tracking.get(c.id);
          // Fail-closed: joylashuvi noma'lum "uyga rejimi" haydovchi — mos emas.
          if (!loc) return { c, keep: false, match: false };
          const match = await this.isHomeModeMatch(
            loc,
            home,
            waypoints,
            t.homeModeMaxDetourPercent,
            t.homeModeMaxHomeDistanceKm,
          );
          return { c, keep: match, match };
        }),
      );
      filtered = results.filter((r) => r.keep).map((r) => r.c);
      for (const r of results) if (r.match) matches.add(r.c.id);
    }

    const sorted = await this.applyRatingTiebreak(filtered);
    if (matches.size === 0) return { ids: sorted, matches };
    return {
      ids: [
        ...sorted.filter((id) => matches.has(id)),
        ...sorted.filter((id) => !matches.has(id)),
      ],
      matches,
    };
  }

  /**
   * Masofa bo'yicha saralangan ro'yxatda "bir joyda" (ketma-ket farq
   * ≤{@link RATING_CLUSTER_GAP_KM}) turgan haydovchilar klasterga
   * yig'iladi va klaster ICHIDA reyting bo'yicha (yuqorisi birinchi)
   * tartiblanadi — klasterlar orasida esa masofa tartibi saqlanadi.
   * FAIL-OPEN: `getPublicBulk` auth servisidan javob ololmasa, barcha
   * reyting `0` deb olinadi (barqaror `sort` tufayli masofa tartibi
   * o'zgarishsiz qoladi) — dispatch HECH QACHON bu sabab bilan to'xtamaydi
   * (bu reyting-tiebreak butun tizimga tegishli bo'lgani uchun, "uyga
   * rejimi"dagi fail-closed siyosatidan ATAYLAB farqli).
   */
  private async applyRatingTiebreak(
    candidates: { id: string; distanceKm: number }[],
  ): Promise<string[]> {
    if (candidates.length <= 1) return candidates.map((c) => c.id);
    const info = await this.driverInfo.getPublicBulk(candidates.map((c) => c.id));
    const ratingOf = (id: string) => info.get(id)?.rating ?? 0;
    const out: string[] = [];
    for (let i = 0; i < candidates.length; ) {
      let j = i;
      while (
        j + 1 < candidates.length &&
        candidates[j + 1].distanceKm - candidates[j].distanceKm <=
          DispatchService.RATING_CLUSTER_GAP_KM
      ) {
        j++;
      }
      const cluster = candidates
        .slice(i, j + 1)
        .sort((a, b) => ratingOf(b.id) - ratingOf(a.id) || a.distanceKm - b.distanceKm);
      out.push(...cluster.map((c) => c.id));
      i = j + 1;
    }
    return out;
  }

  /** Buyurtma taklifi (vertikalni bilish uchun). */
  getById(orderId: string): DispatchOffer | null {
    const s = this.offers.get(orderId);
    return s ? this.toOffer(s) : null;
  }

  /** Haydovchi shu buyurtmani qabul qila oladimi (taklif yoki pool + Comfort). */
  async canAccept(driverId: string, orderId: string): Promise<boolean> {
    const s = this.offers.get(orderId);
    if (!s) return false;
    // Comfort buyurtmani faqat Comfort haydovchi olishi mumkin.
    if (s.tariffClass === 'comfort') {
      const ok = await this.driverInfo.isComfortDriver(driverId);
      if (!ok) return false;
    }
    // "Uyga rejimi" faol haydovchilar uchun QO'SHIMCHA himoya qatlami —
    // pool ro'yxatida (keshlanish/poll oralig'i tufayli) endi ko'rinmasa
    // ham, eski/keshlangan orderId bilan mos kelmagan buyurtmani qabul
    // qilib olishning oldini oladi. Oddiy haydovchilarga tegmaydi.
    const homeModeDrivers = await this.driverInfo.getHomeModeDrivers();
    if (homeModeDrivers.has(driverId)) {
      const match = await this.homeModeMatchFor(driverId, orderId);
      if (!match) return false;
    }
    if (s.status === 'pool') return true;
    return s.offeredTo === driverId && Date.now() < s.expiresAt;
  }

  /** Haydovchi o'tkazib yubordi — darhol keyingisiga. */
  async skip(driverId: string, orderId: string): Promise<void> {
    const s = this.offers.get(orderId);
    if (!s || s.offeredTo !== driverId) return;
    s.tried.add(driverId);
    await this.assignNext(s);
  }

  /** Buyurtma biriktirildi/yopildi — dispatchdan olib tashlaymiz. */
  clear(orderId: string): void {
    this.offers.delete(orderId);
  }

  private toOffer(s: OfferState): DispatchOffer {
    return {
      orderId: s.orderId,
      vertical: s.vertical,
      pickupLat: s.pickupLat,
      pickupLng: s.pickupLng,
      pickupName: s.pickupName,
      dropoffLat: s.dropoffLat ?? null,
      dropoffLng: s.dropoffLng ?? null,
      dropoffText: s.dropoffText ?? null,
      amount: s.amount,
      earning: s.earning,
      foodItemsTotal: s.foodItemsTotal,
      foodServiceFee: s.foodServiceFee,
      tariffClass: s.tariffClass,
      homeModeMatch: s.homeModeMatch,
    };
  }
}
