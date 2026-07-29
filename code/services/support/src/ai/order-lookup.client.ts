import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface OrderLookupResult {
  type: 'FOOD' | 'TAXI' | 'PARCEL';
  customerId: string;
}

/**
 * services/order'dan haydovchi+buyurtma raqami bo'yicha mijozni topadi —
 * haydovchi AI'ga shikoyat qilganda buyurtma raqamini aytsa, qaysi mijoz
 * haqida gap ketayotganini aniqlash uchun. TariffKnowledgeClient bilan bir
 * xil "thin client, hech qachon throw qilmaydi" naqshi.
 */
@Injectable()
export class OrderLookupClient {
  private readonly logger = new Logger(OrderLookupClient.name);
  private readonly baseUrl: string;
  private readonly key?: string;

  constructor(config: ConfigService) {
    this.baseUrl = config.get<string>('ORDER_SERVICE_URL') ?? 'http://localhost:4004';
    this.key = config.get<string>('INTERNAL_API_KEY');
  }

  async lookupByDriver(
    driverUserId: string,
    publicNo: number,
  ): Promise<OrderLookupResult | null> {
    if (!this.key || !driverUserId || !Number.isFinite(publicNo)) return null;
    try {
      const res = await fetch(
        `${this.baseUrl}/api/v1/internal/orders/lookup-by-driver?driverUserId=${encodeURIComponent(driverUserId)}&publicNo=${publicNo}`,
        { headers: { 'x-internal-key': this.key } },
      );
      if (!res.ok) return null;
      const json = (await res.json()) as { data: OrderLookupResult | null };
      return json?.data ?? null;
    } catch (err) {
      this.logger.warn(`Buyurtma qidiruvi muvaffaqiyatsiz: ${(err as Error).message}`);
      return null;
    }
  }
}
