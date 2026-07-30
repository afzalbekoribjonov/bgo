import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/** Haydovchining ommaviy ma'lumoti (auth servisidan). */
export interface DriverPublicInfo {
  fullName: string;
  carName: string | null;
  carYear: number | null;
  plateNumber: string | null;
}

/** Har qanday foydalanuvchining umumiy ma'lumoti (mijoz/haydovchi/oshxona egasi). */
export interface UserBasicInfo {
  id: string;
  phone: string;
  fullName: string | null;
}

/**
 * Auth servisidan haydovchi ommaviy ma'lumotini oladi (ism, mashina) —
 * mijozga safar paytida ko'rsatish uchun. `x-internal-key` bilan.
 * Qisqa muddatli kesh (ism/mashina kam o'zgaradi). BEST-EFFORT: xato -> null.
 */
@Injectable()
export class DriverInfoClient {
  private readonly logger = new Logger(DriverInfoClient.name);
  private readonly baseUrl: string;
  private readonly key?: string;
  private readonly cache = new Map<
    string,
    { info: DriverPublicInfo | null; at: number }
  >();
  private readonly phoneCache = new Map<
    string,
    { phone: string | null; at: number }
  >();
  private readonly userInfoCache = new Map<
    string,
    { info: UserBasicInfo | null; at: number }
  >();
  private comfortCache: { ids: Set<string>; at: number } | null = null;
  private homeModeCache: {
    map: Map<string, { lat: number; lng: number }>;
    at: number;
  } | null = null;
  private static readonly TTL_MS = 60_000;
  private static readonly COMFORT_TTL_MS = 20_000;
  private static readonly HOME_MODE_TTL_MS = 20_000;
  /** Osilib qolgan ichki chaqiruv butun so'rovni cheksiz ushlab turmasin. */
  private static readonly FETCH_TIMEOUT_MS = 5_000;

  constructor(config: ConfigService) {
    this.baseUrl =
      config.get<string>('AUTH_SERVICE_URL') ?? 'http://localhost:4001';
    this.key = config.get<string>('INTERNAL_API_KEY');
  }

  /** Foydalanuvchi telefon raqami (userId bo'yicha) — suhbat qo'ng'irog'i uchun. */
  async getUserPhone(userId: string): Promise<string | null> {
    if (!userId || !this.key) return null;
    const c = this.phoneCache.get(userId);
    if (c && Date.now() - c.at < DriverInfoClient.TTL_MS) return c.phone;
    try {
      const res = await fetch(
        `${this.baseUrl}/api/v1/internal/drivers/${userId}/phone`,
        {
          headers: { 'x-internal-key': this.key },
          signal: AbortSignal.timeout(DriverInfoClient.FETCH_TIMEOUT_MS),
        },
      );
      if (!res.ok) return null;
      const json = (await res.json()) as { data: { phone: string | null } };
      const phone = json?.data?.phone ?? null;
      this.phoneCache.set(userId, { phone, at: Date.now() });
      return phone;
    } catch {
      return null;
    }
  }

