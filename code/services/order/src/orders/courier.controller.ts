import { Body, Controller, Get, HttpCode, Param, Post } from '@nestjs/common';
import { DriverActionDto } from './dto/driver-action.dto';
import { OrdersService } from './orders.service';

/**
 * Haydovchi (kuryer) uchun yetkazib berish boshqaruvi.
 * plan/06-driver-app.md
 * TODO(driver auth): hozir ochiq (dev), driverId body'da. Driver roli JWT
 * ulanganda guard + sub'dan driverId.
 */
@Controller('courier')
export class CourierController {
  constructor(private readonly orders: OrdersService) {}

  /** Yetkazishga tayyor (READY), hali biriktirilmagan buyurtmalar. */
  @Get('available')
  async available() {
    return { success: true, data: await this.orders.listAvailableForDelivery() };
  }

  /** Haydovchining buyurtmalari. */
  @Get('drivers/:driverId/orders')
  async driverOrders(@Param('driverId') driverId: string) {
    return { success: true, data: await this.orders.listDriverOrders(driverId) };
  }

  @Post('orders/:id/accept')
  @HttpCode(200)
  async accept(@Param('id') id: string, @Body() dto: DriverActionDto) {
    return { success: true, data: await this.orders.acceptDelivery(id, dto.driverId) };
  }

  @Post('orders/:id/pickup')
  @HttpCode(200)
  async pickup(@Param('id') id: string, @Body() dto: DriverActionDto) {
    return { success: true, data: await this.orders.pickup(id, dto.driverId) };
  }

  @Post('orders/:id/delivered')
  @HttpCode(200)
  async delivered(@Param('id') id: string, @Body() dto: DriverActionDto) {
    return { success: true, data: await this.orders.delivered(id, dto.driverId) };
  }
}
