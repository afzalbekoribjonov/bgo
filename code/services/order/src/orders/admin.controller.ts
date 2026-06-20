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
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { OrdersService } from './orders.service';

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
