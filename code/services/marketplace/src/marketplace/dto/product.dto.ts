import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { I18nStringDto } from './i18n-string.dto';

export class CreateProductDto {
  @IsOptional()
  @IsString()
  categoryId?: string;

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
