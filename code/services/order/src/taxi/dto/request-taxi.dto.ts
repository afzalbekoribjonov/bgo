import { Type } from 'class-transformer';
import {
  IsNotEmpty,
  IsNumber,
  IsObject,
  IsString,
  Max,
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

export class RequestTaxiDto {
  @IsObject()
  @ValidateNested()
  @Type(() => GeoPointDto)
  pickup!: GeoPointDto;

  @IsObject()
  @ValidateNested()
  @Type(() => GeoPointDto)
  destination!: GeoPointDto;
}
