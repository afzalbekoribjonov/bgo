import { IsBoolean, IsLatitude, IsLongitude, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreatePickupLocationDto {
  @IsString()
  @IsNotEmpty()
  name!: string;

  @IsString()
  @IsNotEmpty()
  address!: string;

  @IsLatitude()
  lat!: number;

  @IsLongitude()
  lng!: number;
}

export class UpdatePickupLocationDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  name?: string;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  address?: string;

  @IsOptional()
  @IsLatitude()
  lat?: number;

  @IsOptional()
  @IsLongitude()
  lng?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
