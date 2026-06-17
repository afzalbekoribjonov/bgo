/**
 * Beshariq Super-App — umumiy tiplar.
 * Backend servislar va veb ilovalar shu yerdan foydalanadi.
 * Ma'lumot modeli: plan/03-databases.md · API: plan/14-api-design.md
 */

// ---- Xizmat turlari ----
export enum ServiceType {
  FOOD = 'FOOD',
  TAXI = 'TAXI',
  DELIVERY = 'DELIVERY',
}

// ---- Buyurtma holatlari (status mashinasi) ----
export enum OrderStatus {
  DRAFT = 'DRAFT',
  PENDING = 'PENDING',
  ACCEPTED = 'ACCEPTED',
  ASSIGNED = 'ASSIGNED',
  IN_PROGRESS = 'IN_PROGRESS',
  PICKED_UP = 'PICKED_UP',
  DELIVERED = 'DELIVERED',
  COMPLETED = 'COMPLETED',
  CLOSED = 'CLOSED',
  CANCELLED = 'CANCELLED',
  FAILED = 'FAILED',
}

// ---- Foydalanuvchi rollari (RBAC) ----
export enum UserRole {
  CUSTOMER = 'customer',
  DRIVER = 'driver',
  RESTAURANT = 'restaurant',
  OPERATOR = 'operator',
  ADMIN = 'admin',
  SUPER_ADMIN = 'super_admin',
}

// ---- To'lov turlari (MVP: naqd) ----
export enum PaymentType {
  CASH = 'CASH',
  PAYME = 'PAYME',
  CLICK = 'CLICK',
  UZUM = 'UZUM',
}

// ---- Tillar ----
export type Locale = 'uz' | 'uz-Cyrl' | 'ru';

/** Ko'p tilli matn (DB'da JSONB). Til: plan/13-localization.md */
export interface I18nText {
  uz: string;
  uz_cyrl?: string;
  ru?: string;
}

// ---- Geo ----
export interface GeoPoint {
  lat: number;
  lng: number;
}

// ---- Standart API javob formati (plan/14-api-design.md) ----
export interface ApiError {
  code: string;
  message: string;
  details?: unknown;
}

export interface ApiMeta {
  page: number;
  limit: number;
  total: number;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: ApiError;
  meta?: ApiMeta;
}
