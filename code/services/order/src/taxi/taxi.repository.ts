import {
  AssignPricing,
  FinalizeTaxiTrip,
  NewTaxiTrip,
  StatusActor,
  TaxiStatus,
  TaxiTrip,
} from './entities';

export interface UpdateStatusMeta {
  by?: StatusActor;
  driverId?: string;
  reason?: string;
}

/** Taksi safari repository interfeysi (abstrakt). */
export abstract class TaxiRepository {
  abstract create(data: NewTaxiTrip): Promise<TaxiTrip>;
  abstract findById(id: string): Promise<TaxiTrip | null>;
  /** Barcha safarlar (admin hisobot uchun). */
  abstract findAll(): Promise<TaxiTrip[]>;
  abstract findByCustomer(customerId: string): Promise<TaxiTrip[]>;
  abstract findByDriver(driverId: string): Promise<TaxiTrip[]>;
  /** Bitta safar — haydovchi + publicNo bo'yicha to'g'ridan-to'g'ri (AI shikoyat qidiruvi). */
  abstract findByDriverAndPublicNo(driverId: string, publicNo: number): Promise<TaxiTrip | null>;
  /** Yangi (PENDING), hali haydovchi biriktirilmagan safarlar. */
  abstract findAvailable(): Promise<TaxiTrip[]>;
  /**
   * Haydovchini biriktiradi va ACCEPTED holatga o'tkazadi. pricing berilsa —
   * olib ketish ustamasi bilan narx/masofa ham yangilanadi.
   */
  abstract assignDriver(
    id: string,
    driverId: string,
    pricing?: AssignPricing,
  ): Promise<TaxiTrip>;
  abstract updateStatus(
    id: string,
    status: TaxiStatus,
    meta?: UpdateStatusMeta,
  ): Promise<TaxiTrip>;
  /** Olib ketish nuqtasiga yetib keldi: ARRIVED + kutishni avtomatik boshlash. */
  abstract markArrived(id: string): Promise<TaxiTrip>;
  /** Kutish holatini o'rnatish — joriy segment (Date|null) + jamlangan soniya. */
  abstract setWaiting(
    id: string,
    startedAt: Date | null,
    accumSec: number,
  ): Promise<TaxiTrip>;
  /** Safarni boshlash: IN_PROGRESS + jamlangan kutish (soniya) + segmentni yopish. */
  abstract beginTrip(id: string, accumSec: number): Promise<TaxiTrip>;
  /** Biriktirilgan haydovchini bo'shatib, PENDING'ga qaytaradi (haydovchi bekor qildi). */
  abstract releaseToPending(
    id: string,
    reason?: string,
    note?: string,
  ): Promise<TaxiTrip>;
  /** Safarni yakunlash — yakuniy narx/masofa/kutish. */
  abstract finalize(id: string, data: FinalizeTaxiTrip): Promise<TaxiTrip>;
  /** Mijoz bahosi (1-5) + izoh. */
  abstract setRating(
    id: string,
    rating: number,
    comment?: string,
  ): Promise<TaxiTrip>;
  /** Haydovchining o'rtacha bahosi va baholar soni (yakunlangan safarlardan). */
  abstract driverRatingStats(
    driverId: string,
  ): Promise<{ avg: number; count: number }>;
}
