import { Controller, Get, Query } from '@nestjs/common';
import { OrdersService } from './orders.service';

/**
 * Admin / hisobot endpointlari (buyurtmalar bo'yicha). plan/08-admin-workspace.md
 * TODO(admin auth): hozir ochiq (dev). Admin roli JWT + Reporting servisi keyin.
 */
@Controller('admin')
export class AdminController {
  constructor(private readonly orders: OrdersService) {}

  @Get('stats')
  async stats() {
    return { success: true, data: await this.orders.adminStats() };
  }

  @Get('orders')
  async list(
    @Query('status') status?: string,
    @Query('type') type?: string,
  ) {
    return {
      success: true,
      data: await this.orders.adminListOrders({ status, type }),
    };
  }
}