  /** Bajarilgan buyurtma komissiyasini haydovchi balansidan yechadi (best-effort). */
  async charge(userId: string, amount: number, note: string): Promise<void> {
    if (!userId || !this.key || amount <= 0) return;
    try {
      const res = await fetch(
        `${this.baseUrl}/api/v1/internal/drivers/${userId}/charge`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-internal-key': this.key,
          },
          body: JSON.stringify({ amount, note }),
          signal: AbortSignal.timeout(DriverInfoClient.FETCH_TIMEOUT_MS),
        },
      );
      if (!res.ok) this.logger.warn(`Komissiya yechilmadi: ${res.status}`);
    } catch (err) {
      this.logger.warn(`Komissiya yechilmadi: ${(err as Error).message}`);
    }
  }

  /**
   * Haydovchi balansiga SEZDIRMASDAN qo'shadi (best-effort) — masalan bekor
   * qilish jarimasi mijoz aybi bilan bo'lganda qaytariladi. Haydovchi
   * "Hisobim"da bu yozuvni ko'rmaydi, faqat balans darhol to'g'ri bo'ladi.
   */
  async silentRefund(userId: string, amount: number, note: string): Promise<void> {
    if (!userId || !this.key || amount <= 0) return;
    try {
      const res = await fetch(
        `${this.baseUrl}/api/v1/internal/drivers/${userId}/silent-refund`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-internal-key': this.key,
          },
          body: JSON.stringify({ amount, note }),
          signal: AbortSignal.timeout(DriverInfoClient.FETCH_TIMEOUT_MS),
        },
      );
      if (!res.ok) this.logger.warn(`Sezdirmasdan qaytarish muvaffaqiyatsiz: ${res.status}`);
    } catch (err) {
      this.logger.warn(`Sezdirmasdan qaytarish xatosi: ${(err as Error).message}`);
    }
  }

  /**
   * Har qanday foydalanuvchining umumiy ma'lumoti (ism+telefon) — admin panelda
   * mijoz/haydovchi nomini ko'rsatish uchun (auth servisidagi umumiy endpoint).
   */
  async getUserInfo(userId: string): Promise<UserBasicInfo | null> {
    if (!userId || !this.key) return null;
    const cached = this.userInfoCache.get(userId);
    if (cached && Date.now() - cached.at < DriverInfoClient.TTL_MS) return cached.info;
    try {
      const res = await fetch(`${this.baseUrl}/api/v1/internal/users/${userId}`, {
        headers: { 'x-internal-key': this.key },
        signal: AbortSignal.timeout(DriverInfoClient.FETCH_TIMEOUT_MS),
      });
      if (!res.ok) return null;
      const json = (await res.json()) as { data: UserBasicInfo | null };
      const info = json?.data ?? null;
      this.userInfoCache.set(userId, { info, at: Date.now() });
      return info;
    } catch (err) {
      this.logger.warn(`Foydalanuvchi ma'lumoti olinmadi: ${(err as Error).message}`);
      return null;
    }
  }

  /**
   * Bir nechta foydalanuvchining ma'lumotini bitta so'rovda oladi (id -> info)
   * — admin ro'yxatlarni boyitishda har qator uchun alohida chaqiruv (N+1)
   * o'rniga. `getUserInfo`bilan bir xil keshni ishlatadi/to'ldiradi.
   */
  async getUsersInfo(userIds: string[]): Promise<Map<string, UserBasicInfo | null>> {
    const result = new Map<string, UserBasicInfo | null>();
    const uniqueIds = [...new Set(userIds.filter(Boolean))];
    if (!this.key || uniqueIds.length === 0) return result;

    const toFetch: string[] = [];
    for (const id of uniqueIds) {
      const cached = this.userInfoCache.get(id);
      if (cached && Date.now() - cached.at < DriverInfoClient.TTL_MS) {
        result.set(id, cached.info);
      } else {
        toFetch.push(id);
      }
    }
    if (toFetch.length === 0) return result;

    try {
      const res = await fetch(
        `${this.baseUrl}/api/v1/internal/users/batch?ids=${toFetch.map(encodeURIComponent).join(',')}`,
        {
          headers: { 'x-internal-key': this.key },
          signal: AbortSignal.timeout(DriverInfoClient.FETCH_TIMEOUT_MS),
        },
      );
      if (!res.ok) {
        for (const id of toFetch) result.set(id, null);
        return result;
      }
      const json = (await res.json()) as { data: UserBasicInfo[] };
      const found = new Map((json?.data ?? []).map((u) => [u.id, u] as const));
      for (const id of toFetch) {
        const info = found.get(id) ?? null;
        this.userInfoCache.set(id, { info, at: Date.now() });
        result.set(id, info);
      }
    } catch (err) {
      this.logger.warn(`Ko'p foydalanuvchi ma'lumoti olinmadi: ${(err as Error).message}`);
      for (const id of toFetch) result.set(id, null);
    }
    return result;
  }

  /**
   * Comfort tarifi yoqilgan haydovchilar (userId to'plami) — dispatch/pool
   * filtrlash uchun. Qisqa kesh; xato bo'lsa bo'sh to'plam (xavfsiz standart:
   * comfort buyurtma noto'g'ri haydovchiga bormaydi).
   */
  async getComfortIds(): Promise<Set<string>> {
    if (
      this.comfortCache &&
      Date.now() - this.comfortCache.at < DriverInfoClient.COMFORT_TTL_MS
    ) {
      return this.comfortCache.ids;
    }
    if (!this.key) return new Set();
    try {
      const res = await fetch(
        `${this.baseUrl}/api/v1/internal/drivers/comfort-ids`,
        {
          headers: { 'x-internal-key': this.key },
          signal: AbortSignal.timeout(DriverInfoClient.FETCH_TIMEOUT_MS),
        },
      );
      if (!res.ok) return this.comfortCache?.ids ?? new Set();
      const json = (await res.json()) as { data: string[] };
      const ids = new Set(json?.data ?? []);
      this.comfortCache = { ids, at: Date.now() };
      return ids;
    } catch {
      return this.comfortCache?.ids ?? new Set();
    }
  }

  /** Haydovchi Comfort tarifida ishlay oladimi. */
  async isComfortDriver(userId: string): Promise<boolean> {
    const ids = await this.getComfortIds();
    return ids.has(userId);
  }

  /**
   * "Uyga" rejimi faol haydovchilar (userId -> uy koordinatasi) — dispatch
   * uyga mos buyurtmalarni tavsiya qilishi uchun. Qisqa kesh; xato bo'lsa
   * bo'sh xarita (xavfsiz standart: hech kimga ustuvorlik berilmaydi).
   */
  async getHomeModeDrivers(): Promise<Map<string, { lat: number; lng: number }>> {
    if (
      this.homeModeCache &&
      Date.now() - this.homeModeCache.at < DriverInfoClient.HOME_MODE_TTL_MS
    ) {
      return this.homeModeCache.map;
    }
    if (!this.key) return new Map();
    try {
      const res = await fetch(
        `${this.baseUrl}/api/v1/internal/drivers/home-mode-active`,
        {
          headers: { 'x-internal-key': this.key },
          signal: AbortSignal.timeout(DriverInfoClient.FETCH_TIMEOUT_MS),
        },
      );
      if (!res.ok) return this.homeModeCache?.map ?? new Map();
      const json = (await res.json()) as {
        data: { userId: string; lat: number; lng: number }[];
      };
      const map = new Map(
        (json?.data ?? []).map(
          (d) => [d.userId, { lat: d.lat, lng: d.lng }] as const,
        ),
      );
      this.homeModeCache = { map, at: Date.now() };
      return map;
    } catch {
      return this.homeModeCache?.map ?? new Map();
    }
  }

  /**
   * Haydovchi buyurtmani bekor qildi — ketma-ket hisoblagichni oshiradi
   * (best-effort, xato bo'lsa jim o'tkaziladi — bekor qilish oqimini to'xtatmaydi).
   */
  async recordCancellation(userId: string): Promise<void> {
    if (!userId || !this.key) return;
    try {
      await fetch(
        `${this.baseUrl}/api/v1/internal/drivers/${userId}/record-cancellation`,
        {
          method: 'POST',
          headers: { 'x-internal-key': this.key },
          signal: AbortSignal.timeout(DriverInfoClient.FETCH_TIMEOUT_MS),
        },
      );
    } catch (err) {
      this.logger.warn(`Bekor qilish hisoblagichi yangilanmadi: ${(err as Error).message}`);
    }
  }

  /** Haydovchi buyurtmani muvaffaqiyatli yakunladi — hisoblagich 0'ga tushadi. */
  async recordCompletion(userId: string): Promise<void> {
    if (!userId || !this.key) return;
    try {
      await fetch(
        `${this.baseUrl}/api/v1/internal/drivers/${userId}/record-completion`,
        {
          method: 'POST',
          headers: { 'x-internal-key': this.key },
          signal: AbortSignal.timeout(DriverInfoClient.FETCH_TIMEOUT_MS),
        },
      );
    } catch (err) {
      this.logger.warn(`Bekor qilish hisoblagichi tozalanmadi: ${(err as Error).message}`);
    }
  }

  /** Ketma-ket `threshold`dan ortiq bekor qilgan haydovchilar (Shubhali haydovchilar). */
  async listHighCancellations(threshold = 3): Promise<
    { userId: string; driverName: string; carName: string | null; plateNumber: string | null; consecutiveCancellations: number }[]
  > {
    if (!this.key) return [];
    try {
      const res = await fetch(
        `${this.baseUrl}/api/v1/internal/drivers/high-cancellations?threshold=${threshold}`,
        {
          headers: { 'x-internal-key': this.key },
          signal: AbortSignal.timeout(DriverInfoClient.FETCH_TIMEOUT_MS),
        },
      );
      if (!res.ok) return [];
      const json = (await res.json()) as {
        data: {
          userId: string;
          driverName: string;
          carName: string | null;
          plateNumber: string | null;
          consecutiveCancellations: number;
        }[];
      };
      return json?.data ?? [];
    } catch (err) {
      this.logger.warn(`Yuqori bekor qilishlar ro'yxati olinmadi: ${(err as Error).message}`);
      return [];
    }
  }

  async getPublic(userId: string): Promise<DriverPublicInfo | null> {
    if (!userId || !this.key) return null;
    const cached = this.cache.get(userId);
    if (cached && Date.now() - cached.at < DriverInfoClient.TTL_MS) {
      return cached.info;
    }
    try {
      const res = await fetch(
        `${this.baseUrl}/api/v1/internal/drivers/${userId}`,
        {
          headers: { 'x-internal-key': this.key },
          signal: AbortSignal.timeout(DriverInfoClient.FETCH_TIMEOUT_MS),
        },
      );
      if (!res.ok) return null;
      const json = (await res.json()) as { data: DriverPublicInfo | null };
      const info = json?.data ?? null;
      this.cache.set(userId, { info, at: Date.now() });
      return info;
    } catch (err) {
      this.logger.warn(`Driver info olinmadi: ${(err as Error).message}`);
      return null;
    }
  }

  /**
   * Bir nechta haydovchining ommaviy ma'lumotini bitta so'rovda oladi
   * (id -> info) — admin ro'yxatlarni boyitishda har qator uchun alohida
   * chaqiruv (N+1) o'rniga. `getPublic` bilan bir xil keshni ishlatadi/to'ldiradi.
   */
  async getPublicBulk(userIds: string[]): Promise<Map<string, DriverPublicInfo | null>> {
    const result = new Map<string, DriverPublicInfo | null>();
    const uniqueIds = [...new Set(userIds.filter(Boolean))];
    if (!this.key || uniqueIds.length === 0) return result;

    const toFetch: string[] = [];
    for (const id of uniqueIds) {
      const cached = this.cache.get(id);
      if (cached && Date.now() - cached.at < DriverInfoClient.TTL_MS) {
        result.set(id, cached.info);
      } else {
        toFetch.push(id);
      }
    }
    if (toFetch.length === 0) return result;

    try {
      const res = await fetch(
        `${this.baseUrl}/api/v1/internal/drivers/batch?ids=${toFetch.map(encodeURIComponent).join(',')}`,
        {
          headers: { 'x-internal-key': this.key },
          signal: AbortSignal.timeout(DriverInfoClient.FETCH_TIMEOUT_MS),
        },
      );
      if (!res.ok) {
        for (const id of toFetch) result.set(id, null);
        return result;
      }
      const json = (await res.json()) as {
        data: (DriverPublicInfo & { userId: string })[];
      };
      const found = new Map((json?.data ?? []).map((d) => [d.userId, d] as const));
      for (const id of toFetch) {
        const info = found.get(id) ?? null;
        this.cache.set(id, { info, at: Date.now() });
        result.set(id, info);
      }
    } catch (err) {
      this.logger.warn(`Ko'p haydovchi ma'lumoti olinmadi: ${(err as Error).message}`);
      for (const id of toFetch) result.set(id, null);
    }
    return result;
  }
}
