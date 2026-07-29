import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

/** Admin: mijozga (yoki barchaga) xabar yuborish. */
export class SendCustomerMessageDto {
  @IsOptional()
  @IsString()
  customerId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  title?: string;

  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  body!: string;
}

/** Admin: mijozni bloklash — sabab ko'rsatilishi shart. */
export class BlockCustomerDto {
  @IsString()
  @MinLength(3)
  @MaxLength(500)
  reason!: string;
}
