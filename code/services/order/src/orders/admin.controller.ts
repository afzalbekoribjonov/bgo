import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
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

  /** Ixtiyoriy sana oralig'i hisoboti: ?from=YYYY-MM-DD&to=YYYY-MM-DD (istalgan kun/oy). */
  @Get('reports/range')
  async reportsRange(@Query('from') from?: string, @Query('to') to?: string) {
    const today = new Date().toISOString().slice(0, 10);
    const f = from && /^\d{4}-\d{2}-\d{2}$/.test(from) ? from : today;
    const t = to && /^\d{4}-\d{2}-\d{2}$/.test(to) ? to : today;
    return { success: true, data: await this.orders.adminReportRange(f, t) };
  }

  /** Bitta buyurtmaning to'liq holati (alohida sahifa): ?type=FOOD|TAXI|PARCEL. */
  @Get('orders/:id/detail')
  async orderDetail(@Param('id') id: string, @Query('type') type?: string) {
    const valid = ['FOOD', 'TAXI', 'PARCEL'];
    const t = valid.includes(type ?? '') ? (type as 'FOOD' | 'TAXI' | 'PARCEL') : 'FOOD';
    return { success: true, data: await this.orders.adminOrderDetail(id, t) };
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
    @Query('driverId') driverId?: string,
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
        driverId,
      }),
    };
  }

  /** Jonli xarita: online haydovchilar (joylashuv + yo'nalish + bandlik). */
  @Get('live-drivers')
  async liveDrivers() {
    return { success: true, data: await this.orders.adminLiveDrivers() };
  }

  /** "Shubhali haydovchilar" — real bo'lmagan tezlikda/bir zumda yakunlangan safarlar. */
  @Get('suspicious-drivers')
  async suspiciousDrivers() {
    return { success: true, data: await this.orders.adminSuspiciousTrips() };
  }

  /** Haydovchi buyurtmalar tarixi (uchala vertikal). */
  @Get('drivers/:id/history')
  async driverHistory(@Param('id') id: string) {
    return { success: true, data: await this.orders.adminDriverHistory(id) };
  }

  /** Haydovchi statistikasi — daromad + platforma foydasi. ?period=today|week|month|all. */
  @Get('drivers/:id/stats')
  async driverStats(
    @Param('id') id: string,
    @Query('period') period?: string,
  ) {
    const valid: (ReportPeriod | 'all')[] = ['today', 'week', 'month', 'all'];
    const p = valid.includes(period as ReportPeriod) ? (period as ReportPeriod | 'all') : 'today';
    return { success: true, data: await this.orders.adminDriverStats(id, p) };
  }

  /** Admin: buyurtmani majburiy bekor qilish. */
  @Post('orders/:id/cancel')
  @HttpCode(200)
  async cancelOrder(@Param('id') id: string) {
    return { success: true, data: await this.orders.adminCancelById(id) };
  }
}
