import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AccessTokenPayload, CurrentUser, JwtAuthGuard, Roles, RolesGuard } from '@beshariq/nest-auth';
import { DriverCancelParcelDto } from './dto/request-parcel.dto';
import { ParcelService } from './parcel.service';

/**
 * Kuryer dostavka oqimi. plan/06-driver-app.md
 * Faqat 'driver' roli; driverId token (JWT sub) dan olinadi.
 */
@Controller('parcel/driver')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('driver')
export class ParcelDriverController {
  constructor(private readonly parcel: ParcelService) {}

  @Get('available')
  async available() {
    return { success: true, data: await this.parcel.listAvailable() };
  }

  @Get('my-deliveries')
  async myDeliveries(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.parcel.listDriverParcels(user.sub) };
  }

  /** Faol dostavkalar (jonli) — ilova qayta ochilganda tiklash. */
  @Get('deliveries')
  async activeDeliveries(@CurrentUser() user: AccessTokenPayload) {
    return {
      success: true,
      data: await this.parcel.listActiveDriverParcels(user.sub),
    };
  }

  /** Bitta dostavka (jonli). */
  @Get('deliveries/:id')
  async detail(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.parcel.liveForDriver(user.sub, id) };
  }

  @Post('deliveries/:id/accept')
  @HttpCode(200)
  async accept(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.parcel.accept(id, user.sub) };
  }

  /** Yetib keldim (ACCEPTED -> ARRIVED). */
  @Post('deliveries/:id/arrive')
  @HttpCode(200)
  async arrive(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.parcel.arrive(id, user.sub) };
  }

  /** Dastavkani oldim (ARRIVED -> PICKED_UP). */
  @Post('deliveries/:id/pickup')
  @HttpCode(200)
  async pickup(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.parcel.pickup(id, user.sub) };
  }

  /** Yo'lga chiqish (PICKED_UP -> IN_TRANSIT). */
  @Post('deliveries/:id/transit')
  @HttpCode(200)
  async transit(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.parcel.startTransit(id, user.sub) };
  }

  /** Safarni yakunlash (IN_TRANSIT -> DELIVERED). */
  @Post('deliveries/:id/delivered')
  @HttpCode(200)
  async delivered(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.parcel.delivered(id, user.sub) };
  }

  /** Kuryer bekor qiladi (sabab majburiy) -> qayta dispatch. */
  @Post('deliveries/:id/cancel')
  @HttpCode(200)
  async cancel(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
    @Body() dto: DriverCancelParcelDto,
  ) {
    return {
      success: true,
      data: await this.parcel.driverCancel(id, user.sub, dto.reason, dto.note),
    };
  }
}
