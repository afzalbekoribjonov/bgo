import {
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

/** Servislararo (internal) push yuborish so'rovi. */
export class SendNotificationDto {
  @IsString()
  @IsNotEmpty()
  userId!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  title!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  body!: string;

  /** FCM data — qiymatlar string bo'lishi shart. */
  @IsOptional()
  @IsObject()
  data?: Record<string, string>;
}
