import { Controller, Get, UseGuards } from '@nestjs/common';
import { InternalKeyGuard } from '@beshariq/nest-auth';
import { TariffService } from './tariff.service';

/**
 * Servislararo (internal) endpoint — services/support AI yordamchisi joriy
 * narxlarni promptga qo'shish uchun so'raydi. x-internal-key bilan
 * himoyalangan (JWT emas) — @beshariq/nest-auth guard'i.
 */
@Controller('internal/tariff')
@UseGuards(InternalKeyGuard)
export class InternalTariffController {
  constructor(private readonly service: TariffService) {}

  @Get()
  async get() {
    return { success: true, data: await this.service.getTariff() };
  }
}
