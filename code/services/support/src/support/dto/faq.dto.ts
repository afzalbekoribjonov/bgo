import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsIn,
  IsInt,
  IsObject,
  IsOptional,
  Min,
  ValidateNested,
} from 'class-validator';
import { I18nStringDto } from './i18n-string.dto';

export class CreateFaqDto {
  @IsObject()
  @ValidateNested()
  @Type(() => I18nStringDto)
  label!: I18nStringDto;

  @IsObject()
  @ValidateNested()
  @Type(() => I18nStringDto)
  answer!: I18nStringDto;

  /** Bo'sh/berilmagan bo'lsa — ikkalasiga ham (mijoz VA haydovchi) ko'rsatiladi. */
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(2)
  @IsIn(['CUSTOMER', 'DRIVER'], { each: true })
  roles?: ('CUSTOMER' | 'DRIVER')[];

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;
}

export class UpdateFaqDto {
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => I18nStringDto)
  label?: I18nStringDto;

  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => I18nStringDto)
  answer?: I18nStringDto;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(2)
  @IsIn(['CUSTOMER', 'DRIVER'], { each: true })
  roles?: ('CUSTOMER' | 'DRIVER')[];

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
