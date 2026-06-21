export type TaxiStatus =
  | 'PENDING'
  | 'ACCEPTED'
  | 'IN_PROGRESS'
  | 'COMPLETED'
  | 'CANCELLED';

export interface GeoPoint {
  text: string;
  lat: number;
  lng: number;
}

export interface TaxiStatusEntry {
  status: TaxiStatus;
  at: string;
}

export interface TaxiTrip {
  id: string;
  publicNo: number;
  customerId: string;
  driverId?: string;
  pickup: GeoPoint;
  destination: GeoPoint;
  distanceKm: number;
  fare: number;
  commission: number;
  driverEarning: number;
  status: TaxiStatus;
  paymentType: 'CASH';
  statusHistory: TaxiStatusEntry[];
  createdAt: string;
}

export interface NewTaxiTrip {
  customerId: string;
  pickup: GeoPoint;
  destination: GeoPoint;
  distanceKm: number;
  fare: number;
  commission: number;
  driverEarning: number;
}
