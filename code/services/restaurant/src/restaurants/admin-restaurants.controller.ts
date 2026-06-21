import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
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
}
