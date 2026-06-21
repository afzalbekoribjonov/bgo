import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AccessTokenPayload, CurrentUser, JwtAuthGuard } from '@beshariq/nest-auth';
import { EstimateParcelDto, RequestParcelDto } from './dto/request-parcel.dto';
import { ParcelService } from './parcel.service';

/** Mijoz dostavka (pochta) buyurtmasi. plan/05-customer-app.md */
@Controller('parcel')
@UseGuards(JwtAuthGuard)
export class ParcelController {
  constructor(private readonly parcel: ParcelService) {}

  @Post('estimate')
  @HttpCode(200)
  async estimate(@Body() dto: EstimateParcelDto) {
    return { success: true, data: await this.parcel.estimateDto(dto) };
  }

  @Post('request')
  async request(
    @CurrentUser() user: AccessTokenPayload,
    @Body() dto: RequestParcelDto,
  ) {
    return { success: true, data: await this.parcel.create(user.sub, dto) };
  }

  @Get('mine')
  async mine(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.parcel.listMine(user.sub) };
  }

  @Get(':id')
  async detail(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
  ) {
    return { success: true, data: await this.parcel.getOwned(user.sub, id) };
  }

  @Post(':id/cancel')
  @HttpCode(200)
  async cancel(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
  ) {
    return { success: true, data: await this.parcel.cancel(user.sub, id) };
  }
}
