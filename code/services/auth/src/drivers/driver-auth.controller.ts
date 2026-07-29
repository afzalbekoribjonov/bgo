import {
  Body,
  Controller,
  Get,
  HttpCode,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  AccessTokenPayload,
  CurrentUser,
  JwtAuthGuard,
  Roles,
  RolesGuard,
} from '@beshariq/nest-auth';
import { DriversService } from './drivers.service';
import {
  DriverCheckDto,
  DriverLoginDto,
  DriverStatusDto,
} from './dto/driver.dto';

/**
 * Haydovchi ilovasi autentifikatsiyasi — ro'yxatdan o'tishsiz.
 * Telefon raqami admin tomonidan qo'shilgan bo'lsa, 8 xonali kod bilan kiradi.
 * plan/06-driver-app.md
 */
@Controller('auth/driver')
export class DriverAuthController {
  constructor(private readonly drivers: DriversService) {}

  /** Raqam bizning haydovchimi? (login: kod inputini ochishdan oldin) */
  @Post('check')
  @HttpCode(200)
  async check(@Body() dto: DriverCheckDto) {
    return { success: true, data: await this.drivers.checkPhone(dto.phone) };
  }

  /** Telefon + 8 xonali kod -> uzoq muddatli token. */
  @Post('login')
  @HttpCode(200)
  async login(@Body() dto: DriverLoginDto) {
    return { success: true, data: await this.drivers.login(dto.phone, dto.code) };
  }

  /** Joriy haydovchi profili. */
  @Get('me')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('driver')
  async me(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.drivers.getByPhone(user.phone) };
  }

  /** Hisob balansi + to'ldirish tarixi (Hisobim). */
  @Get('balance')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('driver')
  async balance(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.drivers.getBalance(user.phone) };
  }

  /** Onlayn/oflayn (Liniyaga chiqish / Ishni yakunlash). */
  @Post('status')
  @HttpCode(200)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('driver')
  async status(
    @CurrentUser() user: AccessTokenPayload,
    @Body() dto: DriverStatusDto,
  ) {
    return {
      success: true,
      data: await this.drivers.setOnline(user.phone, dto.isOnline),
    };
  }

  /** Menga kelgan xabarlar (admin yuborgan; broadcast + shaxsiy). */
  @Get('messages')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('driver')
  async messages(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.drivers.myMessages(user.sub) };
  }

  /** O'qilmagan xabarlar soni (qo'ng'iroqcha badge). */
  @Get('messages/unread-count')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('driver')
  async unreadCount(@CurrentUser() user: AccessTokenPayload) {
    return {
      success: true,
      data: await this.drivers.unreadMessagesCount(user.sub),
    };
  }

  /** Xabarlar ekrani ochildi — hammasini o'qilgan deb belgilash. */
  @Post('messages/read')
  @HttpCode(200)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('driver')
  async markRead(@CurrentUser() user: AccessTokenPayload) {
    return {
      success: true,
      data: await this.drivers.markMessagesRead(user.sub),
    };
  }
}
