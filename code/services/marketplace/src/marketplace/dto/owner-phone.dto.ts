import { IsNotEmpty, IsString, Matches } from 'class-validator';

const PHONE_RE = /^\+998\d{9}$/;

export class LookupOwnerDto {
  @IsString()
  @IsNotEmpty()
  @Matches(PHONE_RE, { message: "Telefon +998XXXXXXXXX formatida bo'lishi kerak" })
  phone!: string;
}

export class AssignOwnerByPhoneDto {
  @IsString()
  @IsNotEmpty()
  @Matches(PHONE_RE, { message: "Telefon +998XXXXXXXXX formatida bo'lishi kerak" })
  phone!: string;
}
