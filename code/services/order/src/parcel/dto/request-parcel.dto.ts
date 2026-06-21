import { Type } from 'class-transformer';
import {
  IsIn,
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

export class EstimateParcelDto {
  @IsObject()
  @ValidateNested()
  @Type(() => GeoPointDto)
  pickup!: GeoPointDto;

  @IsObject()
  @ValidateNested()
  @Type(() => GeoPointDto)
  destination!: GeoPointDto;

  @IsIn(['SMALL', 'MEDIUM', 'LARGE'])
  size!: 'SMALL' | 'MEDIUM' | 'LARGE';
}

export class RequestParcelDto extends EstimateParcelDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  recipientName!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(20)
  recipientPhone!: string;

  @IsOptional()
  @IsString()
  @MaxLength(300)
  note?: string;
}
