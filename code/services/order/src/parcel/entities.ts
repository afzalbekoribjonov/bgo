import { GeoPoint } from '../common/geo';

export type ParcelStatus =
  | 'PENDING'
  | 'ACCEPTED'
  | 'PICKED_UP'
  | 'DELIVERED'
  | 'CANCELLED';

export type ParcelSize = 'SMALL' | 'MEDIUM' | 'LARGE';

export interface ParcelStatusEntry {
  status: ParcelStatus;
  at: string;
}

export interface ParcelDelivery {
  id: string;
  publicNo: number;
  customerId: string;
  driverId?: string;
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
  status: ParcelStatus;
  paymentType: 'CASH';
  statusHistory: ParcelStatusEntry[];
  createdAt: string;
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
