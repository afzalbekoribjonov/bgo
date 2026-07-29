import { Body, Controller, Get, HttpCode, Param, Post, UseGuards } from '@nestjs/common';
import { AccessTokenPayload, CurrentUser, JwtAuthGuard } from '@beshariq/nest-auth';
import { IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';
import { CreateStoreOrderDto } from './dto/create-store-order.dto';
import { StoreOrdersService } from './store-orders.service';

class RateStoreOrderDto {
  @IsInt()
  @Min(1)
  @Max(5)
  rating!: number;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  comment?: string;
}

/** Mijoz — Beshariq Market buyurtmasi (yetkazish yoki olib ketish). */
@Controller('store')
@UseGuards(JwtAuthGuard)
export class StoreOrdersController {
  constructor(private readonly service: StoreOrdersService) {}

  @Post('orders')
  async create(
    @CurrentUser() user: AccessTokenPayload,
    @Body() dto: CreateStoreOrderDto,
  ) {
    return { success: true, data: await this.service.create(user.sub, dto) };
  }

  @Get('orders/mine')
  async mine(@CurrentUser() user: AccessTokenPayload) {
    return { success: true, data: await this.service.listMine(user.sub) };
  }

  @Get('orders/:id')
  async detail(@CurrentUser() user: AccessTokenPayload, @Param('id') id: string) {
    return { success: true, data: await this.service.getOwnedLive(user.sub, id) };
  }

  @Post('orders/:id/cancel')
  @HttpCode(200)
  async cancel(@CurrentUser() user: AccessTokenPayload, @Param('id') id: string) {
    return { success: true, data: await this.service.cancel(user.sub, id) };
  }

  @Post('orders/:id/rate')
  @HttpCode(200)
  async rate(
    @CurrentUser() user: AccessTokenPayload,
    @Param('id') id: string,
    @Body() dto: RateStoreOrderDto,
  ) {
    return {
      success: true,
      data: await this.service.rate(user.sub, id, dto.rating, dto.comment),
    };
  }

  /** Biriktirilgan haydovchining jonli joylashuvi (xaritada kuzatish). */
  @Get('orders/:id/driver')
  async driver(@CurrentUser() user: AccessTokenPayload, @Param('id') id: string) {
    return {
      success: true,
      data: await this.service.driverLocationForOrder(user.sub, id),
    };
  }
}
