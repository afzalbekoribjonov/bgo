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
}
