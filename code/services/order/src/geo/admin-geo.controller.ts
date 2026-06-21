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
import { CreateAreaDto, CreatePlaceDto, UpdateAreaDto } from './dto/geo.dto';
import { GeoService } from './geo.service';

/** Xizmat hududlari + joylar boshqaruvi — faqat admin. plan/12-maps-navigation.md */
@Controller('admin/geo')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
export class AdminGeoController {
  constructor(private readonly geo: GeoService) {}

  @Get('areas')
  async areas() {
    return { success: true, data: await this.geo.listAllAreas() };
  }

  @Post('areas')
  async createArea(@Body() dto: CreateAreaDto) {
    return { success: true, data: await this.geo.createArea(dto) };
  }

  @Patch('areas/:id')
  async updateArea(@Param('id') id: string, @Body() dto: UpdateAreaDto) {
    return { success: true, data: await this.geo.updateArea(id, dto) };
  }

  @Delete('areas/:id')
  @HttpCode(200)
  async deleteArea(@Param('id') id: string) {
    await this.geo.deleteArea(id);
    return { success: true };
  }

  @Post('areas/:id/places')
  async addPlace(@Param('id') id: string, @Body() dto: CreatePlaceDto) {
    return { success: true, data: await this.geo.addPlace(id, dto) };
  }

  @Delete('places/:id')
  @HttpCode(200)
  async deletePlace(@Param('id') id: string) {
    await this.geo.deletePlace(id);
    return { success: true };
  }
}
