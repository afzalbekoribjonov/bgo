/** Foydalanuvchi (auth doirasida). To'liq profil — User servisida (Faza 1B). */
export interface Consent {
  privacy: boolean;
  version: string;
  acceptedAt: string;
}

export interface UserEntity {
  id: string;
  phone: string;
  fullName?: string;
  locale: string;
  roles: string[];
  consent?: Consent;
  createdAt: string;
}
