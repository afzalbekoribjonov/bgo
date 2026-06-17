import { IsString, Length, Matches } from 'class-validator';

export class VerifyOtpDto {
  @Matches(/^\+998\d{9}$/, {
    message: 'Telefon raqami +998XXXXXXXXX formatida bo\'lishi kerak',
  })
  phone!: string;

  @IsString()
  @Length(4, 8, { message: 'Kod 4-8 raqamdan iborat bo\'lishi kerak' })
  code!: string;
}
