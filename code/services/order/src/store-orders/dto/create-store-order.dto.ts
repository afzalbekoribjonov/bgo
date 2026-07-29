import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateIf,
  ValidateNested,
} from 'class-validator';

export class StoreOrderAddressDto {
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

export class StoreOrderItemDto {
  @IsString()
  @IsNotEmpty()
  productId!: string;

  @IsInt()
  @Min(1)
  qty!: number;

  /** Tanlangan o'lcham — mahsulotda o'lchamlar bo'lsa majburiy (server tekshiradi). */
  @IsOptional()
  @IsString()
  @MaxLength(20)
  size?: string;
}

export class CreateStoreOrderDto {
  @IsString()
  @IsNotEmpty()
  pickupLocationId!: string;

  @IsIn(['DELIVERY', 'PICKUP'])
  deliveryMethod!: 'DELIVERY' | 'PICKUP';

  @ValidateIf((o: CreateStoreOrderDto) => o.deliveryMethod === 'DELIVERY')
  @IsObject()
  @ValidateNested()
  @Type(() => StoreOrderAddressDto)
  address?: StoreOrderAddressDto;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => StoreOrderItemDto)
  items!: StoreOrderItemDto[];
}
