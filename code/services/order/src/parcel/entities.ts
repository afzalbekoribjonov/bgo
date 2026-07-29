import { GeoPoint } from '../common/geo';

export type ParcelStatus =
  | 'PENDING'
  | 'ACCEPTED'
  | 'ARRIVED'
  | 'PICKED_UP'
  | 'IN_TRANSIT'
  | 'DELIVERED'
  | 'CANCELLED';

export type ParcelSize = 'SMALL' | 'MEDIUM' | 'LARGE';

export type StatusActor = 'customer' | 'driver' | 'admin' | 'system';

export interface ParcelStatusEntry {
  status: ParcelStatus;
  at: string;
  by?: StatusActor;
  /** Shu o'tishga aloqador haydovchi (haydovchi voz kechganda ham saqlanadi). */
  driverId?: string;
  reason?: string;
}

export interface ParcelDelivery {
  id: string;
  publicNo: number;
  customerId: string;
  driverId?: string;
  pickup: GeoPoint;
  destination: GeoPoint;
  distanceKm: number;
  /** Kuryer GPS orqali haqiqatda bosib o'tgan masofa (narxga ta'sir qilmaydi). */
  actualDistanceKm?: number;
  size: ParcelSize;
  recipientName: string;
  recipientPhone: string;
  note?: string;
  fare: number;
  commission: number;
  driverEarning: number;
  status: ParcelStatus;
  paymentType: 'CASH';
  statusHistory: ParcelStatusEntry[];
  rating?: number;
  ratingComment?: string;
  createdAt: string;
  updatedAt: string;
}

/** Jonli ko'rinish — narx + biriktirilgan kuryer ma'lumoti (mijozga). */
export interface ParcelDeliveryLive extends ParcelDelivery {
  currentFare: number;
  durationMinutes: number;
  driverName?: string | null;
  driverCar?: string | null;
  driverPlate?: string | null;
  driverPhone?: string | null; // mijoz suhbatdan qo'ng'iroq qilishi uchun
  customerPhone?: string | null; // kuryer suhbatdan qo'ng'iroq qilishi uchun
  driverRating?: number;
  driverRatingCount?: number;
}

/** Admin statistika/hisobot uchun qisqartirilgan qator (select — pickup/destination/statusHistory'siz). */
export interface ParcelStatsRow {
  status: ParcelStatus;
  createdAt: string;
  fare: number;
  commission: number;
  driverId?: string;
}

/** Kuryer daromadi/statistikasi uchun qisqartirilgan qator. */
export interface ParcelEarningsRow {
  status: ParcelStatus;
  createdAt: string;
  fare: number;
  driverEarning: number;
  updatedAt: string;
}

export type ChatRole = 'customer' | 'driver';

/** Dostavka suhbat xabari (mijoz↔kuryer). */
export interface ParcelMessage {
  id: string;
  parcelId: string;
  senderId: string;
  senderRole: ChatRole;
  text: string;
  createdAt: string;
}

export interface NewParcelMessage {
  parcelId: string;
  senderId: string;
  senderRole: ChatRole;
  text: string;
}

export interface NewParcelDelivery {
  customerId: string;
  pickup: GeoPoint;
  destination: GeoPoint;
  distanceKm: number;
  size: ParcelSize;
  recipientName: string;
  recipientPhone: string;
  note?: string;
  fare: number;
  commission: number;
  driverEarning: number;
}
