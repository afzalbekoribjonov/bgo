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
  taxiWaitPerMin: number;
  taxiWaitFreeMin: number;
  taxiPickupSurchargePerKm: number;
  taxiPickupSurchargeThresholdKm: number;
  taxiComfortPerKmExtra: number;
  taxiComfortBaseExtra: number;
  parcelBaseFare: number;
  parcelPerKm: number;
  parcelMinFare: number;
  parcelCommissionPercent: number;
  foodServiceThreshold: number;
  foodServiceFeeUnder: number;
  foodServiceFeeOver: number;
  driverCancelPenalty: number;
  homeModeTaxiCommissionPercent: number;
  homeModeParcelCommissionPercent: number;
  homeModeMaxDetourPercent: number;
  homeModeMaxHomeDistanceKm: number;
}

export type TariffPatch = Partial<Omit<Tariff, 'id'>>;

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
    return this.map(t);
  }

  async updateTariff(patch: TariffPatch): Promise<Tariff> {
    const t = await this.prisma.tariff.upsert({
      where: { id: 'default' },
      update: patch,
      create: { id: 'default', ...patch },
    });
    return this.map(t);
  }

  private map(t: {
    id: string;
    deliveryFee: number;
    foodCommissionPercent: number;
    courierSharePercent: number;
    taxiBaseFare: number;
    taxiPerKm: number;
    taxiMinFare: number;
    taxiCommissionPercent: number;
    taxiWaitPerMin: number;
    taxiWaitFreeMin: number;
    taxiPickupSurchargePerKm: number;
    taxiPickupSurchargeThresholdKm: number;
    taxiComfortPerKmExtra: number;
    taxiComfortBaseExtra: number;
    parcelBaseFare: number;
    parcelPerKm: number;
    parcelMinFare: number;
    parcelCommissionPercent: number;
    foodServiceThreshold: number;
    foodServiceFeeUnder: number;
    foodServiceFeeOver: number;
    driverCancelPenalty: number;
    homeModeTaxiCommissionPercent: number;
    homeModeParcelCommissionPercent: number;
    homeModeMaxDetourPercent: number;
    homeModeMaxHomeDistanceKm: number;
  }): Tariff {
    return {
      id: t.id,
      deliveryFee: t.deliveryFee,
      foodCommissionPercent: t.foodCommissionPercent,
      courierSharePercent: t.courierSharePercent,
      taxiBaseFare: t.taxiBaseFare,
      taxiPerKm: t.taxiPerKm,
      taxiMinFare: t.taxiMinFare,
      taxiCommissionPercent: t.taxiCommissionPercent,
      taxiWaitPerMin: t.taxiWaitPerMin,
      taxiWaitFreeMin: t.taxiWaitFreeMin,
      taxiPickupSurchargePerKm: t.taxiPickupSurchargePerKm,
      taxiPickupSurchargeThresholdKm: t.taxiPickupSurchargeThresholdKm,
      taxiComfortPerKmExtra: t.taxiComfortPerKmExtra,
      taxiComfortBaseExtra: t.taxiComfortBaseExtra,
      parcelBaseFare: t.parcelBaseFare,
      parcelPerKm: t.parcelPerKm,
      parcelMinFare: t.parcelMinFare,
      parcelCommissionPercent: t.parcelCommissionPercent,
      foodServiceThreshold: t.foodServiceThreshold,
      foodServiceFeeUnder: t.foodServiceFeeUnder,
      foodServiceFeeOver: t.foodServiceFeeOver,
      driverCancelPenalty: t.driverCancelPenalty,
      homeModeTaxiCommissionPercent: t.homeModeTaxiCommissionPercent,
      homeModeParcelCommissionPercent: t.homeModeParcelCommissionPercent,
      homeModeMaxDetourPercent: t.homeModeMaxDetourPercent,
      homeModeMaxHomeDistanceKm: t.homeModeMaxHomeDistanceKm,
    };
  }
}
