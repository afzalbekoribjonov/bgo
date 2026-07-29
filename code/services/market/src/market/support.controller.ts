import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import {
  AccessTokenPayload,
  CurrentUser,
  JwtAuthGuard,
  Roles,
  RolesGuard,
} from '@beshariq/nest-auth';
import { CreateSupportMessageDto } from './dto/support-message.dto';
import { MarketService } from './market.service';

/** Market Support chat — mijoz o'z ipida yozadi, admin barcha iplarni ko'radi. */
@Controller('market/support')
export class SupportController {
  constructor(private readonly service: MarketService) {}

  @Get('messages')
  @UseGuards(JwtAuthGuard)
  async myMessages(@CurrentUser() user: AccessTokenPayload) {
    return {
      success: true,
      data: await this.service.listSupportMessages(user.sub),
    };
  }

  @Post('messages')
  @UseGuards(JwtAuthGuard)
  async send(
    @Body() dto: CreateSupportMessageDto,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return {
      success: true,
      data: await this.service.sendSupportMessage(user.sub, 'CUSTOMER', dto.text),
    };
  }

  @Get('admin/threads')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  async threads() {
    return { success: true, data: await this.service.listSupportThreads() };
  }

  @Get('admin/threads/:customerId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  async threadMessages(@Param('customerId') customerId: string) {
    return {
      success: true,
      data: await this.service.listSupportMessages(customerId),
    };
  }

  @Post('admin/threads/:customerId')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  async reply(
    @Param('customerId') customerId: string,
    @Body() dto: CreateSupportMessageDto,
  ) {
    await this.service.markSupportSeen(customerId);
    return {
      success: true,
      data: await this.service.sendSupportMessage(customerId, 'SUPPORT', dto.text),
    };
  }
}
