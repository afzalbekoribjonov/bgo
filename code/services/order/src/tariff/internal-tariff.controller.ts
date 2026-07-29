import { Controller, ForbiddenException, Get, Headers } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { TariffService } from './tariff.service';

/**
 * Servislararo (internal) endpoint — services/support AI yordamchisi joriy
 * narxlarni promptga qo'shish uchun so'raydi. x-internal-key bilan
 * himoyalangan (JWT emas), services/market/src/market/internal.controller.ts
 * bilan bir xil naqsh.
 */
@Controller('internal/tariff')
export class InternalTariffController {
  constructor(
    private readonly service: TariffService,
    private readonly config: ConfigService,
  ) {}

  private checkKey(key?: string): void {
    const expected = this.config.get<string>('INTERNAL_API_KEY') ?? 'dev_internal_key';
    if (key !== expected) throw new ForbiddenException("Internal kalit noto'g'ri");
  }

  @Get()
  async get(@Headers('x-internal-key') key?: string) {
    this.checkKey(key);
    return { success: true, data: await this.service.getTariff() };
  }
}
