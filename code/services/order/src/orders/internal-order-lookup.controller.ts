import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { InternalKeyGuard } from '@beshariq/nest-auth';
import { OrdersService } from './orders.service';

/**
 * Servislararo (internal) endpoint — services/support AI shikoyat funksiyasi
 * haydovchi aytgan buyurtma raqamidan mijozni aniqlash uchun so'raydi.
 * x-internal-key bilan himoyalangan — @beshariq/nest-auth guard'i.
 */
@Controller('internal/orders')
@UseGuards(InternalKeyGuard)
export class InternalOrderLookupController {
  constructor(private readonly orders: OrdersService) {}

  @Get('lookup-by-driver')
  async lookup(
    @Query('driverUserId') driverUserId: string,
    @Query('publicNo') publicNo: string,
  ) {
    const no = Number(publicNo);
    if (!driverUserId || !Number.isFinite(no)) {
      return { success: true, data: null };
    }
    return {
      success: true,
      data: await this.orders.lookupByDriverAndPublicNo(driverUserId, no),
    };
  }

  /**
   * Restoran servisi oshxonani o'chirishdan oldin so'raydi — hali yakunlanmagan
   * buyurtmalar bo'lsa, o'chirish bloklanadi.
   */
  @Get('restaurant/:restaurantId/active-count')
  async activeCount(@Param('restaurantId') restaurantId: string) {
    return {
      success: true,
      data: { count: await this.orders.activeOrderCountForRestaurant(restaurantId) },
    };
  }
}
