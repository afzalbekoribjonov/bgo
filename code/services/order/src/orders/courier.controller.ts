import { Controller, Get, HttpCode, Param, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AccessTokenPayload } from '../auth/jwt-payload.interface';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { OrdersService } from './orders.service';

/**
 * Haydovchi (kuryer) yetkazib berish boshqaruvi. plan/06-driver-app.md
 * Faqat 'driver' roli; driverId token (JWT sub) dan olinadi.
 */
@Controller('courier')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('driver')
export class CourierController {
  constructor(private readonly orders: OrdersService) {}

  /** Yetkazishga tayyor (READY), hali biriktirilmagan buyurtmalar. */
  @Get('available')
  async available() {
    return { success: true, data: await this.orders.listAvailableForDelivery() };
  }

  /** Haydovchining o'z buyurtmalari. */
  @Get('my-orders')
  async myOrders(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.orders.listDriverOrders(user.sub) };
  }

  @Post('orders/:id/accept')
  @HttpCode(200)
  async accept(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.orders.acceptDelivery(id, user.sub) };
  }

  @Post('orders/:id/pickup')
  @HttpCode(200)
  async pickup(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.orders.pickup(id, user.sub) };
  }

  @Post('orders/:id/delivered')
  @HttpCode(200)
  async delivered(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.orders.delivered(id, user.sub) };
  }
}
