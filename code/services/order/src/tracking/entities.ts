/** Haydovchi/kuryerning eng oxirgi jonli joylashuvi. */
export interface DriverLocation {
  driverId: string;
  lat: number;
  lng: number;
  heading?: number; // harakat yo'nalishi (gradus)
  updatedAt: string;
}

export interface NewDriverLocation {
  lat: number;
  lng: number;
  heading?: number;
}

/** Yaqin (online) haydovchi — anonim (driverId qaytarilmaydi). */
export interface NearbyDriver {
  lat: number;
  lng: number;
  heading?: number;
  distanceKm: number;
  ageSeconds: number;
}
