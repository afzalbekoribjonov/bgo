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

/**
 * Market servisidan (katalog) mahsulot/zaxira/pickup joy ma'lumotini oladi —
 * narx/nom SERVER tomonda aniqlanadi (mijoz yuborgan narxga ishonilmaydi).
 * `x-internal-key` bilan himoyalangan servislararo chaqiruvlar.
 */
@Injectable()
export class MarketClient {
  private readonly logger = new Logger(MarketClient.name);
  private readonly baseUrl: string;
  private readonly internalKey: string;
  /** Osilib qolgan ichki chaqiruv butun so'rovni cheksiz ushlab turmasin. */
  private static readonly FETCH_TIMEOUT_MS = 5_000;

  constructor(config: ConfigService) {
    this.baseUrl =
      config.get<string>('MARKET_SERVICE_URL') ?? 'http://localhost:4005';
    this.internalKey = config.get<string>('INTERNAL_API_KEY') ?? 'dev_internal_key';
  }

  private headers(json = false) {
    return {
      'x-internal-key': this.internalKey,
      ...(json ? { 'Content-Type': 'application/json' } : {}),
    };
  }

  async getProduct(id: string): Promise<MarketProductSnapshot> {
    let response: Response;
    try {
      response = await fetch(
        `${this.baseUrl}/api/v1/market/internal/products/${id}`,
        {
          headers: this.headers(),
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
    let response: Response;
    try {
      response = await fetch(
        `${this.baseUrl}/api/v1/market/internal/pickup-locations/${id}`,
        {
          headers: this.headers(),
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
