import { Controller, Get, HttpCode, Param, Post } from '@nestjs/common';
import { OrdersService } from './orders.service';

/**
 * Oshxona paneli uchun buyurtma boshqaruvi (status oqimi).
 * plan/07-restaurant-app.md
 * TODO(restaurant auth): hozir ochiq (dev). Restaurant roli JWT + egalik
 * tekshiruvi restaurant_web auth ulanganda qo'shiladi.
 */
@Controller('kitchen')
export class KitchenController {
  constructor(private readonly orders: OrdersService) {}

  /** Oshxonaga kelgan buyurtmalar. */
  @Get('restaurants/:restaurantId/orders')
  async list(@Param('restaurantId') restaurantId: string) {
    return { success: true, data: await this.orders.listForRestaurant(restaurantId) };
  }

  @Post('orders/:id/accept')
  @HttpCode(200)
  async accept(@Param('id') id: string) {
    return { success: true, data: await this.orders.acceptByRestaurant(id) };
  }

  @Post('orders/:id/preparing')
  @HttpCode(200)
  async preparing(@Param('id') id: string) {
    return { success: true, data: await this.orders.startPreparing(id) };
  }

  @Post('orders/:id/ready')
  @HttpCode(200)
  async ready(@Param('id') id: string) {
    return { success: true, data: await this.orders.markReady(id) };
  }

  @Post('orders/:id/reject')
  @HttpCode(200)
  async reject(@Param('id') id: string) {
    return { success: true, data: await this.orders.rejectByRestaurant(id) };
  }
}
