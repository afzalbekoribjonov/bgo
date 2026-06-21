import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export interface Tariff {
  id: string;
  deliveryFee: number;
  foodCommissionPercent: number;
  courierSharePercent: number;
  taxiBaseFare: number;
  taxiPerKm: number;
  taxiMinFare: number;
  taxiCommissionPercent: number;
}

/**
 * Narx/tarif sozlamasi (MVP: yagona 'default' qator). plan/11-pricing-promo.md
 * TODO: alohida Pricing servisiga ajratish (zona, taksi km/daqiqa, surge).
 */
@Injectable()
export class TariffService {
  constructor(private readonly prisma: PrismaService) {}

  /** Joriy tarif (bo'lmasa standart qiymatlar bilan yaratiladi). */
  async getTariff(): Promise<Tariff> {
    const t = await this.prisma.tariff.upsert({
      where: { id: 'default' },
      update: {},
      create: { id: 'default' },
    });
    return {
      id: t.id,
      deliveryFee: t.deliveryFee,
      foodCommissionPercent: t.foodCommissionPercent,
      courierSharePercent: t.courierSharePercent,
      taxiBaseFare: t.taxiBaseFare,
      taxiPerKm: t.taxiPerKm,
      taxiMinFare: t.taxiMinFare,
      taxiCommissionPercent: t.taxiCommissionPercent,
    };
  }

  async updateTariff(patch: {
    deliveryFee?: number;
    foodCommissionPercent?: number;
    courierSharePercent?: number;
    taxiBaseFare?: number;
    taxiPerKm?: number;
    taxiMinFare?: number;
    taxiCommissionPercent?: number;
  }): Promise<Tariff> {
    const t = await this.prisma.tariff.upsert({
      where: { id: 'default' },
      update: patch,
      create: { id: 'default', ...patch },
    });
    return {
      id: t.id,
      deliveryFee: t.deliveryFee,
      foodCommissionPercent: t.foodCommissionPercent,
      courierSharePercent: t.courierSharePercent,
      taxiBaseFare: t.taxiBaseFare,
      taxiPerKm: t.taxiPerKm,
      taxiMinFare: t.taxiMinFare,
      taxiCommissionPercent: t.taxiCommissionPercent,
    };
  }
}
