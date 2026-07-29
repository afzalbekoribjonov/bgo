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
import { SellerType } from '../../prisma/generated/client';
import { CreateCategoryDto, UpdateCategoryDto } from './dto/category.dto';
import { CreateSellerDto, UpdateSellerDto } from './dto/seller.dto';
import { MarketplaceService } from './marketplace.service';

function toSellerType(value?: string): SellerType | undefined {
  return value === 'SHOP' || value === 'CONSTRUCTION' ? value : undefined;
}

/** Marketplace boshqaruvi — admin_web "Sotuvchilar" bo'limi. */
@Controller('marketplace/admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
export class AdminController {
  constructor(private readonly service: MarketplaceService) {}

  // ---- Sotuvchilar ----
  @Get('sellers')
  async sellers(@Query('sellerType') sellerType?: string) {
    return {
      success: true,
      data: await this.service.adminListSellers(toSellerType(sellerType)),
    };
  }

  @Post('sellers')
  async createSeller(@Body() dto: CreateSellerDto) {
    return { success: true, data: await this.service.createSeller(dto) };
  }

  @Patch('sellers/:id')
  async updateSeller(@Param('id') id: string, @Body() dto: UpdateSellerDto) {
    return { success: true, data: await this.service.updateSeller(id, dto) };
  }

  @Delete('sellers/:id')
  async deleteSeller(@Param('id') id: string) {
    return { success: true, data: await this.service.deleteSeller(id) };
  }

  // ---- Kategoriyalar ----
  @Get('categories')
  async categories(@Query('sellerType') sellerType?: string) {
    return {
      success: true,
      data: await this.service.listCategories(toSellerType(sellerType)),
    };
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

  // ---- Mahsulot moderatsiyasi ----
  @Get('products')
  async products(@Query('sellerId') sellerId?: string) {
    return {
      success: true,
      data: await this.service.adminListProducts(sellerId),
    };
  }

  @Delete('products/:id')
  async deleteProduct(@Param('id') id: string) {
    return { success: true, data: await this.service.adminDeleteProduct(id) };
  }
}
