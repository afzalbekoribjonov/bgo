import {
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AccessTokenPayload, CurrentUser, JwtAuthGuard, Roles, RolesGuard } from '@beshariq/nest-auth';
import { TaxiService } from './taxi.service';

/**
 * Haydovchi taksi oqimi. plan/06-driver-app.md
 * Faqat 'driver' roli; driverId token (JWT sub) dan olinadi.
 */
@Controller('taxi/driver')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('driver')
export class TaxiDriverController {
  constructor(private readonly taxi: TaxiService) {}

  /** Yangi (PENDING), biriktirilmagan safarlar. */
  @Get('available')
  async available() {
    return { success: true, data: await this.taxi.listAvailable() };
  }

  /** Haydovchining o'z safarlari. */
  @Get('my-trips')
  async myTrips(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.taxi.listDriverTrips(user.sub) };
  }

  @Post('trips/:id/accept')
  @HttpCode(200)
  async accept(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.taxi.accept(id, user.sub) };
  }

  @Post('trips/:id/start')
  @HttpCode(200)
  async start(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.taxi.start(id, user.sub) };
  }

  @Post('trips/:id/complete')
  @HttpCode(200)
  async complete(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.taxi.complete(id, user.sub) };
  }
}
