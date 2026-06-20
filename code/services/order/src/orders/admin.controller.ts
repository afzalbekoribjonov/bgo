import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { OrdersService } from './orders.service';

/**
 * Admin / hisobot endpointlari (buyurtmalar bo'yicha). plan/08-admin-workspace.md
 * Faqat 'admin' roli. TODO: alohida Reporting servisi keyin.
 */
@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
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
