import { Body, Controller, Get, Headers, Param, Post, UseGuards } from '@nestjs/common';
import { AccessTokenPayload, CurrentUser, JwtAuthGuard } from '@beshariq/nest-auth';
import { localeFromHeader } from '@beshariq/i18n';
import { CreateConversationDto, SendMessageDto } from './dto/conversation.dto';
import { SupportService } from './support.service';

function roleOf(user: AccessTokenPayload): 'CUSTOMER' | 'DRIVER' {
  return user.roles.includes('driver') ? 'DRIVER' : 'CUSTOMER';
}

/** Mijoz/haydovchi tomoni — AI yordamchi + tayyor savol-javoblar. */
@Controller('support')
@UseGuards(JwtAuthGuard)
export class SupportController {
  constructor(private readonly service: SupportService) {}

  @Get('faq')
  async faq(
    @CurrentUser() user: AccessTokenPayload,
    @Headers('accept-language') lang?: string,
  ) {
    return {
      success: true,
      data: await this.service.listFaq(roleOf(user), localeFromHeader(lang)),
    };
  }

  @Post('conversations')
  async create(
    @Body() dto: CreateConversationDto,
    @CurrentUser() user: AccessTokenPayload,
    @Headers('accept-language') lang?: string,
  ) {
    return {
      success: true,
      data: await this.service.createConversation(
        user.sub,
        roleOf(user),
        dto.topic,
        localeFromHeader(lang),
      ),
    };
  }

  @Get('conversations')
  async list(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.service.listConversations(user.sub) };
  }

  @Get('conversations/:id/messages')
  async messages(@Param('id') id: string, @CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.service.getMessages(user.sub, id) };
  }

  @Post('conversations/:id/messages')
  async send(
    @Param('id') id: string,
    @Body() dto: SendMessageDto,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return {
      success: true,
      data: await this.service.sendMessage(user.sub, roleOf(user), id, dto.text),
    };
  }
}
