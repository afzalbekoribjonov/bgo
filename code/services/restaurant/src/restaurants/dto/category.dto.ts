import { Type } from 'class-transformer';
import { IsInt, IsObject, IsOptional, Min, ValidateNested } from 'class-validator';
import { I18nStringDto } from './i18n-string.dto';

export class CreateCategoryDto {
  @IsObject()
  @ValidateNested()
  @Type(() => I18nStringDto)
  name!: I18nStringDto;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;
}

export class UpdateCategoryDto {
  @IsOptional()
  @ValidateNested()
  @Type(() => I18nStringDto)
  name?: I18nStringDto;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;
}
