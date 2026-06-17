import { Controller, Get, Headers, Param } from '@nestjs/common';
import { localeFromHeader } from '../common/i18n';
import { RestaurantsService } from './restaurants.service';

/** Public katalog (mijoz ilovasi uchun). plan/05-customer-app.md */
@Controller('restaurants')
export class CatalogController {
  constructor(private readonly service: RestaurantsService) {}

  @Get()
  async list() {
    return { success: true, data: await this.service.listPublicRestaurants() };
  }

  @Get(':id')
  async detail(@Param('id') id: string) {
    return { success: true, data: await this.service.getPublicRestaurant(id) };
  }

  @Get(':id/menu')
  async menu(
    @Param('id') id: string,
    @Headers('accept-language') lang?: string,
  ) {
    const data = await this.service.getMenu(id, localeFromHeader(lang));
    return { success: true, data };
  }
}
