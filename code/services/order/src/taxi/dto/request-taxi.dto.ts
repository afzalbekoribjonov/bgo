import { Type } from 'class-transformer';
import {
  DRIVER_CANCEL_REASONS,
  DriverCancelReason,
} from '../../common/cancel-reasons';
import {
  IsIn,
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

  /** Tarif klassi: start (standart) | comfort (faqat Comfort mashinalar). */
  @IsOptional()
  @IsIn(['start', 'comfort'])
  tariffClass?: 'start' | 'comfort';
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

/** Haydovchi safarni bekor qiladi — sabab majburiy. */
export class DriverCancelDto {
  @IsIn(DRIVER_CANCEL_REASONS)
  reason!: DriverCancelReason;

  @IsOptional()
  @IsString()
  @MaxLength(300)
  note?: string;
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
