import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { InternalKeyGuard } from '@beshariq/nest-auth';
import { MarketService } from './market.service';

/**
 * Servislararo (internal) endpointlar — order servisi (store-orders, Faza A1)
 * buyurtma yaratishda narx/zaxira snapshotini oladi va zaxirani band qiladi.
 * x-internal-key bilan himoyalangan (JWT emas) — @beshariq/nest-auth guard'i.
 */
@Controller('market/internal')
@UseGuards(InternalKeyGuard)
export class InternalController {
  constructor(private readonly service: MarketService) {}

  @Get('products/:id')
  async product(@Param('id') id: string) {
    return { success: true, data: await this.service.internalGetProduct(id) };
  }

  @Get('pickup-locations/:id')
  async pickupLocation(@Param('id') id: string) {
    return {
      success: true,
      data: await this.service.internalGetPickupLocation(id),
    };
  }

  @Get('settings')
  async settings() {
    return { success: true, data: await this.service.getSettings() };
  }

  @Post('products/:id/reserve-stock')
  @HttpCode(200)
  async reserve(@Param('id') id: string, @Body('qty') qty: number) {
    return {
      success: true,
      data: await this.service.internalReserveStock(id, qty),
    };
  }

  @Post('products/:id/release-stock')
  @HttpCode(200)
  async release(@Param('id') id: string, @Body('qty') qty: number) {
    return {
      success: true,
      data: await this.service.internalReleaseStock(id, qty),
    };
  }
}
