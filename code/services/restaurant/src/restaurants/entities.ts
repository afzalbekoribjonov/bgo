import { I18nString } from '@beshariq/i18n';

export type RestaurantStatus = 'ACTIVE' | 'PENDING' | 'BLOCKED';

/** Oshxona. plan/03-databases.md (restaurant_db) */
export interface Restaurant {
  id: string;
  ownerUserId?: string;
  name: string; // brend nomi (odatda tarjima qilinmaydi)
  lat: number;
  lng: number;
  address: string;
  phone: string;
  status: RestaurantStatus;
  commissionPercent: number; // bizning ulush %
  isOpen: boolean;
  rating: number;
  logoUrl?: string;
  createdAt: string;
}

/** Menyu kategoriyasi (3 til). */
export interface Category {
  id: string;
  restaurantId: string;
  name: I18nString;
  sortOrder: number;
}

/** Taom (3 til, narx so'mda butun son). */
export interface MenuItem {
  id: string;
  restaurantId: string;
  categoryId: string;
  name: I18nString;
  description?: I18nString;
  price: number;
  imageUrl?: string;
  isAvailable: boolean;
  createdAt: string;
}
