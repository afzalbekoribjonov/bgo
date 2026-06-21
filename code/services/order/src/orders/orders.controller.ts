import {
  Body,
  Controller,
  Get,
  Headers,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AccessTokenPayload, CurrentUser, JwtAuthGuard } from '@beshariq/nest-auth';
import { CreateOrderDto } from './dto/create-order.dto';
import { OrdersService } from './orders.service';

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

  @Get(':id')
  async getOne(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
  ) {
    return { success: true, data: await this.orders.getOwned(user.sub, id) };
  }

  @Post(':id/cancel')
  async cancel(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
  ) {
    return { success: true, data: await this.orders.cancel(user.sub, id) };
  }
}
