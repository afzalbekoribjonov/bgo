import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard, Roles, RolesGuard } from '@beshariq/nest-auth';
import { CustomersService } from './customers.service';
import { BlockCustomerDto, SendCustomerMessageDto } from './dto/customer.dto';

/** Mijoz moderatsiyasi (bloklash) + xabar yuborish — faqat admin. */
@Controller('auth/admin/customers')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
export class AdminCustomersController {
  constructor(private readonly customers: CustomersService) {}

  // Diqqat: statik 'messages' yo'li ':id'dan OLDIN turishi shart.

  @Post('messages')
  async sendMessage(@Body() dto: SendCustomerMessageDto) {
    return { success: true, data: await this.customers.sendMessage(dto) };
  }

  @Get('messages')
  async listMessages() {
    return { success: true, data: await this.customers.listSentMessages() };
  }

  @Get(':id')
  async getOne(@Param('id') id: string) {
    return { success: true, data: await this.customers.getById(id) };
  }

  @Patch(':id/block')
  async block(@Param('id') id: string, @Body() dto: BlockCustomerDto) {
    return { success: true, data: await this.customers.block(id, dto.reason) };
  }

  @Patch(':id/unblock')
  async unblock(@Param('id') id: string) {
    return { success: true, data: await this.customers.unblock(id) };
  }
}
