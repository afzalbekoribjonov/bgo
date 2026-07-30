export type TaxiStatus =
  | 'PENDING'
  | 'ACCEPTED'
  | 'ARRIVED'
  | 'IN_PROGRESS'
  | 'COMPLETED'
  | 'CANCELLED';

export interface GeoPoint {
  text: string;
  lat: number;
  lng: number;
}

export type StatusActor = 'customer' | 'driver' | 'admin' | 'system';

export interface TaxiStatusEntry {
  status: TaxiStatus;
  at: string;
  by?: StatusActor;
  /** Shu o'tishga aloqador haydovchi (haydovchi voz kechganda ham saqlanadi). */
  driverId?: string;
  reason?: string;
}

/** Tarif klassi: start (oddiy) | comfort (admin yoqqan mashinalar, qimmatroq). */
export type TaxiTariffClass = 'start' | 'comfort';

export interface TaxiTrip {
  id: string;
  publicNo: number;
  customerId: string;
  driverId?: string;
  pickup: GeoPoint;
  destination?: GeoPoint; // manzilsiz (metered) rejimda bo'sh
  metered: boolean;
  tariffClass: TaxiTariffClass;
  distanceKm: number;
  /** Haydovchi GPS orqali haqiqatda bosib o'tgan masofa (narxga ta'sir qilmaydi). */
  actualDistanceKm?: number;
  waitMinutes: number;
  /** Joriy kutish segmenti boshlangan vaqt (ISO) — null bo'lsa kutilmayapti. */
  waitStartedAt?: string | null;
  /** Jamlangan kutish (yopilgan segmentlar, soniya). */
  waitAccumSec: number;
  /** Haydovchi -> olib ketish nuqtasi masofasi (km, qabul paytida). */
  pickupDistanceKm: number;
  /** Olib ketish masofasi ustamasi (so'm). */
  pickupSurcharge: number;
  fare: number;
  commission: number;
  driverEarning: number;
  /** "Uyga" rejimi mos kelib biriktirilganmi — complete()da komissiya shu asosda qayta hisoblanadi. */
  homeModeMatch: boolean;
  status: TaxiStatus;
  paymentType: 'CASH';
  statusHistory: TaxiStatusEntry[];
  rating?: number;
  ratingComment?: string;
  createdAt: string;
  updatedAt: string;
}

/**
 * Jonli safar ko'rinishi — server tomonda hisoblangan (poll vaqtida).
 * Kutish yonayotgan bo'lsa current* qiymatlar real vaqtda o'sib boradi.
 */
export interface TaxiTripLive extends TaxiTrip {
  currentWaitMinutes: number; // hozirgacha pulli kutish (daqiqa, butun)
  currentWaitFee: number; // hozirgacha pulli kutish (so'm)
  currentFare: number; // hozirgi jami narx (base + ustama + kutish)
  durationMinutes: number; // safar davomiyligi (yakunda)
  waitFreeMin: number; // bepul kutish oynasi (daqiqa) — keyin pulli (tillo)
  // Biriktirilgan haydovchi ma'lumoti (faol safarda mijozga ko'rsatish uchun).
  driverName?: string | null;
  driverCar?: string | null;
  driverPlate?: string | null; // mashina raqami (o'xshash mashinalarni farqlash)
  driverPhone?: string | null; // mijoz suhbatda qo'ng'iroq qilishi uchun
  customerPhone?: string | null; // haydovchi suhbatda qo'ng'iroq qilishi uchun
  driverRating?: number; // o'rtacha baho (0 = hali baho yo'q)
  driverRatingCount?: number;
}

export interface NewTaxiTrip {
  customerId: string;
  pickup: GeoPoint;
  destination?: GeoPoint;
  metered: boolean;
  tariffClass: TaxiTariffClass;
  distanceKm: number;
  fare: number;
  commission: number;
  driverEarning: number;
}

/** Safarni yakunlash ma'lumotlari (metered: masofa; pulli kutish). */
export interface FinalizeTaxiTrip {
  distanceKm: number;
  waitMinutes: number;
  pickupSurcharge: number;
  fare: number;
  commission: number;
  driverEarning: number;
}

/** Qabul paytida olib ketish masofasi + ustamasi (fare o'zgarmaydi — yakunda qo'shiladi). */
export interface AssignPricing {
  pickupDistanceKm: number;
  pickupSurcharge: number;
  /**
   * "Uyga" rejimi mos kelsa qayta hisoblangan komissiya/haydovchi ulushi
   * (fare o'zgarmaydi — faqat platforma/haydovchi taqsimoti). Bo'lmasa
   * yaratilishdagi oddiy komissiya o'zgarishsiz qoladi.
   */
  commission?: number;
  driverEarning?: number;
  /** Qotirilib saqlanadi — complete()da komissiya shu asosda qayta hisoblanadi. */
  homeModeMatch?: boolean;
}

/** Admin statistika/hisobot uchun qisqartirilgan qator (select — pickup/destination/statusHistory'siz). */
export interface TaxiStatsRow {
  status: TaxiStatus;
  createdAt: string;
  fare: number;
  commission: number;
  driverId?: string;
}

/** Haydovchi daromadi/statistikasi uchun qisqartirilgan qator. */
export interface TaxiEarningsRow {
  status: TaxiStatus;
  createdAt: string;
  fare: number;
  driverEarning: number;
  updatedAt: string;
}

export type ChatRole = 'customer' | 'driver';

/** Taksi suhbat xabari (mijoz↔haydovchi). */
export interface TaxiMessage {
  id: string;
  tripId: string;
  senderId: string;
  senderRole: ChatRole;
  text: string;
  createdAt: string;
}

export interface NewTaxiMessage {
  tripId: string;
  senderId: string;
  senderRole: ChatRole;
  text: string;
}
