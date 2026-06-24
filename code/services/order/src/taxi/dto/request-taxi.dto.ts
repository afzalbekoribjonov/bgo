import { Type } from 'class-transformer';
import {
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  Max,
  MaxLength,
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

/** Suhbat xabari yuborish. Birinchi xabarga "Assalomu alaykum, " server qo'shadi. */
export class SendTaxiMessageDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(1000)
  text!: string;
}

/** Safarni baholash (yakunlangach). */
export class RateTaxiDto {
  @IsInt()
  @Min(1)
  @Max(5)
  rating!: number;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  comment?: string;
}
