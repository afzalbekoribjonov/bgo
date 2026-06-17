import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
} from '@nestjs/common';
import { CreateCategoryDto, UpdateCategoryDto } from './dto/category.dto';
import {
  AvailabilityDto,
  CreateMenuItemDto,
  UpdateMenuItemDto,
} from './dto/menu-item.dto';
import { RestaurantsService } from './restaurants.service';

/**
 * Oshxona boshqaruvi (menyu, kategoriya, narx). plan/07-restaurant-app.md
 * TODO(restaurant_web auth): restaurantId egalik tekshiruvi JWT orqali —
 * hozir ochiq (dev). Restaurant paneli auth ulanganda qo'shiladi.
 */
@Controller('restaurants/:restaurantId')
export class ManagementController {
  constructor(private readonly service: RestaurantsService) {}

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
