import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface MarketProductSnapshot {
  id: string;
  name: string;
  price: number;
  stockQty: number;
  /** Mavjud o'lchamlar — bo'sh bo'lsa mahsulot o'lchamsiz. */
  sizes: string[];
}

export interface MarketPickupLocation {
  id: string;
  name: string;
  address: string;
  lat: number;
  lng: number;
}

export interface MarketSettingsSnapshot {
  minOrderAmount: number;
  isAcceptingOrders: boolean;
}

/**
 * Market servisidan (katalog) mahsulot/zaxira/pickup joy ma'lumotini oladi —
 * narx/nom SERVER tomonda aniqlanadi (mijoz yuborgan narxga ishonilmaydi).
 * `x-internal-key` bilan himoyalangan servislararo chaqiruvlar.
 */
@Injectable()
export class MarketClient {
  private readonly logger = new Logger(MarketClient.name);
  private readonly baseUrl: string;
  /** Zaxira ("default") kalit ATAYLAB yo'q — sozlanmagan bo'lsa xato beriladi. */
  private readonly internalKey?: string;
  /** Osilib qolgan ichki chaqiruv butun so'rovni cheksiz ushlab turmasin. */
  private static readonly FETCH_TIMEOUT_MS = 5_000;
  private settingsCache: { settings: MarketSettingsSnapshot; at: number } | null = null;
  private static readonly SETTINGS_TTL_MS = 60_000;

  constructor(config: ConfigService) {
    this.baseUrl =
      config.get<string>('MARKET_SERVICE_URL') ?? 'http://localhost:4005';
    this.internalKey = config.get<string>('INTERNAL_API_KEY');
  }

  /**
   * Market chaqiruvlari (narx/zaxira) buyurtma yaratishning majburiy qismi —
   * kalit yo'q bo'lsa jimgina davom etib bo'lmaydi, aniq xato beramiz.
   */
  private headers(json = false): Record<string, string> {
    if (!this.internalKey) {
      this.logger.error(
        "INTERNAL_API_KEY sozlanmagan — market servisiga ichki so'rov yuborib bo'lmaydi",
      );
      throw new ServiceUnavailableException('Market xizmati vaqtincha ishlamayapti');
    }
    return {
      'x-internal-key': this.internalKey,
      ...(json ? { 'Content-Type': 'application/json' } : {}),
    };
  }

  async getProduct(id: string): Promise<MarketProductSnapshot> {
    // Sarlavhalar try'dan TASHQARIDA tayyorlanadi — kalit yo'qligi "ulanib
    // bo'lmadi" deb noto'g'ri yorliqlanmasligi uchun.
    const headers = this.headers();
    let response: Response;
    try {
      response = await fetch(
        `${this.baseUrl}/api/v1/market/internal/products/${id}`,
        {
          headers,
          signal: AbortSignal.timeout(MarketClient.FETCH_TIMEOUT_MS),
        },
      );
    } catch (err) {
      this.logger.error(`Market servisiga ulanib bo'lmadi: ${(err as Error).message}`);
      throw new ServiceUnavailableException('Market xizmati ishlamayapti');
    }
    if (response.status === 404) throw new NotFoundException('Mahsulot topilmadi');
    if (!response.ok) {
      throw new ServiceUnavailableException('Market xizmati xato qaytardi');
    }
    const body = (await response.json()) as { data: MarketProductSnapshot };
    return body.data;
  }

  async getPickupLocation(id: string): Promise<MarketPickupLocation> {
    const headers = this.headers();
    let response: Response;
    try {
      response = await fetch(
        `${this.baseUrl}/api/v1/market/internal/pickup-locations/${id}`,
        {
          headers,
          signal: AbortSignal.timeout(MarketClient.FETCH_TIMEOUT_MS),
        },
      );
    } catch (err) {
      this.logger.error(`Market servisiga ulanib bo'lmadi: ${(err as Error).message}`);
      throw new ServiceUnavailableException('Market xizmati ishlamayapti');
    }
    if (response.status === 404) {
      throw new NotFoundException("Olib ketish joyi topilmadi");
    }
    if (!response.ok) {
      throw new ServiceUnavailableException('Market xizmati xato qaytardi');
    }
    const body = (await response.json()) as { data: MarketPickupLocation };
    return body.data;
  }

  /** Zaxirani band qiladi (atomik) — yetarli bo'lmasa 400. */
  async reserveStock(productId: string, qty: number): Promise<void> {
    const response = await fetch(
      `${this.baseUrl}/api/v1/market/internal/products/${productId}/reserve-stock`,
      {
        method: 'POST',
        headers: this.headers(true),
        body: JSON.stringify({ qty }),
        signal: AbortSignal.timeout(MarketClient.FETCH_TIMEOUT_MS),
      },
    ).catch((err: Error) => {
      this.logger.error(`Zaxira band qilishda ulanish xatosi: ${err.message}`);
      throw new ServiceUnavailableException('Market xizmati ishlamayapti');
    });
    if (!response.ok) {
      throw new BadRequestException(
        `Mahsulot zaxirasi yetarli emas (id: ${productId})`,
      );
    }
  }

  /**
   * Market sozlamalari (minimal buyurtma + do'kon holati) — checkout'da
   * tekshiriladi. Qisqa TTL-kesh; xatoda OXIRGI ma'lum qiymat qaytariladi,
   * kesh umuman bo'lmasa `null` (cheklovsiz — FAIL-OPEN). Bu `getProduct`/
   * `getPickupLocation`dan ATAYLAB farqli: ular narx/zaxira xavfsizligi
   * uchun fail-CLOSED, lekin Market butunlay ishlamay qolsa checkout baribir
   * o'sha chaqiruvlar orqali to'xtaydi — shuning uchun bu yerda bitta
   * vaqtinchalik xato haqiqiy minimal-buyurtma qoidasini bekor qilib
   * qo'ymasligi muhimroq.
   */
  async getSettings(): Promise<MarketSettingsSnapshot | null> {
    if (
      this.settingsCache &&
      Date.now() - this.settingsCache.at < MarketClient.SETTINGS_TTL_MS
    ) {
      return this.settingsCache.settings;
    }
    if (!this.internalKey) return this.settingsCache?.settings ?? null;
    try {
      const res = await fetch(`${this.baseUrl}/api/v1/market/internal/settings`, {
        headers: { 'x-internal-key': this.internalKey },
        signal: AbortSignal.timeout(MarketClient.FETCH_TIMEOUT_MS),
      });
      if (!res.ok) return this.settingsCache?.settings ?? null;
      const json = (await res.json()) as { data: MarketSettingsSnapshot };
      const settings = json?.data ?? null;
      if (settings) this.settingsCache = { settings, at: Date.now() };
      return settings;
    } catch (err) {
      this.logger.warn(`Market sozlamalari olinmadi: ${(err as Error).message}`);
      return this.settingsCache?.settings ?? null;
    }
  }

  /** Bekor qilingan/o'zgartirilgan buyurtma uchun zaxirani qaytaradi (best-effort). */
  async releaseStock(productId: string, qty: number): Promise<void> {
    try {
      await fetch(
        `${this.baseUrl}/api/v1/market/internal/products/${productId}/release-stock`,
        {
          method: 'POST',
          headers: this.headers(true),
          body: JSON.stringify({ qty }),
          signal: AbortSignal.timeout(MarketClient.FETCH_TIMEOUT_MS),
        },
      );
    } catch (err) {
      this.logger.warn(`Zaxira qaytarishda xato: ${(err as Error).message}`);
    }
  }
}
