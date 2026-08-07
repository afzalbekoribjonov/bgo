import { Controller, Get, HttpCode, Param, Post, UseGuards } from '@nestjs/common';
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

  /**
   * Oshxona egasining userId'sini qaytaradi — order servisi yangi
   * buyurtmada egaga push-bildirishnoma yuborish uchun ishlatadi.
   * Ichki-only: ownerUserId hech qachon public/admin javoblarda ochilmaydi.
   */
  @Get(':id/owner')
  async owner(@Param('id') id: string) {
    const ownerUserId = await this.service.getOwnerUserId(id);
    return { ownerUserId };
  }
}
