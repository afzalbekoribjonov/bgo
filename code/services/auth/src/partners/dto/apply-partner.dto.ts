import { IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class ApplyPartnerDto {
  @IsString()
  @MinLength(3)
  @MaxLength(120)
  fullName!: string;

  @IsIn(['RESTAURANT', 'DRIVER'])
  type!: 'RESTAURANT' | 'DRIVER';

  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
