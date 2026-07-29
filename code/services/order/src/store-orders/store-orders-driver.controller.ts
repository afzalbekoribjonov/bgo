import { Controller, Get, HttpCode, Param, Post, UseGuards } from '@nestjs/common';
import { AccessTokenPayload, CurrentUser, JwtAuthGuard, Roles, RolesGuard } from '@beshariq/nest-auth';
import { StoreOrdersService } from './store-orders.service';

/**
 * Haydovchi — Market yetkazish oqimi (faqat DELIVERY buyurtmalar).
 * Faqat 'driver' roli; driverId token (JWT sub) dan olinadi.
 */
@Controller('store/driver')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('driver')
export class StoreOrdersDriverController {
  constructor(private readonly service: StoreOrdersService) {}

  @Get('available')
  async available() {
    return { success: true, data: await this.service.listAvailable() };
  }

  @Get('my-orders')
  async myOrders(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.service.listDriverOrders(user.sub) };
  }

  /** Faol buyurtmalar (jonli) — ilova qayta ochilganda tiklash. */
  @Get('orders')
  async activeOrders(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.service.listActiveDriverOrders(user.sub) };
  }

  @Get('orders/:id')
  async detail(@Param('id') id: string, @CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.service.liveForDriver(user.sub, id) };
  }

  @Post('orders/:id/accept')
  @HttpCode(200)
  async accept(@Param('id') id: string, @CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.service.accept(id, user.sub) };
  }

  @Post('orders/:id/arrive')
  @HttpCode(200)
  async arrive(@Param('id') id: string, @CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.service.arrive(id, user.sub) };
  }

  @Post('orders/:id/pickup')
  @HttpCode(200)
  async pickup(@Param('id') id: string, @CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.service.pickup(id, user.sub) };
  }

  @Post('orders/:id/transit')
  @HttpCode(200)
  async transit(@Param('id') id: string, @CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.service.startTransit(id, user.sub) };
  }

  @Post('orders/:id/delivered')
  @HttpCode(200)
  async delivered(@Param('id') id: string, @CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.service.delivered(id, user.sub) };
  }

  @Post('orders/:id/cancel')
  @HttpCode(200)
  async cancel(@Param('id') id: string, @CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.service.driverCancel(id, user.sub) };
  }

  @Get('earnings')
  async earnings(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.service.driverEarnings(user.sub) };
  }
}
