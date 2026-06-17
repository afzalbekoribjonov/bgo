import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
} from 'class-validator';
import { I18nStringDto } from './i18n-string.dto';

export class CreateMenuItemDto {
  @IsString()
  @IsNotEmpty()
  categoryId!: string;

  @IsObject()
  @ValidateNested()
  @Type(() => I18nStringDto)
  name!: I18nStringDto;

  @IsOptional()
  @ValidateNested()
  @Type(() => I18nStringDto)
  description?: I18nStringDto;

  @IsInt()
  @Min(0)
  price!: number;

  @IsOptional()
  @IsString()
  imageUrl?: string;

  @IsOptional()
  @IsBoolean()
  isAvailable?: boolean;
}

export class UpdateMenuItemDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  categoryId?: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => I18nStringDto)
  name?: I18nStringDto;

  @IsOptional()
  @ValidateNested()
  @Type(() => I18nStringDto)
  description?: I18nStringDto;

  @IsOptional()
  @IsInt()
  @Min(0)
  price?: number;

  @IsOptional()
  @IsString()
  imageUrl?: string;

  @IsOptional()
  @IsBoolean()
  isAvailable?: boolean;
}

export class AvailabilityDto {
  @IsBoolean()
  isAvailable!: boolean;
}
