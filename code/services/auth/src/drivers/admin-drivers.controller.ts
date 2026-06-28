import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard, Roles, RolesGuard } from '@beshariq/nest-auth';
import { DriversService } from './drivers.service';
import { CreateDriverDto, UpdateDriverDto } from './dto/driver.dto';

/** Haydovchilarni boshqarish — faqat admin. plan/08-admin-workspace.md */
@Controller('auth/admin/drivers')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
export class AdminDriversController {
  constructor(private readonly drivers: DriversService) {}

  @Get()
  async list() {
    return { success: true, data: await this.drivers.listDrivers() };
  }

  @Post()
  async create(@Body() dto: CreateDriverDto) {
    return { success: true, data: await this.drivers.createDriver(dto) };
  }

  @Get(':id')
  async detail(@Param('id') id: string) {
    return { success: true, data: await this.drivers.getDriver(id) };
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() dto: UpdateDriverDto) {
    return { success: true, data: await this.drivers.updateDriver(id, dto) };
  }

  @Post(':id/regenerate-code')
  async regenerate(@Param('id') id: string) {
    return { success: true, data: await this.drivers.regenerateCode(id) };
  }
}
