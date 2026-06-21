import {
  IsBoolean,
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

export class CreateRestaurantDto {
  @IsString()
  @MinLength(2)
  @MaxLength(120)
  name!: string;

  @IsString()
  @MinLength(3)
  @MaxLength(200)
  address!: string;

  @IsString()
  @MinLength(5)
  @MaxLength(20)
  phone!: string;

  @IsOptional()
  @IsNumber()
  lat?: number;

  @IsOptional()
  @IsNumber()
  lng?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  commissionPercent?: number;

  @IsOptional()
  @IsBoolean()
  isOpen?: boolean;

  @IsOptional()
  @IsString()
  ownerUserId?: string;
}

export class UpdateRestaurantDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(120)
  name?: string;

  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(200)
  address?: string;

  @IsOptional()
  @IsString()
  @MinLength(5)
  @MaxLength(20)
  phone?: string;

  @IsOptional()
  @IsNumber()
  lat?: number;

  @IsOptional()
  @IsNumber()
  lng?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  commissionPercent?: number;

  @IsOptional()
  @IsBoolean()
  isOpen?: boolean;

  @IsOptional()
  @IsIn(['ACTIVE', 'PENDING', 'BLOCKED'])
  status?: 'ACTIVE' | 'PENDING' | 'BLOCKED';
}
