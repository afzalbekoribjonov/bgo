import { IsInt, IsOptional, Max, Min } from 'class-validator';

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
}
