import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  Headers,
  HttpCode,
  Param,
  Post,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MarketService } from './market.service';

/**
 * Servislararo (internal) endpointlar — order servisi (store-orders, Faza A1)
 * buyurtma yaratishda narx/zaxira snapshotini oladi va zaxirani band qiladi.
 * x-internal-key bilan himoyalangan (JWT emas).
 */
@Controller('market/internal')
export class InternalController {
  constructor(
    private readonly service: MarketService,
    private readonly config: ConfigService,
  ) {}

  private checkKey(key?: string): void {
    const expected = this.config.get<string>('INTERNAL_API_KEY') ?? 'dev_internal_key';
    if (key !== expected) throw new ForbiddenException("Internal kalit noto'g'ri");
  }

  @Get('products/:id')
  async product(@Param('id') id: string, @Headers('x-internal-key') key?: string) {
    this.checkKey(key);
    return { success: true, data: await this.service.internalGetProduct(id) };
  }

  @Get('pickup-locations/:id')
  async pickupLocation(
    @Param('id') id: string,
    @Headers('x-internal-key') key?: string,
  ) {
    this.checkKey(key);
    return {
      success: true,
      data: await this.service.internalGetPickupLocation(id),
    };
  }

  @Post('products/:id/reserve-stock')
  @HttpCode(200)
  async reserve(
    @Param('id') id: string,
    @Body('qty') qty: number,
    @Headers('x-internal-key') key?: string,
  ) {
    this.checkKey(key);
    return {
      success: true,
      data: await this.service.internalReserveStock(id, qty),
    };
  }

  @Post('products/:id/release-stock')
  @HttpCode(200)
  async release(
    @Param('id') id: string,
    @Body('qty') qty: number,
    @Headers('x-internal-key') key?: string,
  ) {
    this.checkKey(key);
    return {
      success: true,
      data: await this.service.internalReleaseStock(id, qty),
    };
  }
}
