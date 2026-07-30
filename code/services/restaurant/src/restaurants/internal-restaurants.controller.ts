import { Controller, HttpCode, Param, Post, UseGuards } from '@nestjs/common';
import { InternalKeyGuard } from '@beshariq/nest-auth';
import { RestaurantsService } from './restaurants.service';

/**
 * Servislararo (internal) endpoint — order servisi buyurtma bekor bo'lganda
 * oshxonani faolsiz qiladi. x-internal-key bilan himoyalangan (JWT emas)
 * — @beshariq/nest-auth guard'i.
 */
@Controller('internal/restaurants')
@UseGuards(InternalKeyGuard)
export class InternalRestaurantsController {
  constructor(private readonly service: RestaurantsService) {}

  /** Oshxonani faolsiz (isOpen=false) qiladi. */
  @Post(':id/inactive')
  @HttpCode(200)
  async inactive(@Param('id') id: string) {
    await this.service.setOpen(id, false);
    return { success: true };
  }
}
