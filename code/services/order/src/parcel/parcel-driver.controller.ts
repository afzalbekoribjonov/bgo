import {
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AccessTokenPayload } from '../auth/jwt-payload.interface';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
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

  @Post('deliveries/:id/accept')
  @HttpCode(200)
  async accept(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.parcel.accept(id, user.sub) };
  }

  @Post('deliveries/:id/pickup')
  @HttpCode(200)
  async pickup(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.parcel.pickup(id, user.sub) };
  }

  @Post('deliveries/:id/delivered')
  @HttpCode(200)
  async delivered(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.parcel.delivered(id, user.sub) };
  }
}
