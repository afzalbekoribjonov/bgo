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
}
