import { Controller, ForbiddenException, Get, Headers, Query } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OrdersService } from './orders.service';

/**
 * Servislararo (internal) endpoint — services/support AI shikoyat funksiyasi
 * haydovchi aytgan buyurtma raqamidan mijozni aniqlash uchun so'raydi.
 * x-internal-key bilan himoyalangan, boshqa internal controller'lar bilan
 * bir xil naqsh.
 */
@Controller('internal/orders')
export class InternalOrderLookupController {
  constructor(
    private readonly orders: OrdersService,
    private readonly config: ConfigService,
  ) {}

  private checkKey(key?: string): void {
    const expected = this.config.get<string>('INTERNAL_API_KEY') ?? 'dev_internal_key';
    if (key !== expected) throw new ForbiddenException("Internal kalit noto'g'ri");
  }

  @Get('lookup-by-driver')
  async lookup(
    @Query('driverUserId') driverUserId: string,
    @Query('publicNo') publicNo: string,
    @Headers('x-internal-key') key?: string,
  ) {
    this.checkKey(key);
    const no = Number(publicNo);
    if (!driverUserId || !Number.isFinite(no)) {
      return { success: true, data: null };
    }
    return {
      success: true,
      data: await this.orders.lookupByDriverAndPublicNo(driverUserId, no),
    };
  }
}
