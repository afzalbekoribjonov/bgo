import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/** Har qanday foydalanuvchining umumiy ma'lumoti (mijoz/haydovchi). */
export interface UserBasicInfo {
  id: string;
  phone: string;
  fullName: string | null;
}

/**
 * Auth servisidan foydalanuvchi ma'lumotini oladi (ism, telefon) — admin
 * panelda suhbatda kim ekanini ko'rsatish uchun. `x-internal-key` bilan.
 * Qisqa muddatli kesh. BEST-EFFORT: xato -> null (suhbatlar ro'yxati
 * baribir ko'rsatiladi, faqat ism o'rniga ID qoladi).
 */
@Injectable()
export class UserInfoClient {
  private readonly logger = new Logger(UserInfoClient.name);
  private readonly baseUrl: string;
  private readonly key?: string;
  private readonly cache = new Map<string, { info: UserBasicInfo | null; at: number }>();
  private static readonly TTL_MS = 60_000;
  /** Osilib qolgan ichki chaqiruv butun so'rovni cheksiz ushlab turmasin. */
  private static readonly FETCH_TIMEOUT_MS = 5_000;

  constructor(config: ConfigService) {
    this.baseUrl = config.get<string>('AUTH_SERVICE_URL') ?? 'http://localhost:4001';
    this.key = config.get<string>('INTERNAL_API_KEY');
  }

  async getUserInfo(userId: string): Promise<UserBasicInfo | null> {
    if (!userId || !this.key) return null;
    const cached = this.cache.get(userId);
    if (cached && Date.now() - cached.at < UserInfoClient.TTL_MS) return cached.info;
    try {
      const res = await fetch(`${this.baseUrl}/api/v1/internal/users/${userId}`, {
        headers: { 'x-internal-key': this.key },
        signal: AbortSignal.timeout(UserInfoClient.FETCH_TIMEOUT_MS),
      });
      if (!res.ok) return null;
      const json = (await res.json()) as { data: UserBasicInfo | null };
      const info = json?.data ?? null;
      this.cache.set(userId, { info, at: Date.now() });
      return info;
    } catch (err) {
      this.logger.warn(`Foydalanuvchi ma'lumoti olinmadi: ${(err as Error).message}`);
      return null;
    }
  }
}
