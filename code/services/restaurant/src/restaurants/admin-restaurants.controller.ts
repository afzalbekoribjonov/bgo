import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard, Roles, RolesGuard } from '@beshariq/nest-auth';
import { CreateRestaurantDto, UpdateRestaurantDto } from './dto/restaurant.dto';
import { RestaurantsService } from './restaurants.service';

/**
 * Oshxona onboarding — yaratish/tahrirlash (admin). plan/08-admin-workspace.md
 * Eslatma: '/restaurants/manage/all' (ikki segment) catalog ':id' bilan
 * to'qnashmaydi.
 */
@Controller('restaurants')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
export class AdminRestaurantsController {
  constructor(private readonly service: RestaurantsService) {}

  /** Barcha oshxonalar (admin ko'rinishi). */
  @Get('manage/all')
  async list() {
    return { success: true, data: await this.service.adminListRestaurants() };
  }

  @Post()
  async create(@Body() dto: CreateRestaurantDto) {
    return { success: true, data: await this.service.createRestaurant(dto) };
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() dto: UpdateRestaurantDto) {
    return { success: true, data: await this.service.updateRestaurant(id, dto) };
  }

  /** Oshxonani butunlay o'chirish — qaytarib bo'lmaydi. */
  @Delete(':id')
  async remove(@Param('id') id: string) {
    await this.service.deleteRestaurant(id);
    return { success: true };
  }
}
