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
  createdAt: string;
  updatedAt: string;
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
};
