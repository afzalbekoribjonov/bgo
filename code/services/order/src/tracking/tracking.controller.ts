import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  AccessTokenPayload,
  CurrentUser,
  JwtAuthGuard,
  Roles,
  RolesGuard,
} from '@beshariq/nest-auth';
import { OsrmRouteClient } from '../common/osrm-route.client';
import { PingLocationDto } from './dto/ping-location.dto';
import { RouteQueryDto } from './dto/route-query.dto';
import { DriverLocationService } from './driver-location.service';

/**
 * Haydovchi/kuryer jonli joylashuvi. Faqat 'driver' roli; driverId JWT'dan.
 * plan/12-maps-navigation.md
 */
@Controller('driver')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('driver')
export class TrackingController {
  constructor(
    private readonly locations: DriverLocationService,
    private readonly osrm: OsrmRouteClient,
  ) {}

  /**
   * Navigatsiya marshruti: geometriya + burilishlar (turn-by-turn uchun).
   * OSRM ishlamasa `data: null` qaytadi (HTTP xato EMAS) — ilova mavjud
   * "to'g'ri chiziq" zaxirasiga tushadi va navigatsiya buzilmaydi.
   */
  @Get('route')
  async route(@Query() q: RouteQueryDto) {
    const data = await this.osrm.routeWithSteps(
      { lat: q.fromLat, lng: q.fromLng },
      { lat: q.toLat, lng: q.toLng },
    );
    return { success: true, data };
  }

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
