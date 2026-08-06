import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import { InternalKeyGuard } from '@beshariq/nest-auth';
import { DriversService } from './drivers.service';

/** Servislararo: komissiya yechish so'rovi. */
export class ChargeDto {
  @IsInt()
  @Min(0)
  amount!: number;

  @IsOptional()
  @IsString()
  note?: string;
}

/** Servislararo: mijoz bahosini haydovchi reytingiga qo'shish so'rovi. */
export class ApplyRatingDto {
  @IsInt()
  @Min(1)
  @Max(5)
  score!: number;
}

/**
 * Servislararo: haydovchi ommaviy ma'lumoti + balansdan komissiya yechish
 * (order servisi chaqiradi). `x-internal-key` bilan himoyalangan.
 */
@Controller('internal/drivers')
@UseGuards(InternalKeyGuard)
export class InternalDriversController {
  constructor(private readonly drivers: DriversService) {}

  /** GET /api/v1/internal/drivers/comfort-ids -> Comfort haydovchi userId'lari. */
  @Get('comfort-ids')
  async comfortIds() {
    return { success: true, data: await this.drivers.comfortUserIds() };
  }

  /**
   * GET /api/v1/internal/drivers/high-cancellations?threshold=3 ->
   * ketma-ket shu sondan ortiq bekor qilgan haydovchilar (Shubhali haydovchilar).
   */
  @Get('high-cancellations')
  async highCancellations(@Query('threshold') threshold?: string) {
    const t = Number(threshold);
    return {
      success: true,
      data: await this.drivers.listHighCancellationDrivers(
        Number.isFinite(t) && t > 0 ? t : 3,
      ),
    };
  }

  /** POST /api/v1/internal/drivers/:userId/record-cancellation -> hisoblagichni oshiradi. */
  @Post(':userId/record-cancellation')
  @HttpCode(200)
  async recordCancellation(@Param('userId') userId: string) {
    return { success: true, data: await this.drivers.recordCancellation(userId) };
  }

  /** POST /api/v1/internal/drivers/:userId/record-completion -> hisoblagichni 0'ga tushiradi. */
  @Post(':userId/record-completion')
  @HttpCode(200)
  async recordCompletion(@Param('userId') userId: string) {
    await this.drivers.recordCompletion(userId);
    return { success: true };
  }

  /**
   * GET /api/v1/internal/drivers/batch?ids=a,b,c -> {userId,fullName,carName,carYear,plateNumber}[]
   * Bir nechta haydovchi ma'lumotini bitta so'rovda oladi — admin ro'yxatlarni
   * boyitishda har qator uchun alohida chaqiruv (N+1) o'rniga.
   */
  @Get('batch')
  async batch(@Query('ids') ids?: string) {
    const idList = (ids ?? '')
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);
    return { success: true, data: await this.drivers.getPublicByUserIds(idList) };
  }

  /**
   * GET /api/v1/internal/drivers/home-mode-active -> {userId,lat,lng}[]
   * "Uyga" rejimi faol haydovchilar — order servisi dispatch mosligini
   * hisoblashi uchun (OSRM marshrut chetlanishi).
   */
  @Get('home-mode-active')
  async homeModeActive() {
    return { success: true, data: await this.drivers.homeModeActiveDrivers() };
  }

  /** GET /api/v1/internal/drivers/:userId -> { fullName, carName, ... } | null */
  @Get(':userId')
  async byUserId(@Param('userId') userId: string) {
    return { success: true, data: await this.drivers.getPublicByUserId(userId) };
  }

  /** GET /api/v1/internal/drivers/:userId/phone -> { phone } (suhbat qo'ng'irog'i). */
  @Get(':userId/phone')
  async phone(@Param('userId') userId: string) {
    return { success: true, data: await this.drivers.getUserPhone(userId) };
  }

  /** POST /api/v1/internal/drivers/:userId/charge -> balansdan komissiya yechadi. */
  @Post(':userId/charge')
  @HttpCode(200)
  async charge(@Param('userId') userId: string, @Body() dto: ChargeDto) {
    return {
      success: true,
      data: await this.drivers.charge(userId, dto.amount, dto.note ?? ''),
    };
  }

  /**
   * POST /api/v1/internal/drivers/:userId/silent-refund -> balansga
   * SEZDIRMASDAN qo'shadi (haydovchi "Hisobim"da ko'rmaydi).
   */
  @Post(':userId/silent-refund')
  @HttpCode(200)
  async silentRefund(@Param('userId') userId: string, @Body() dto: ChargeDto) {
    return {
      success: true,
      data: await this.drivers.silentRefund(userId, dto.amount, dto.note ?? ''),
    };
  }

  /**
   * POST /api/v1/internal/drivers/:userId/apply-rating -> mijoz bahosini
   * (1-5) haydovchining umumiy reytingiga og'irlik-o'rtacha sifatida qo'shadi.
   */
  @Post(':userId/apply-rating')
  @HttpCode(200)
  async applyRating(@Param('userId') userId: string, @Body() dto: ApplyRatingDto) {
    await this.drivers.applyCustomerRating(userId, dto.score);
    return { success: true };
  }
}
