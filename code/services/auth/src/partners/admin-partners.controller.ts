import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UpdatePartnerStatusDto } from './dto/update-partner-status.dto';
import { PartnerStatus } from './partner.entity';
import { PartnersService } from './partners.service';

/**
 * Hamkorlik arizalarini boshqarish — faqat admin. plan/08-admin-workspace.md
 * Tasdiqlash = tegishli rolni berish (oshxona/haydovchi).
 */
@Controller('auth/admin/partners')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
export class AdminPartnersController {
  constructor(private readonly partners: PartnersService) {}

  @Get()
  async list(@Query('status') status?: string) {
    const valid: PartnerStatus[] = ['PENDING', 'APPROVED', 'REJECTED'];
    const filter = valid.includes(status as PartnerStatus)
      ? (status as PartnerStatus)
      : undefined;
    return { success: true, data: await this.partners.adminList(filter) };
  }

  @Patch(':id')
  async update(
    @Param('id') id: string,
    @Body() dto: UpdatePartnerStatusDto,
  ) {
    return {
      success: true,
      data: await this.partners.adminUpdateStatus(id, dto.status),
    };
  }
}
