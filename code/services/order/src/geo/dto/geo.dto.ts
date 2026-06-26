import {
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateAreaDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  name!: string;

  @IsNumber()
  @Min(-90)
  @Max(90)
  centerLat!: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  centerLng!: number;

  /** GeoJSON Polygon koordinatalari: [[[lng,lat],...]] */
  @IsArray()
  boundary!: number[][][];

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdateAreaDto {
  @IsOptional()
  @IsString()
  @MaxLength(120)
  name?: string;

  @IsOptional()
  @IsNumber()
  centerLat?: number;

  @IsOptional()
  @IsNumber()
  centerLng?: number;

  @IsOptional()
  @IsArray()
  boundary?: number[][][];

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class CreatePlaceDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  label!: string;

  @IsNumber()
  @Min(-90)
  @Max(90)
  lat!: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  lng!: number;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  category?: string;

  @IsOptional()
  @IsInt()
  sortOrder?: number;
}

export class CreateRoadDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  name!: string;

  @IsIn(['street', 'main', 'center'])
  kind!: 'street' | 'main' | 'center';

  /** Yo'l chizig'i nuqtalari: [[lat,lng], ...] (kamida 2 ta). */
  @IsArray()
  @ArrayMinSize(2)
  points!: number[][];
}
