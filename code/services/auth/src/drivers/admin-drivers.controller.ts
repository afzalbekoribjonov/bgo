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
import {
  BlockDriverDto,
  CreateDriverDto,
  SendDriverMessageDto,
  TopupDto,
  UpdateDriverDto,
} from './dto/driver.dto';

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

  // Diqqat: statik 'messages' yo'llari ':id'dan OLDIN turishi shart.

  /** Xabar yuborish: driverUserId berilsa — bittaga, bo'lmasa hammaga. */
  @Post('messages')
  async sendMessage(@Body() dto: SendDriverMessageDto) {
    return { success: true, data: await this.drivers.sendMessage(dto) };
  }

  /** Yuborilgan xabarlar tarixi. */
  @Get('messages')
  async listMessages() {
    return { success: true, data: await this.drivers.listSentMessages() };
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

  @Post(':id/topup')
  async topup(@Param('id') id: string, @Body() dto: TopupDto) {
    return {
      success: true,
      data: await this.drivers.topup(id, dto.amount, dto.note),
    };
  }

  /** Ma'lum muddatga bloklash (sabab + daqiqa). */
  @Post(':id/block')
  async block(@Param('id') id: string, @Body() dto: BlockDriverDto) {
    return {
      success: true,
      data: await this.drivers.blockDriver(id, dto.reason, dto.minutes),
    };
  }

  /** Darhol blokdan chiqarish (masalan ofisda jarima to'langach). */
  @Post(':id/unblock')
  async unblock(@Param('id') id: string) {
    return { success: true, data: await this.drivers.unblockDriver(id) };
  }
}
