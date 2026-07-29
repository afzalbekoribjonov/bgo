import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

interface TariffData {
  deliveryFee: number;
  foodCommissionPercent: number;
  taxiBaseFare: number;
  taxiPerKm: number;
  taxiMinFare: number;
  taxiWaitPerMin: number;
  taxiWaitFreeMin: number;
  taxiComfortPerKmExtra: number;
  taxiComfortBaseExtra: number;
  parcelBaseFare: number;
  parcelPerKm: number;
  parcelMinFare: number;
}

const FALLBACK_CONTEXT =
  "Narxlar masofa va tanlangan tarifga qarab avtomatik hisoblanadi; aniq narxni ilova ichidagi hisoblovchida ko'rishingiz mumkin.";

/**
 * services/order'dagi joriy tarifni o'qib, AI promptga qo'shiladigan qisqa
 * matn blokka aylantiradi. 60s kesh (UserInfoClient bilan bir xil naqsh).
 * Xato bo'lsa — raqamlarsiz, xavfsiz umumiy javob (hech qachon eskirgan
 * narx to'qib chiqarilmaydi).
 */
@Injectable()
export class TariffKnowledgeClient {
  private readonly logger = new Logger(TariffKnowledgeClient.name);
  private readonly baseUrl: string;
  private readonly key?: string;
  private cache?: { text: string; at: number };
  private static readonly TTL_MS = 60_000;
  /** Osilib qolgan ichki chaqiruv butun so'rovni cheksiz ushlab turmasin. */
  private static readonly FETCH_TIMEOUT_MS = 5_000;

  constructor(config: ConfigService) {
    this.baseUrl = config.get<string>('ORDER_SERVICE_URL') ?? 'http://localhost:4004';
    this.key = config.get<string>('INTERNAL_API_KEY');
  }

  async getPricingContext(): Promise<string> {
    if (this.cache && Date.now() - this.cache.at < TariffKnowledgeClient.TTL_MS) {
      return this.cache.text;
    }
    if (!this.key) return FALLBACK_CONTEXT;
    try {
      const res = await fetch(`${this.baseUrl}/api/v1/internal/tariff`, {
        headers: { 'x-internal-key': this.key },
        signal: AbortSignal.timeout(TariffKnowledgeClient.FETCH_TIMEOUT_MS),
      });
      if (!res.ok) return FALLBACK_CONTEXT;
      const json = (await res.json()) as { data: TariffData };
      const t = json?.data;
      if (!t) return FALLBACK_CONTEXT;
      const text = [
        `Ovqat yetkazib berish: ${t.deliveryFee} so'm.`,
        `Taksi: boshlang'ich narx ${t.taxiBaseFare} so'm, har km ${t.taxiPerKm} so'm, minimal narx ${t.taxiMinFare} so'm (${t.taxiWaitFreeMin} daqiqagacha kutish bepul, keyin daqiqasiga ${t.taxiWaitPerMin} so'm). Comfort tarifi qo'shimcha ${t.taxiComfortBaseExtra} so'm + har km ${t.taxiComfortPerKmExtra} so'm.`,
        `Pochta/dostavka: boshlang'ich narx ${t.parcelBaseFare} so'm, har km ${t.parcelPerKm} so'm, minimal narx ${t.parcelMinFare} so'm.`,
      ].join('\n');
      this.cache = { text, at: Date.now() };
      return text;
    } catch (err) {
      this.logger.warn(`Tarif ma'lumoti olinmadi: ${(err as Error).message}`);
      return FALLBACK_CONTEXT;
    }
  }
}
