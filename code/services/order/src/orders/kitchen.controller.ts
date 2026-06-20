import {
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { OrdersService } from './orders.service';

/**
 * Oshxona paneli uchun buyurtma boshqaruvi (status oqimi).
 * plan/07-restaurant-app.md
 * Faqat 'restaurant' roli. TODO: oshxona egalik tekshiruvi.
 */
@Controller('kitchen')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('restaurant')
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
