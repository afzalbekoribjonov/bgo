import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard, Roles, RolesGuard } from '@beshariq/nest-auth';
import { RestaurantOwnerGuard } from './restaurant-owner.guard';
import { CreateCategoryDto, UpdateCategoryDto } from './dto/category.dto';
import {
  AvailabilityDto,
  CreateMenuItemDto,
  UpdateMenuItemDto,
} from './dto/menu-item.dto';
import { OpenDto } from './dto/open.dto';
import { UpdateLogoDto } from './dto/logo.dto';
import { RestaurantsService } from './restaurants.service';

/**
 * Oshxona boshqaruvi (menyu, kategoriya, narx). plan/07-restaurant-app.md
 * Faqat 'restaurant' roli. TODO: restaurantId egalik tekshiruvi (ownerUserId↔restaurant).
 */
@Controller('restaurants/:restaurantId')
@UseGuards(JwtAuthGuard, RolesGuard, RestaurantOwnerGuard)
@Roles('restaurant', 'admin')
export class ManagementController {
  constructor(private readonly service: RestaurantsService) {}

  // ----- Holat (ochiq/yopiq) -----

  /** "Hozir yopiq/ochiq" — oshxona bandligini boshqaradi. */
  @Patch('open')
  async setOpen(
    @Param('restaurantId') restaurantId: string,
    @Body() dto: OpenDto,
  ) {
    return {
      success: true,
      data: await this.service.setOpen(restaurantId, dto.isOpen),
    };
  }

  /** Oshxona logotipi (profil rasmi) — o'rnatish/o'zgartirish. */
  @Patch('logo')
  async updateLogo(
    @Param('restaurantId') restaurantId: string,
    @Body() dto: UpdateLogoDto,
  ) {
    return {
      success: true,
      data: await this.service.updateLogo(restaurantId, dto.logoUrl),
    };
  }

  // ----- Kategoriyalar -----

  @Get('categories')
  async listCategories(@Param('restaurantId') restaurantId: string) {
    return { success: true, data: await this.service.listCategories(restaurantId) };
  }

  @Post('categories')
  @HttpCode(201)
  async createCategory(
    @Param('restaurantId') restaurantId: string,
    @Body() dto: CreateCategoryDto,
  ) {
    return {
      success: true,
      data: await this.service.createCategory(restaurantId, dto),
    };
  }

  @Patch('categories/:id')
  async updateCategory(
    @Param('restaurantId') restaurantId: string,
    @Param('id') id: string,
    @Body() dto: UpdateCategoryDto,
  ) {
    return {
      success: true,
      data: await this.service.updateCategory(restaurantId, id, dto),
    };
  }

  @Delete('categories/:id')
  async deleteCategory(
    @Param('restaurantId') restaurantId: string,
    @Param('id') id: string,
  ) {
    await this.service.deleteCategory(restaurantId, id);
    return { success: true };
  }

  // ----- Taomlar -----

  @Get('menu-items')
  async listMenuItems(@Param('restaurantId') restaurantId: string) {
    return { success: true, data: await this.service.listMenuItems(restaurantId) };
  }

  @Post('menu-items')
  @HttpCode(201)
  async createMenuItem(
    @Param('restaurantId') restaurantId: string,
    @Body() dto: CreateMenuItemDto,
  ) {
    return {
      success: true,
      data: await this.service.createMenuItem(restaurantId, dto),
    };
  }

  @Patch('menu-items/:id')
  async updateMenuItem(
    @Param('restaurantId') restaurantId: string,
    @Param('id') id: string,
    @Body() dto: UpdateMenuItemDto,
  ) {
    return {
      success: true,
      data: await this.service.updateMenuItem(restaurantId, id, dto),
    };
  }

  @Patch('menu-items/:id/availability')
  async setAvailability(
    @Param('restaurantId') restaurantId: string,
    @Param('id') id: string,
    @Body() dto: AvailabilityDto,
  ) {
    return {
      success: true,
      data: await this.service.setAvailability(restaurantId, id, dto.isAvailable),
    };
  }

  @Delete('menu-items/:id')
  async deleteMenuItem(
    @Param('restaurantId') restaurantId: string,
    @Param('id') id: string,
  ) {
    await this.service.deleteMenuItem(restaurantId, id);
    return { success: true };
  }
}
