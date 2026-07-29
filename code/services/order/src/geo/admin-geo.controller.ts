import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard, Roles, RolesGuard } from '@beshariq/nest-auth';
import {
  CreateAreaDto,
  CreateMarkerDto,
  CreatePlaceDto,
  CreateRoadDto,
  UpdateAreaDto,
  UpdateRoadDto,
} from './dto/geo.dto';
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

  @Get('roads')
  async roads() {
    return { success: true, data: await this.geo.listRoads() };
  }

  @Post('areas/:id/roads')
  async addRoad(@Param('id') id: string, @Body() dto: CreateRoadDto) {
    return { success: true, data: await this.geo.addRoad(id, dto) };
  }

  @Patch('roads/:id')
  async updateRoad(@Param('id') id: string, @Body() dto: UpdateRoadDto) {
    return { success: true, data: await this.geo.updateRoad(id, dto) };
  }

  @Delete('roads/:id')
  @HttpCode(200)
  async deleteRoad(@Param('id') id: string) {
    await this.geo.deleteRoad(id);
    return { success: true };
  }

  @Get('markers')
  async markers(@Query('areaId') areaId?: string) {
    return { success: true, data: await this.geo.listMarkers(areaId) };
  }

  @Post('areas/:id/markers')
  async addMarker(@Param('id') id: string, @Body() dto: CreateMarkerDto) {
    return { success: true, data: await this.geo.addMarker(id, dto) };
  }

  @Delete('markers/:id')
  @HttpCode(200)
  async deleteMarker(@Param('id') id: string) {
    await this.geo.deleteMarker(id);
    return { success: true };
  }

  /** Beshariqning barcha yo'llarini OSM'dan import (yashil yo'l to'ri). */
  @Post('import-osm-roads')
  @HttpCode(200)
  async importOsm() {
    return { success: true, data: await this.geo.importOsmRoads() };
  }

  /** Nomli joylarni (qishloq/mahalla...) OSM'dan import — dublikatsiz qo'shadi. */
  @Post('import-osm-places')
  @HttpCode(200)
  async importOsmPlaces() {
    return { success: true, data: await this.geo.importOsmPlaces() };
  }
}
