import { Body, Controller, Get, HttpCode, Post, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service';
import { CurrentUser } from './current-user.decorator';
import { ConsentDto } from './dto/consent.dto';
import { RefreshDto } from './dto/refresh.dto';
import { RequestOtpDto } from './dto/request-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { JwtAuthGuard } from './jwt-auth.guard';
import { AccessTokenPayload } from './jwt-payload.interface';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  /** POST /api/v1/auth/otp/request */
  @Post('otp/request')
  @HttpCode(200)
  async requestOtp(@Body() dto: RequestOtpDto) {
    const result = await this.auth.requestOtp(dto.phone);
    return { success: true, data: { sent: true, ...result } };
  }

  /** POST /api/v1/auth/otp/verify */
  @Post('otp/verify')
  @HttpCode(200)
  async verifyOtp(@Body() dto: VerifyOtpDto) {
    const data = await this.auth.verifyOtp(dto.phone, dto.code);
    return { success: true, data };
  }

  /** POST /api/v1/auth/refresh */
  @Post('refresh')
  @HttpCode(200)
  async refresh(@Body() dto: RefreshDto) {
    const data = await this.auth.refresh(dto.refreshToken);
    return { success: true, data };
  }

  /** GET /api/v1/auth/me */
  @Get('me')
  @UseGuards(JwtAuthGuard)
  async me(@CurrentUser() user: AccessTokenPayload) {
    const data = await this.auth.getMe(user.sub);
    return { success: true, data };
  }

  /** POST /api/v1/auth/consent */
  @Post('consent')
  @HttpCode(200)
  @UseGuards(JwtAuthGuard)
  async consent(@CurrentUser() user: AccessTokenPayload, @Body() dto: ConsentDto) {
    const data = await this.auth.saveConsent(user.sub, dto.privacy, dto.version);
    return { success: true, data };
  }
}
