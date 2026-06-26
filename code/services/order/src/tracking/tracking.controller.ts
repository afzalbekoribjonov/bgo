import {
  Body,
  Controller,
  Delete,
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
import { PingLocationDto } from './dto/ping-location.dto';
import { DriverLocationService } from './driver-location.service';

/**
 * Haydovchi/kuryer jonli joylashuvi. Faqat 'driver' roli; driverId JWT'dan.
 * plan/12-maps-navigation.md
 */
@Controller('driver')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('driver')
export class TrackingController {
  constructor(private readonly locations: DriverLocationService) {}

  /** Joylashuvni yangilash (har bir necha soniyada). */
  @Post('location')
  @HttpCode(200)
  async ping(
    @CurrentUser() user: AccessTokenPayload,
    @Body() dto: PingLocationDto,
  ) {
    return { success: true, data: await this.locations.ping(user.sub, dto) };
  }

  /** Online holatdan chiqish (joylashuvni o'chiradi). */
  @Delete('location')
  @HttpCode(200)
  async offline(@CurrentUser() user: AccessTokenPayload) {
    await this.locations.goOffline(user.sub);
    return { success: true };
  }
}
