import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard, Roles, RolesGuard } from '@beshariq/nest-auth';
import { CreateCategoryDto, UpdateCategoryDto } from './dto/category.dto';
import { UpdateMarketSettingsDto } from './dto/market-settings.dto';
import {
  CreatePickupLocationDto,
  UpdatePickupLocationDto,
} from './dto/pickup-location.dto';
import {
  AdjustStockDto,
  CreateProductDto,
  UpdateProductDto,
} from './dto/product.dto';
import { MarketService } from './market.service';

/** Market boshqaruvi — admin_web "Market" bo'limi. */
@Controller('market/admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
export class AdminController {
  constructor(private readonly service: MarketService) {}

  // ---- Kategoriyalar ----
  @Get('categories')
  async categories() {
    return { success: true, data: await this.service.listCategories() };
  }

  @Post('categories')
  async createCategory(@Body() dto: CreateCategoryDto) {
    return { success: true, data: await this.service.createCategory(dto) };
  }

  @Patch('categories/:id')
  async updateCategory(@Param('id') id: string, @Body() dto: UpdateCategoryDto) {
    return { success: true, data: await this.service.updateCategory(id, dto) };
  }

  @Delete('categories/:id')
  async deleteCategory(@Param('id') id: string) {
    return { success: true, data: await this.service.deleteCategory(id) };
  }

  // ---- Mahsulotlar ----
  @Get('products')
  async products(
    @Query('categoryId') categoryId?: string,
    @Query('q') q?: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return {
      success: true,
      data: await this.service.adminListProducts({
        categoryId,
        q,
        page: Math.max(1, Number(page) || 1),
        pageSize: Math.min(50, Math.max(1, Number(pageSize) || 20)),
      }),
    };
  }

  @Post('products')
  async createProduct(@Body() dto: CreateProductDto) {
    return { success: true, data: await this.service.createProduct(dto) };
  }

  @Patch('products/:id')
  async updateProduct(@Param('id') id: string, @Body() dto: UpdateProductDto) {
    return { success: true, data: await this.service.updateProduct(id, dto) };
  }

  @Patch('products/:id/stock')
  async adjustStock(@Param('id') id: string, @Body() dto: AdjustStockDto) {
    return { success: true, data: await this.service.adjustStock(id, dto) };
  }

  @Delete('products/:id')
  async deleteProduct(@Param('id') id: string) {
    return { success: true, data: await this.service.deleteProduct(id) };
  }

  // ---- Izohlar (moderatsiya) ----
  @Delete('comments/:id')
  async deleteComment(@Param('id') id: string) {
    return { success: true, data: await this.service.deleteComment(id) };
  }

  // ---- Sozlamalar (minimal buyurtma + do'kon holati) ----
  @Get('settings')
  async settings() {
    return { success: true, data: await this.service.getSettings() };
  }

  @Patch('settings')
  async updateSettings(@Body() dto: UpdateMarketSettingsDto) {
    return { success: true, data: await this.service.updateSettings(dto) };
  }

  // ---- Olib ketish joylari ----
  @Get('pickup-locations')
  async pickupLocations() {
    return { success: true, data: await this.service.listAllPickupLocations() };
  }

  @Post('pickup-locations')
  async createPickupLocation(@Body() dto: CreatePickupLocationDto) {
    return {
      success: true,
      data: await this.service.createPickupLocation(dto),
    };
  }

  @Patch('pickup-locations/:id')
  async updatePickupLocation(
    @Param('id') id: string,
    @Body() dto: UpdatePickupLocationDto,
  ) {
    return {
      success: true,
      data: await this.service.updatePickupLocation(id, dto),
    };
  }

  @Delete('pickup-locations/:id')
  async deletePickupLocation(@Param('id') id: string) {
    return {
      success: true,
      data: await this.service.deletePickupLocation(id),
    };
  }
}
