import {
  Controller,
  ForbiddenException,
  Headers,
  HttpCode,
  Param,
  Post,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RestaurantsService } from './restaurants.service';

/**
 * Servislararo (internal) endpoint — order servisi buyurtma bekor bo'lganda
 * oshxonani faolsiz qiladi. x-internal-key bilan himoyalangan (JWT emas).
 */
@Controller('internal/restaurants')
export class InternalRestaurantsController {
  constructor(
    private readonly service: RestaurantsService,
    private readonly config: ConfigService,
  ) {}

  /** Oshxonani faolsiz (isOpen=false) qiladi. */
  @Post(':id/inactive')
  @HttpCode(200)
  async inactive(
    @Param('id') id: string,
    @Headers('x-internal-key') key?: string,
  ) {
    const expected =
      this.config.get<string>('INTERNAL_API_KEY') ?? 'dev-internal-key';
    if (key !== expected) {
      throw new ForbiddenException("Internal kalit noto'g'ri");
    }
    await this.service.setOpen(id, false);
    return { success: true };
  }
}
