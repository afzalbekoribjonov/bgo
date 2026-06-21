import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { TariffService } from '../tariff/tariff.service';
import { UpdateTariffDto } from '../tariff/dto/update-tariff.dto';
import { PromoService } from '../promo/promo.service';
import { CreatePromoDto, UpdatePromoDto } from '../promo/dto/promo.dto';
import { JwtAuthGuard, Roles, RolesGuard } from '@beshariq/nest-auth';
import { OrdersService, ReportPeriod } from './orders.service';

/**
 * Admin / hisobot endpointlari (buyurtmalar + tarif). plan/08-admin-workspace.md
 * Faqat 'admin' roli. TODO: alohida Reporting/Pricing servisi keyin.
 */
@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
export class AdminController {
  constructor(
    private readonly orders: OrdersService,
    private readonly tariff: TariffService,
    private readonly promo: PromoService,
  ) {}

  @Get('tariff')
  async getTariff() {
    return { success: true, data: await this.tariff.getTariff() };
  }

  @Put('tariff')
  async updateTariff(@Body() dto: UpdateTariffDto) {
    return { success: true, data: await this.tariff.updateTariff(dto) };
  }

  // ----- Promokodlar -----

  @Get('promos')
  async listPromos() {
    return { success: true, data: await this.promo.list() };
  }

  @Post('promos')
  async createPromo(@Body() dto: CreatePromoDto) {
    return { success: true, data: await this.promo.create(dto) };
  }

  @Patch('promos/:id')
  async updatePromo(@Param('id') id: string, @Body() dto: UpdatePromoDto) {
    return { success: true, data: await this.promo.update(id, dto) };
  }

  @Delete('promos/:id')
  async removePromo(@Param('id') id: string) {
    await this.promo.remove(id);
    return { success: true };
  }

  @Get('stats')
  async stats() {
    return { success: true, data: await this.orders.adminStats() };
  }

  /** Davr hisoboti: ?period=today|week|month (standart: today). */
  @Get('reports')
  async reports(@Query('period') period?: string) {
    const valid: ReportPeriod[] = ['today', 'week', 'month'];
    const p = valid.includes(period as ReportPeriod)
      ? (period as ReportPeriod)
      : 'today';
    return { success: true, data: await this.orders.adminReport(p) };
  }

  @Get('orders')
  async list(
    @Query('status') status?: string,
    @Query('type') type?: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('q') q?: string,
    @Query('sort') sort?: string,
    @Query('order') order?: string,
  ) {
    return {
      success: true,
      data: await this.orders.adminListOrders({
        status,
        type,
        from,
        to,
        q,
        sort: sort === 'total' ? 'total' : 'createdAt',
        order: order === 'asc' ? 'asc' : 'desc',
      }),
    };
  }
}
