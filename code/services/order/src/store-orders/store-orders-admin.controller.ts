import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { IsIn } from 'class-validator';
import { JwtAuthGuard, Roles, RolesGuard } from '@beshariq/nest-auth';
import { ReportPeriod } from '../common/reporting';
import { StoreOrderStatus } from './entities';
import { StoreOrdersService } from './store-orders.service';

const STORE_ORDER_STATUSES: StoreOrderStatus[] = [
  'PENDING',
  'ACCEPTED',
  'ARRIVED',
  'PICKED_UP',
  'IN_TRANSIT',
  'DELIVERED',
  'PREPARING',
  'READY_FOR_PICKUP',
  'COMPLETED',
  'CANCELLED',
];

class SetStoreOrderStatusDto {
  @IsIn(STORE_ORDER_STATUSES)
  status!: StoreOrderStatus;
}

/** Admin — Market buyurtmalari boshqaruvi (admin_web "Market" bo'limi). */
@Controller('store/admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
export class StoreOrdersAdminController {
  constructor(private readonly service: StoreOrdersService) {}

  @Get('orders')
  async list(
    @Query('status') status?: string,
    @Query('deliveryMethod') deliveryMethod?: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('q') q?: string,
    @Query('overduePickup') overduePickup?: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return {
      success: true,
      data: await this.service.adminListOrders({
        status,
        deliveryMethod,
        from,
        to,
        q,
        overduePickup: overduePickup === 'true',
        page: Math.max(1, Number(page) || 1),
        pageSize: Math.min(100, Math.max(1, Number(pageSize) || 20)),
      }),
    };
  }

  @Get('orders/:id')
  async detail(@Param('id') id: string) {
    return { success: true, data: await this.service.adminGetById(id) };
  }

  /** PICKUP buyurtmani mijoz olib ketganda staff yakunlaydi. */
  @Post('orders/:id/complete-pickup')
  @HttpCode(200)
  async completePickup(@Param('id') id: string) {
    return { success: true, data: await this.service.adminCompletePickup(id) };
  }

  /** Holatni qo'lda o'zgartirish — faqat ruxsat etilgan o'tishlar (server tekshiradi). */
  @Post('orders/:id/status')
  @HttpCode(200)
  async setStatus(@Param('id') id: string, @Body() dto: SetStoreOrderStatusDto) {
    return {
      success: true,
      data: await this.service.adminSetStatus(id, dto.status),
    };
  }

  @Post('orders/:id/cancel')
  @HttpCode(200)
  async cancel(@Param('id') id: string) {
    return { success: true, data: await this.service.adminCancel(id) };
  }

  @Get('report')
  async report(@Query('period') period: ReportPeriod = 'today') {
    return { success: true, data: await this.service.adminReport(period) };
  }

  @Get('stats')
  async stats() {
    return { success: true, data: await this.service.adminStats() };
  }
}
