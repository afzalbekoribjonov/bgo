import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

const PHONE = /^\+998\d{9}$/;
const PHONE_MSG = "Telefon raqami +998XXXXXXXXX formatida bo'lishi kerak";

/** Admin: yangi haydovchi qo'shish. */
export class CreateDriverDto {
  @Matches(PHONE, { message: PHONE_MSG })
  phone!: string;

  @IsString()
  @MinLength(3)
  @MaxLength(120)
  fullName!: string;

  @IsOptional()
  @IsInt()
  @Min(18)
  @Max(100)
  age?: number;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  carName?: string;

  @IsOptional()
  @IsInt()
  @Min(1970)
  @Max(2100)
  carYear?: number;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  plateNumber?: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  licenseInfo?: string;
}

/** Admin: haydovchi ma'lumotlarini yangilash. */
export class UpdateDriverDto {
  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(120)
  fullName?: string;

  @IsOptional()
  @IsInt()
  @Min(18)
  @Max(100)
  age?: number;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  carName?: string;

  @IsOptional()
  @IsInt()
  @Min(1970)
  @Max(2100)
  carYear?: number;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  plateNumber?: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  licenseInfo?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

/** Haydovchi ilovasi: raqam haydovchimi? */
export class DriverCheckDto {
  @Matches(PHONE, { message: PHONE_MSG })
  phone!: string;
}

/** Haydovchi ilovasi: telefon + 8 xonali kod bilan kirish. */
export class DriverLoginDto {
  @Matches(PHONE, { message: PHONE_MSG })
  phone!: string;

  @Matches(/^\d{8}$/, { message: "Kod 8 xonali bo'lishi kerak" })
  code!: string;
}

/** Haydovchi ilovasi: onlayn/oflayn holatni o'zgartirish. */
export class DriverStatusDto {
  @IsBoolean()
  isOnline!: boolean;
}

/** Admin: haydovchi hisobini to'ldirish. */
export class TopupDto {
  @IsInt()
  @Min(1000)
  @Max(100000000)
  amount!: number;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  note?: string;
}
