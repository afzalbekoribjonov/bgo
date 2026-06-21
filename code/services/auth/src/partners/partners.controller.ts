import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { AccessTokenPayload, CurrentUser, JwtAuthGuard } from '@beshariq/nest-auth';
import { ApplyPartnerDto } from './dto/apply-partner.dto';
import { PartnersService } from './partners.service';

/**
 * Hamkorlik ("hamkorlik") — foydalanuvchi arizasi. plan/05-customer-app.md
 * Har autentifikatsiya qilingan foydalanuvchi ariza bera oladi.
 */
@Controller('partners')
@UseGuards(JwtAuthGuard)
export class PartnersController {
  constructor(private readonly partners: PartnersService) {}

  @Post('apply')
  async apply(
    @CurrentUser() user: AccessTokenPayload,
    @Body() dto: ApplyPartnerDto,
  ) {
    return {
      success: true,
      data: await this.partners.apply(user.sub, user.phone, dto),
    };
  }

  @Get('mine')
  async mine(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.partners.listMine(user.sub) };
  }
}
