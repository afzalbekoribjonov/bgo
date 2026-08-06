import { IsBoolean, IsInt, IsOptional, Min } from 'class-validator';

export class UpdateMarketSettingsDto {
  @IsOptional()
  @IsInt()
  @Min(0)
  minOrderAmount?: number;

  @IsOptional()
  @IsBoolean()
  isAcceptingOrders?: boolean;
}
