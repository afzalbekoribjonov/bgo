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
  Min,
  ValidateNested,
} from 'class-validator';

export class OrderItemDto {
  @IsString()
  @IsNotEmpty()
  menuItemId!: string;

  @IsInt()
  @Min(1)
  qty!: number;
}

export class OrderAddressDto {
  @IsString()
  @IsNotEmpty()
  text!: string;

  @IsOptional()
  @IsNumber()
  lat?: number;

  @IsOptional()
  @IsNumber()
  lng?: number;
}

export class CreateOrderDto {
  // MVP: faqat ovqat
  @IsIn(['FOOD'])
  type!: 'FOOD';

  @IsString()
  @IsNotEmpty()
  restaurantId!: string;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  items!: OrderItemDto[];

  @IsObject()
  @ValidateNested()
  @Type(() => OrderAddressDto)
  address!: OrderAddressDto;

  // MVP: faqat naqd
  @IsIn(['CASH'])
  paymentType!: 'CASH';
}
