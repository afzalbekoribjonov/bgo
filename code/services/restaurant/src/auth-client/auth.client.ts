import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/** Auth servisidagi foydalanuvchining ommaviy ma'lumoti. */
export interface AuthUserLookup {
  id: string;
  phone: string;
  fullName: string | null;
}

/**
 * Auth servisidan foydalanuvchini telefon/ID bo'yicha topadi — oshxona egasini
 * telefon raqami bo'yicha bog'lash uchun. `x-internal-key` bilan. Qisqa muddatli
 * kesh (kam o'zgaradi). BEST-EFFORT: xato -> null.
 */
@Injectable()
export class AuthClient {
  private readonly logger = new Logger(AuthClient.name);
  private readonly baseUrl: string;
  private readonly key?: string;
  private readonly byIdCache = new Map<string, { user: AuthUserLookup | null; at: number }>();
  private static readonly TTL_MS = 60_000;
  /** Osilib qolgan ichki chaqiruv butun so'rovni cheksiz ushlab turmasin. */
  private static readonly FETCH_TIMEOUT_MS = 5_000;

  constructor(config: ConfigService) {
    this.baseUrl = config.get<string>('AUTH_SERVICE_URL') ?? 'http://localhost:4001';
    this.key = config.get<string>('INTERNAL_API_KEY');
  }

  /** Telefon raqami bo'yicha qidiradi (ega biriktirishdan oldin ko'rish/tasdiqlash). Keshlanmaydi. */
  async findUserByPhone(phone: string): Promise<AuthUserLookup | null> {
    if (!phone || !this.key) return null;
    try {
      const res = await fetch(
        `${this.baseUrl}/api/v1/internal/users/by-phone/${encodeURIComponent(phone)}`,
        {
          headers: { 'x-internal-key': this.key },
          signal: AbortSignal.timeout(AuthClient.FETCH_TIMEOUT_MS),
        },
      );
      if (!res.ok) return null;
      const json = (await res.json()) as { data: AuthUserLookup | null };
      return json?.data ?? null;
    } catch (err) {
      this.logger.warn(`Foydalanuvchi (telefon) topilmadi: ${(err as Error).message}`);
      return null;
    }
  }

  /** ID bo'yicha (mavjud egani ko'rsatish uchun) — qisqa keshlangan. */
  async getUserById(userId: string): Promise<AuthUserLookup | null> {
    if (!userId || !this.key) return null;
    const cached = this.byIdCache.get(userId);
    if (cached && Date.now() - cached.at < AuthClient.TTL_MS) return cached.user;
    try {
      const res = await fetch(`${this.baseUrl}/api/v1/internal/users/${userId}`, {
        headers: { 'x-internal-key': this.key },
        signal: AbortSignal.timeout(AuthClient.FETCH_TIMEOUT_MS),
      });
      if (!res.ok) return null;
      const json = (await res.json()) as { data: AuthUserLookup | null };
      const user = json?.data ?? null;
      this.byIdCache.set(userId, { user, at: Date.now() });
      return user;
    } catch (err) {
      this.logger.warn(`Foydalanuvchi (ID) topilmadi: ${(err as Error).message}`);
      return null;
    }
  }

  /**
   * Bir nechta foydalanuvchini ID bo'yicha bitta so'rovda oladi va `byIdCache`ni
   * to'ldiradi — admin ro'yxatlarni boyitishda har qator uchun alohida
   * `getUserById` chaqiruvi (N+1) o'rniga, keshni oldindan isitish uchun.
   */
  async getUsersById(userIds: string[]): Promise<Map<string, AuthUserLookup | null>> {
    const result = new Map<string, AuthUserLookup | null>();
    const uniqueIds = [...new Set(userIds.filter(Boolean))];
    if (!this.key || uniqueIds.length === 0) return result;

    const toFetch: string[] = [];
    for (const id of uniqueIds) {
      const cached = this.byIdCache.get(id);
      if (cached && Date.now() - cached.at < AuthClient.TTL_MS) {
        result.set(id, cached.user);
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
          signal: AbortSignal.timeout(AuthClient.FETCH_TIMEOUT_MS),
        },
      );
      if (!res.ok) {
        for (const id of toFetch) result.set(id, null);
        return result;
      }
      const json = (await res.json()) as { data: AuthUserLookup[] };
      const found = new Map((json?.data ?? []).map((u) => [u.id, u] as const));
      for (const id of toFetch) {
        const user = found.get(id) ?? null;
        this.byIdCache.set(id, { user, at: Date.now() });
        result.set(id, user);
      }
    } catch (err) {
      this.logger.warn(`Ko'p foydalanuvchi (ID) topilmadi: ${(err as Error).message}`);
      for (const id of toFetch) result.set(id, null);
    }
    return result;
  }
}
