import {
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface CatalogItem {
  name: string;
  price: number;
  isAvailable: boolean;
}

/** Oshxona joylashuvi (kuryer navigatsiyasi uchun — olib ketish nuqtasi). */
export interface RestaurantSummary {
  id: string;
  name: string;
  address: string;
  lat: number;
  lng: number;
}

/**
 * Restaurant servisidan menyuni oladi — narx/nom SERVER tomonda aniqlanadi
 * (mijoz yuborgan narxga ishonilmaydi). plan/10-auth-security.md
 */
@Injectable()
export class RestaurantClient {
  private readonly logger = new Logger(RestaurantClient.name);
  private readonly baseUrl: string;

  constructor(config: ConfigService) {
    this.baseUrl =
      config.get<string>('RESTAURANT_SERVICE_URL') ?? 'http://localhost:3003';
  }

  /** Oshxona menyusidagi taomlar (id -> {name, price, isAvailable}). */
  async getMenuItems(
    restaurantId: string,
    locale: string,
  ): Promise<Map<string, CatalogItem>> {
    const url = `${this.baseUrl}/api/v1/restaurants/${restaurantId}/menu`;
    let response: Response;
    try {
      response = await fetch(url, { headers: { 'Accept-Language': locale } });
    } catch (err) {
      this.logger.error(`Katalogga ulanib bo'lmadi: ${(err as Error).message}`);
      throw new ServiceUnavailableException('Katalog xizmati ishlamayapti');
    }

    if (response.status === 404) {
      throw new NotFoundException('Oshxona topilmadi');
    }
    if (!response.ok) {
      throw new ServiceUnavailableException('Katalog xizmati xato qaytardi');
    }

    const body = (await response.json()) as {
      data: { categories: { items: Array<CatalogItem & { id: string }> }[] };
    };

    const map = new Map<string, CatalogItem>();
    for (const category of body.data.categories) {
      for (const item of category.items) {
        map.set(item.id, {
          name: item.name,
          price: item.price,
          isAvailable: item.isAvailable,
        });
      }
    }
    return map;
  }

  /**
   * Barcha faol oshxonalar joylashuvi (id -> {name, address, lat, lng}).
   * Kuryer buyurtmalarini "olib ketish nuqtasi" bilan boyitish uchun — bitta
   * so'rov (N+1 emas). Xato bo'lsa bo'sh map (navigatsiya degradatsiya qiladi).
   */
  async getRestaurantDirectory(): Promise<Map<string, RestaurantSummary>> {
    const url = `${this.baseUrl}/api/v1/restaurants`;
    const map = new Map<string, RestaurantSummary>();
    try {
      const response = await fetch(url);
      if (!response.ok) return map;
      const body = (await response.json()) as {
        data: Array<{
          id: string;
          name: string;
          address: string;
          lat: number;
          lng: number;
        }>;
      };
      for (const r of body.data ?? []) {
        map.set(r.id, {
          id: r.id,
          name: r.name,
          address: r.address,
          lat: r.lat,
          lng: r.lng,
        });
      }
    } catch (err) {
      this.logger.warn(
        `Oshxona katalogini olishda xato (navigatsiya bo'sh): ${(err as Error).message}`,
      );
    }
    return map;
  }

  /**
   * Joriy foydalanuvchi (restaurant roli) egalik qiladigan oshxona id'lari.
   * Token forward qilinadi — restaurant servisi GET /restaurants/mine.
   */
  async getOwnedRestaurantIds(token: string): Promise<string[]> {
    const url = `${this.baseUrl}/api/v1/restaurants/mine`;
    let response: Response;
    try {
      response = await fetch(url, {
        headers: { Authorization: `Bearer ${token}` },
      });
    } catch (err) {
      this.logger.error(`Egalik so'rovida xato: ${(err as Error).message}`);
      throw new ServiceUnavailableException('Katalog xizmati ishlamayapti');
    }
    if (!response.ok) {
      throw new ServiceUnavailableException(
        "Oshxona egaligini aniqlab bo'lmadi",
      );
    }
    const body = (await response.json()) as { data: Array<{ id: string }> };
    return (body.data ?? []).map((r) => r.id);
  }
}
