import { Controller, Get, Headers, Param, UseGuards } from '@nestjs/common';
import { AccessTokenPayload, CurrentUser, JwtAuthGuard, Roles, RolesGuard } from '@beshariq/nest-auth';
import { localeFromHeader } from '@beshariq/i18n';
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

  /**
   * "Mening oshxonam" — kirgan foydalanuvchi oshxona egasimi? Egasi bo'lsa
   * WebView panelga avtomatik kirish uchun token qaytaradi. ':id' dan OLDIN.
   * Rol talab qilinmaydi — egalik ownerUserId bo'yicha tekshiriladi.
   */
  @Get('my-kitchen')
  @UseGuards(JwtAuthGuard)
  async myKitchen(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.service.panelTokenForOwner(user.sub) };
  }

  /** Bosh ekran taomlar lentasi (barcha oshxonalardan). ':id' dan OLDIN. */
  @Get('dishes')
  async dishes(@Headers('accept-language') lang?: string) {
    return {
      success: true,
      data: await this.service.listPopularDishes(localeFromHeader(lang)),
    };
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
