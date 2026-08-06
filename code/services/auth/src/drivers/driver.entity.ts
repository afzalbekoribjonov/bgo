/** Haydovchi profili (auth_db). Admin qo'shadi, 8 xonali kod bilan login. */
export interface DriverProfileEntity {
  id: string;
  userId: string;
  phone: string;
  fullName: string;
  age?: number | null;
  carName?: string | null;
  carYear?: number | null;
  plateNumber?: string | null;
  licenseInfo?: string | null;
  loginCode: string;
  isActive: boolean;
  isOnline: boolean;
  /** Comfort tarifi yoqilganmi (faqat admin boshqaradi). */
  isComfort: boolean;
  balance: number;
  rating: number;
  /** Nechta mijoz bahosi asosida `rating` hisoblangan (og'irlik-o'rtacha uchun). */
  ratingCount: number;
  /** Xabarlar oxirgi o'qilgan payt (null — hech qachon ochilmagan). */
  messagesReadAt?: string | null;
  /** Vaqtinchalik bloklash — o'tmishda/null bo'lsa bloklanmagan. */
  blockedUntil?: string | null;
  blockReason?: string | null;
  /** Ketma-ket bekor qilingan buyurtmalar — muvaffaqiyatli yakunda 0'ga tushadi. */
  consecutiveCancellations: number;
  /** "Uyga" rejimi — uy manzili (belgilanmagan bo'lsa null). */
  homeLat?: number | null;
  homeLng?: number | null;
  homeAddress?: string | null;
  isHomeModeActive: boolean;
  createdAt: string;
  updatedAt: string;
}

/** Admin → haydovchi xabari (driverUserId null = hammaga). */
export interface DriverMessageEntity {
  id: string;
  driverUserId?: string | null;
  title?: string | null;
  body: string;
  createdAt: string;
}

/** Yangi xabar (repo). */
export interface NewDriverMessage {
  driverUserId?: string | null;
  title?: string | null;
  body: string;
}

/** Hisob to'ldirish yozuvi. */
export interface DriverTopupEntity {
  id: string;
  driverId: string;
  amount: number;
  note?: string | null;
  createdAt: string;
}

/** Yangi haydovchi yaratish uchun ma'lumot (repo). */
export interface NewDriverProfile {
  userId: string;
  phone: string;
  fullName: string;
  age?: number | null;
  carName?: string | null;
  carYear?: number | null;
  plateNumber?: string | null;
  licenseInfo?: string | null;
  loginCode: string;
}

/** Tahrirlanadigan maydonlar. */
export type DriverProfilePatch = Partial<
  Omit<NewDriverProfile, 'userId' | 'phone'>
> & {
  isActive?: boolean;
  isOnline?: boolean;
  isComfort?: boolean;
  rating?: number;
  /** `null` — blokdan darhol chiqarish. */
  blockedUntil?: Date | null;
  blockReason?: string | null;
  consecutiveCancellations?: number;
  homeLat?: number | null;
  homeLng?: number | null;
  homeAddress?: string | null;
  isHomeModeActive?: boolean;
};
