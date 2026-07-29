import {
  BadRequestException,
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AccessTokenPayload, CurrentUser, JwtAuthGuard } from '@beshariq/nest-auth';
import {
  RateTaxiDto,
  RequestTaxiDto,
  SendTaxiMessageDto,
} from './dto/request-taxi.dto';
import { TaxiService } from './taxi.service';

/** Mijoz taksi buyurtmasi. plan/05-customer-app.md */
@Controller('taxi')
@UseGuards(JwtAuthGuard)
export class TaxiController {
  constructor(private readonly taxi: TaxiService) {}

  /** Narx baholash (yaratmasdan) — manzil belgilangan bo'lishi shart. */
  @Post('estimate')
  @HttpCode(200)
  async estimate(@Body() dto: RequestTaxiDto) {
    if (!dto.destination) {
      throw new BadRequestException('Narx baholash uchun manzil kerak');
    }
    return {
      success: true,
      data: await this.taxi.estimate(dto.pickup, dto.destination),
    };
  }

  /** Taksi chaqirish. */
  @Post('request')
  async request(
    @CurrentUser() user: AccessTokenPayload,
    @Body() dto: RequestTaxiDto,
  ) {
    return { success: true, data: await this.taxi.create(user.sub, dto) };
  }

  @Get('mine')
  async mine(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.taxi.listMine(user.sub) };
  }

  /** Taksi tarifi (minimal narx ko'rsatish uchun). ':id' dan oldin turishi shart. */
  @Get('tariff')
  async tariff() {
    return { success: true, data: await this.taxi.taxiTariff() };
  }

  /** Yaqin (online) haydovchilar — "yaqin mashinalar". ':id' dan oldin turishi shart. */
  @Get('nearby-drivers')
  async nearbyDrivers(@Query('lat') lat: string, @Query('lng') lng: string) {
    const la = Number(lat);
    const ln = Number(lng);
    if (!Number.isFinite(la) || !Number.isFinite(ln)) {
      throw new BadRequestException('lat va lng kerak');
    }
    return { success: true, data: await this.taxi.nearbyDrivers(la, ln) };
  }

  @Get(':id')
  async detail(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
  ) {
    return { success: true, data: await this.taxi.liveForCustomer(user.sub, id) };
  }

  /** Biriktirilgan haydovchining jonli joylashuvi (null bo'lishi mumkin). */
  @Get(':id/driver')
  async driverLocation(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
  ) {
    return {
      success: true,
      data: await this.taxi.driverLocationForTrip(user.sub, id),
    };
  }

  @Post(':id/cancel')
  @HttpCode(200)
  async cancel(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
  ) {
    return { success: true, data: await this.taxi.cancel(user.sub, id) };
  }

  /** Safarni baholash (1-5) — yakunlangach. */
  @Post(':id/rate')
  @HttpCode(200)
  async rate(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
    @Body() dto: RateTaxiDto,
  ) {
    return {
      success: true,
      data: await this.taxi.rate(user.sub, id, dto.rating, dto.comment),
    };
  }

  /** Suhbat xabarlari (mijoz yoki haydovchi — ishtirokchi bo'lsa). */
  @Get(':id/messages')
  async messages(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
  ) {
    return { success: true, data: await this.taxi.listMessages(id, user.sub) };
  }

  /** Xabar yuborish — birinchi xabarga "Assalomu alaykum, " qo'shiladi. */
  @Post(':id/messages')
  async sendMessage(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
    @Body() dto: SendTaxiMessageDto,
  ) {
    return {
      success: true,
      data: await this.taxi.sendMessage(id, user.sub, dto.text),
    };
  }
}
