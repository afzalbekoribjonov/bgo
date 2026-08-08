import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * Order servisidan restoranning hali yakunlanmagan buyurtmalari sonini
 * so'raydi — oshxonani o'chirishdan oldin xavfsizlik tekshiruvi uchun.
 *
 * Boshqa `*-client`lardan farqli, ATAYLAB FAIL-CLOSED: order servisi bilan
 * aloqa bo'lmasa/xato bo'lsa `null` qaytadi va chaqiruvchi buni "noma'lum —
 * o'chirish xavfli" deb talqin qilib, o'chirishni bloklaydi. Bu — destruktiv
 * (qaytarib bo'lmaydigan) amal, shuning uchun loyihaning odatiy fail-open
 * siyosatidan ataylab chetga chiqadi.
 */
@Injectable()
export class OrderClient {
  private readonly logger = new Logger(OrderClient.name);
  private readonly baseUrl: string;
  private readonly key?: string;
  private static readonly FETCH_TIMEOUT_MS = 5_000;

  constructor(config: ConfigService) {
    this.baseUrl = config.get<string>('ORDER_SERVICE_URL') ?? 'http://localhost:4004';
    this.key = config.get<string>('INTERNAL_API_KEY');
  }

  /** Hali yakunlanmagan buyurtmalar soni. Xatoda/kalitsiz `null`. */
  async getActiveOrderCount(restaurantId: string): Promise<number | null> {
    if (!this.key) return null;
    try {
      const res = await fetch(
        `${this.baseUrl}/api/v1/internal/orders/restaurant/${encodeURIComponent(restaurantId)}/active-count`,
        {
          headers: { 'x-internal-key': this.key },
          signal: AbortSignal.timeout(OrderClient.FETCH_TIMEOUT_MS),
        },
      );
      if (!res.ok) return null;
      const json = (await res.json()) as { data: { count: number } };
      return json?.data?.count ?? null;
    } catch (err) {
      this.logger.warn(`Faol buyurtmalar soni olinmadi: ${(err as Error).message}`);
      return null;
    }
  }
}
