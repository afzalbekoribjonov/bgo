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
import {
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { EstimateParcelDto, RequestParcelDto } from './dto/request-parcel.dto';
import { ParcelService } from './parcel.service';

class RateParcelDto {
  @IsInt()
  @Min(1)
  @Max(5)
  rating!: number;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  comment?: string;
}

class SendParcelMessageDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(1000)
  text!: string;
}

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
    return { success: true, data: await this.parcel.getOwnedLive(user.sub, id) };
  }

  @Post(':id/cancel')
  @HttpCode(200)
  async cancel(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
  ) {
    return { success: true, data: await this.parcel.cancel(user.sub, id) };
  }

  /** Dostavkani baholash (yetkazilgandan keyin). */
  @Post(':id/rate')
  @HttpCode(200)
  async rate(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
    @Body() dto: RateParcelDto,
  ) {
    return {
      success: true,
      data: await this.parcel.rate(user.sub, id, dto.rating, dto.comment),
    };
  }

  /** Biriktirilgan kuryerning jonli joylashuvi (xaritada kuzatish). */
  @Get(':id/driver')
  async driver(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
  ) {
    return {
      success: true,
      data: await this.parcel.driverLocationForParcel(user.sub, id),
    };
  }

  /** Suhbat xabarlari (mijoz yoki kuryer — ishtirokchi bo'lsa). */
  @Get(':id/messages')
  async messages(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
  ) {
    return { success: true, data: await this.parcel.listMessages(id, user.sub) };
  }

  /** Xabar yuborish — birinchi xabarga "Assalomu alaykum, " qo'shiladi. */
  @Post(':id/messages')
  async sendMessage(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
    @Body() dto: SendParcelMessageDto,
  ) {
    return {
      success: true,
      data: await this.parcel.sendMessage(id, user.sub, dto.text),
    };
  }
}
