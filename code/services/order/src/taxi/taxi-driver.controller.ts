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
import { CompleteTaxiDto, DriverCancelDto } from './dto/request-taxi.dto';
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

  /** Yangi (PENDING), biriktirilmagan safarlar (haydovchi tarifiga ko'ra). */
  @Get('available')
  async available(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.taxi.listAvailable(user.sub) };
  }

  /** Haydovchining o'z safarlari. */
  @Get('my-trips')
  async myTrips(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.taxi.listDriverTrips(user.sub) };
  }

  /** Faol safarlar (jonli) — ilova qayta ochilganda tiklash uchun. */
  @Get('trips')
  async activeTrips(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.taxi.listActiveDriverTrips(user.sub) };
  }

  /** Bitta safar (jonli narx/kutish bilan). */
  @Get('trips/:id')
  async trip(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.taxi.liveForDriver(user.sub, id) };
  }

  @Post('trips/:id/accept')
  @HttpCode(200)
  async accept(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.taxi.accept(id, user.sub) };
  }

  /** Olib ketish nuqtasiga yetib keldi (ACCEPTED -> ARRIVED). */
  @Post('trips/:id/arrive')
  @HttpCode(200)
  async arrive(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.taxi.arrive(id, user.sub) };
  }

  /** Yo'l davomidagi kutishni yoqish/o'chirish (Kutish tugmasi, IN_PROGRESS). */
  @Post('trips/:id/wait')
  @HttpCode(200)
  async wait(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
  ) {
    return { success: true, data: await this.taxi.toggleWait(id, user.sub) };
  }

  /** Haydovchi safarni bekor qiladi (sabab majburiy) -> qayta dispatch. */
  @Post('trips/:id/cancel')
  @HttpCode(200)
  async cancel(
    @Param('id') id: string,
    @CurrentUser() user: AccessTokenPayload,
    @Body() dto: DriverCancelDto,
  ) {
    return {
      success: true,
      data: await this.taxi.driverCancel(id, user.sub, dto.reason, dto.note),
    };
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
    @Body() dto: CompleteTaxiDto,
  ) {
    return { success: true, data: await this.taxi.complete(id, user.sub, dto) };
  }
}
