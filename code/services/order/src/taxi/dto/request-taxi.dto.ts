import { Type } from 'class-transformer';
import {
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';

export class GeoPointDto {
  @IsString()
  @IsNotEmpty()
  text!: string;

  @IsNumber()
  @Min(-90)
  @Max(90)
  lat!: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  lng!: number;
}

export class RequestTaxiDto {
  @IsObject()
  @ValidateNested()
  @Type(() => GeoPointDto)
  pickup!: GeoPointDto;

  // Ixtiyoriy: manzil belgilansa narx oldindan; belgilanmasa — metered (yakunda).
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => GeoPointDto)
  destination?: GeoPointDto;
}

/** Safarni yakunlash — metered uchun masofa, pulli kutish (ixtiyoriy). */
export class CompleteTaxiDto {
  @IsOptional()
  @IsNumber()
  @Min(0)
  distanceKm?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  waitMinutes?: number;
}
