import {
  Controller,
  ForbiddenException,
  Get,
  Headers,
  HttpCode,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AccessTokenPayload } from '../auth/jwt-payload.interface';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { RestaurantClient } from '../restaurant-client/restaurant.client';
import { OrdersService } from './orders.service';

/**
 * Oshxona paneli uchun buyurtma boshqaruvi (status oqimi).
 * plan/07-restaurant-app.md
 * 'restaurant' roli + EGALIK tekshiruvi (faqat o'z oshxonasi); admin bypass.
 */
@Controller('kitchen')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('restaurant', 'admin')
export class KitchenController {
  constructor(
    private readonly orders: OrdersService,
    private readonly restaurants: RestaurantClient,
  ) {}

  /** Oshxonaga kelgan buyurtmalar (faqat egasi). */
  @Get('restaurants/:restaurantId/orders')
  async list(
    @Param('restaurantId') restaurantId: string,
    @CurrentUser() user: AccessTokenPayload,
    @Headers('authorization') authHeader?: string,
  ) {
    await this.assertOwns(user, authHeader, restaurantId);
    return { success: true, data: await this.orders.listForRestaurant(restaurantId) };
  }

  @Post('orders/:id/accept')
  @HttpCode(200)
  async accept(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
    @Headers('authorization') authHeader?: string,
  ) {
    await this.assertOwnsOrder(user, authHeader, id);
    return { success: true, data: await this.orders.acceptByRestaurant(id) };
  }

  @Post('orders/:id/preparing')
  @HttpCode(200)
  async preparing(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
    @Headers('authorization') authHeader?: string,
  ) {
    await this.assertOwnsOrder(user, authHeader, id);
    return { success: true, data: await this.orders.startPreparing(id) };
  }

  @Post('orders/:id/ready')
  @HttpCode(200)
  async ready(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
    @Headers('authorization') authHeader?: string,
  ) {
    await this.assertOwnsOrder(user, authHeader, id);
    return { success: true, data: await this.orders.markReady(id) };
  }

  @Post('orders/:id/reject')
  @HttpCode(200)
  async reject(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
    @Headers('authorization') authHeader?: string,
  ) {
    await this.assertOwnsOrder(user, authHeader, id);
    return { success: true, data: await this.orders.rejectByRestaurant(id) };
  }

  /** Buyurtma orqali uning oshxonasi egaligini tekshiradi. */
  private async assertOwnsOrder(
    user: AccessTokenPayload,
    authHeader: string | undefined,
    orderId: string,
  ) {
    const restaurantId = await this.orders.restaurantIdOf(orderId);
    await this.assertOwns(user, authHeader, restaurantId);
  }

  /** Admin bypass; aks holda foydalanuvchi shu oshxona egasi bo'lishi shart. */
  private async assertOwns(
    user: AccessTokenPayload,
    authHeader: string | undefined,
    restaurantId: string,
  ) {
    if (user.roles?.includes('admin')) return;
    const token = authHeader?.replace(/^Bearer\s+/i, '') ?? '';
    const owned = await this.restaurants.getOwnedRestaurantIds(token);
    if (!owned.includes(restaurantId)) {
      throw new ForbiddenException('Bu oshxona sizga tegishli emas');
    }
  }
}
