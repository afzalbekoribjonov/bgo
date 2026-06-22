import {
  BadRequestException,
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AccessTokenPayload, CurrentUser, JwtAuthGuard } from '@beshariq/nest-auth';
import { RequestTaxiDto } from './dto/request-taxi.dto';
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

  @Get(':id')
  async detail(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
  ) {
    return { success: true, data: await this.taxi.getOwned(user.sub, id) };
  }

  @Post(':id/cancel')
  @HttpCode(200)
  async cancel(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
  ) {
    return { success: true, data: await this.taxi.cancel(user.sub, id) };
  }
}
