import { IsOptional, IsString, MinLength } from 'class-validator';

/** Ko'p tilli matn DTO (kamida uz to'ldiriladi). plan/13-localization.md */
export class I18nStringDto {
  @IsString()
  @MinLength(1)
  uz!: string;

  @IsOptional()
  @IsString()
  uz_Cyrl?: string;

  @IsOptional()
  @IsString()
  ru?: string;
}
