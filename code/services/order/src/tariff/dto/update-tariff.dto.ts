import { IsInt, IsNumber, IsOptional, Max, Min } from 'class-validator';

export class UpdateTariffDto {
  @IsOptional()
  @IsInt()
  @Min(0)
  deliveryFee?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  foodCommissionPercent?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  courierSharePercent?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  taxiBaseFare?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  taxiPerKm?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  taxiMinFare?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  taxiCommissionPercent?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  taxiWaitPerMin?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(60)
  taxiWaitFreeMin?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  taxiPickupSurchargePerKm?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(50)
  taxiPickupSurchargeThresholdKm?: number;

  // Comfort tarifi ustamalari (Start narxiga qo'shiladi)
  @IsOptional()
  @IsInt()
  @Min(0)
  taxiComfortPerKmExtra?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  taxiComfortBaseExtra?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  parcelBaseFare?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  parcelPerKm?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  parcelMinFare?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  parcelCommissionPercent?: number;

  // Ovqat xizmat haqi (ustama) — bizning yagona ovqat daromadimiz.
  @IsOptional()
  @IsInt()
  @Min(0)
  foodServiceThreshold?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  foodServiceFeeUnder?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  foodServiceFeeOver?: number;

  // "Uyga" rejimi — uyga mos taksi/dostavka buyurtmalarida oddiy komissiya
  // o'rniga qo'llanadi. Ovqatga tegishli emas (kuryer komissiyasiz qoladi).
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  homeModeTaxiCommissionPercent?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  homeModeParcelCommissionPercent?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  homeModeMaxDetourPercent?: number;
}
