import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { I18nStringDto } from './i18n-string.dto';

export class CreateProductDto {
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
  @IsInt()
  @Min(0)
  stockQty?: number;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(10)
  @IsString({ each: true })
  imageUrls?: string[];

  /** Mavjud o'lchamlar (S/M/L yoki 42/43...). Bo'sh — o'lchamsiz mahsulot. */
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(30)
  @IsString({ each: true })
  @MaxLength(20, { each: true })
  sizes?: string[];

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdateProductDto {
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
  @IsArray()
  @ArrayMaxSize(10)
  @IsString({ each: true })
  imageUrls?: string[];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(30)
  @IsString({ each: true })
  @MaxLength(20, { each: true })
  sizes?: string[];

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class AdjustStockDto {
  /** Musbat — zaxirani oshiradi, manfiy — kamaytiradi (0 dan pastga tushmaydi). */
  @IsInt()
  delta!: number;
}
