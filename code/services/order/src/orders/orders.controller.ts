import {
  Body,
  Controller,
  Get,
  Headers,
  HttpCode,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';
import { AccessTokenPayload, CurrentUser, JwtAuthGuard } from '@beshariq/nest-auth';
import { CreateOrderDto, PromoCheckDto } from './dto/create-order.dto';
import { OrdersService } from './orders.service';

class RateOrderDto {
  @IsInt()
  @Min(1)
  @Max(5)
  rating!: number;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  comment?: string;
}

function localeFromHeader(header?: string): string {
  if (!header) return 'uz';
  const value = header.split(',')[0].trim();
  if (value === 'uz-Cyrl' || value === 'uz_Cyrl') return 'uz-Cyrl';
  if (value.startsWith('ru')) return 'ru';
  return 'uz';
}

@Controller('orders')
@UseGuards(JwtAuthGuard)
export class OrdersController {
  constructor(private readonly orders: OrdersService) {}

  @Post()
  async create(
    @CurrentUser() user: AccessTokenPayload,
    @Body() dto: CreateOrderDto,
    @Headers('accept-language') lang?: string,
  ) {
    const order = await this.orders.create(user.sub, dto, localeFromHeader(lang));
    return { success: true, data: order };
  }

  @Get()
  async listMine(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.orders.listMine(user.sub) };
  }

  /** Ovqat narx-konfiguratsiyasi (ustama + yetkazish). */
  @Get('food-config')
  async foodConfig() {
    return { success: true, data: await this.orders.foodConfig() };
  }

  /**
   * Promokodni buyurtmadan OLDIN tekshirish — {code, discount} qaytaradi,
   * yaroqsiz bo'lsa 400 + sabab (checkout "Tekshirish" tugmasi uchun).
   */
  @Post('promo-check')
  @HttpCode(200)
  async promoCheck(@Body() dto: PromoCheckDto) {
    return {
      success: true,
      data: await this.orders.promoCheck(dto.code, dto.itemsTotal),
    };
  }

  @Get(':id')
  async getOne(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
  ) {
    return { success: true, data: await this.orders.getOwned(user.sub, id) };
  }

  /** Jonli buyurtma — oshxona joylashuvi + kuryer + kuryer joylashuvi. */
  @Get(':id/live')
  async live(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
  ) {
    return { success: true, data: await this.orders.getOwnedLive(user.sub, id) };
  }

  /** Biriktirilgan kuryerning jonli joylashuvi. */
  @Get(':id/driver')
  async driver(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
  ) {
    return {
      success: true,
      data: await this.orders.driverLocationForOrder(user.sub, id),
    };
  }

  /** Yetkazilgan buyurtmani baholash. */
  @Post(':id/rate')
  @HttpCode(200)
  async rate(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
    @Body() dto: RateOrderDto,
  ) {
    return {
      success: true,
      data: await this.orders.rate(user.sub, id, dto.rating, dto.comment),
    };
  }

  @Post(':id/cancel')
  async cancel(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
  ) {
    return { success: true, data: await this.orders.cancel(user.sub, id) };
  }
}
