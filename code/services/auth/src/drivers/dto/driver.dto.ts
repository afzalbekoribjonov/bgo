import {
  IsBoolean,
  IsInt,
  IsNumber,
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

  /** Comfort tarifi — faqat admin yoqadi/o'chiradi. */
  @IsOptional()
  @IsBoolean()
  isComfort?: boolean;

  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(5)
  rating?: number;
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

/** Haydovchi ilovasi: uy manzilini belgilash/o'zgartirish ("Uyga" rejimi). */
export class SetDriverHomeDto {
  @IsNumber()
  @Min(-90)
  @Max(90)
  lat!: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  lng!: number;

  @IsString()
  @MinLength(1)
  @MaxLength(300)
  address!: string;
}

/** Haydovchi ilovasi: "Uyga" rejimini yoqish/o'chirish. */
export class SetHomeModeDto {
  @IsBoolean()
  active!: boolean;
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

/** Admin: haydovchini ma'lum muddatga bloklash. */
export class BlockDriverDto {
  @IsString()
  @MinLength(3)
  @MaxLength(500)
  reason!: string;

  /** Necha daqiqaga (masalan 1440 = 1 kun). */
  @IsInt()
  @Min(5)
  @Max(43200) // 30 kun
  minutes!: number;
}

/** Admin: haydovchi(lar)ga xabar yuborish. driverUserId yo'q = hammaga. */
export class SendDriverMessageDto {
  @IsOptional()
  @IsString()
  driverUserId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  title?: string;

  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  body!: string;
}
