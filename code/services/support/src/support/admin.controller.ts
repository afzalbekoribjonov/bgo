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
import { Roles, RolesGuard, JwtAuthGuard } from '@beshariq/nest-auth';
import { CreateFaqDto, UpdateFaqDto } from './dto/faq.dto';
import { SupportService } from './support.service';

/** Admin panel tomoni — barcha suhbatlar (eskalatsiya nazorati) + FAQ boshqaruvi. */
@Controller('support/admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
export class AdminController {
  constructor(private readonly service: SupportService) {}

  @Get('conversations')
  async list(
    @Query('status') status?: 'OPEN' | 'ESCALATED' | 'RESOLVED',
    @Query('role') role?: 'CUSTOMER' | 'DRIVER',
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return {
      success: true,
      data: await this.service.adminListConversations({
        status,
        role,
        page: Math.max(1, Number(page) || 1),
        pageSize: Math.min(100, Math.max(1, Number(pageSize) || 20)),
      }),
    };
  }

  @Get('conversations/:id/messages')
  async messages(@Param('id') id: string) {
    return { success: true, data: await this.service.adminGetMessages(id) };
  }

  @Post('conversations/:id/messages')
  async reply(@Param('id') id: string, @Body('text') text: string) {
    return { success: true, data: await this.service.adminReply(id, text) };
  }

  @Get('faq')
  async listFaq() {
    return { success: true, data: await this.service.adminListFaq() };
  }

  @Post('faq')
  async createFaq(@Body() dto: CreateFaqDto) {
    return { success: true, data: await this.service.createFaq(dto) };
  }

  @Patch('faq/:id')
  async updateFaq(@Param('id') id: string, @Body() dto: UpdateFaqDto) {
    return { success: true, data: await this.service.updateFaq(id, dto) };
  }

  @Delete('faq/:id')
  async deleteFaq(@Param('id') id: string) {
    return { success: true, data: await this.service.deleteFaq(id) };
  }

  // ---------- Mijozlarga shikoyatlar (haydovchidan AI orqali) ----------

  @Get('complaints')
  async listComplaints(
    @Query('status') status?: 'OPEN' | 'RESOLVED' | 'DISMISSED',
  ) {
    return { success: true, data: await this.service.adminListComplaints(status) };
  }

  @Post('complaints/:id/resolve')
  async resolveComplaint(@Param('id') id: string) {
    return { success: true, data: await this.service.setComplaintStatus(id, 'RESOLVED') };
  }

  @Post('complaints/:id/dismiss')
  async dismissComplaint(@Param('id') id: string) {
    return { success: true, data: await this.service.setComplaintStatus(id, 'DISMISSED') };
  }
}
