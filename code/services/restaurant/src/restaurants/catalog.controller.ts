import { Controller, Get, Headers, Param, UseGuards } from '@nestjs/common';
import { AccessTokenPayload, CurrentUser, JwtAuthGuard, Roles, RolesGuard } from '@beshariq/nest-auth';
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

  /** Joriy foydalanuvchining oshxonalari (restaurant roli). ':id' dan OLDIN. */
  @Get('mine')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('restaurant')
  async mine(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.service.listForOwner(user.sub) };
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
