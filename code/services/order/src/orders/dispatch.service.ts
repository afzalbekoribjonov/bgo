import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { haversineKm } from '../common/geo';
import { DriverLocationService } from '../tracking/driver-location.service';

export type DispatchVertical = 'food' | 'taxi' | 'parcel';

/** Buyurtma taklifi (haydovchiga yuboriladigan ma'lumot). */
export interface DispatchOffer {
  orderId: string;
  vertical: DispatchVertical;
  pickupLat: number;
  pickupLng: number;
  pickupName: string;
  dropoffLat?: number | null;
  dropoffLng?: number | null;
  dropoffText?: string | null;
  amount: number; // buyurtma narxi
  earning: number; // haydovchi ulushi
}

interface OfferState extends DispatchOffer {
  offeredTo: string | null;
  expiresAt: number; // ms
  tried: Set<string>;
  attempt: number; // nechta haydovchiga taklif qilindi
  status: 'offering' | 'pool';
  createdAt: number;
}

/**
 * Buyurtmani eng yaqin online haydovchiga 20s ga taklif qiladi; olmasa keyingi
 * eng yaqiniga; 2 marta olinmasa "pool" (hammaga ko'rinadi). plan/06-driver-app.md
 * In-memory (bitta instans, MVP).
 */
@Injectable()
export class DispatchService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(DispatchService.name);
  private readonly offers = new Map<string, OfferState>();
  private timer?: ReturnType<typeof setInterval>;

  static readonly OFFER_SEC = 20;
  static readonly MAX_ATTEMPTS = 2; // 2 ta haydovchiga, keyin pool

  constructor(private readonly tracking: DriverLocationService) {}

  onModuleInit() {
    this.timer = setInterval(() => {
      this.sweep().catch((e) =>
        this.logger.warn(`Dispatch sweep xatosi: ${(e as Error).message}`),
      );
    }, 2000);
  }

  onModuleDestroy() {
    if (this.timer) clearInterval(this.timer);
  }

  /** Yangi buyurtma — eng yaqin haydovchiga taklif qiladi. */
  async offer(data: DispatchOffer): Promise<void> {
    if (this.offers.has(data.orderId)) return;
    const state: OfferState = {
      ...data,
      offeredTo: null,
      expiresAt: 0,
      tried: new Set<string>(),
      attempt: 0,
      status: 'offering',
      createdAt: Date.now(),
    };
    this.offers.set(data.orderId, state);
    await this.assignNext(state);
    this.logger.log(
      `Dispatch: #${data.orderId} -> ${state.offeredTo ?? 'pool'} (${state.status})`,
    );
  }

  /** Keyingi eng yaqin haydovchiga taklif (yoki pool'ga). */
  private async assignNext(state: OfferState): Promise<void> {
    if (state.attempt >= DispatchService.MAX_ATTEMPTS) {
      state.status = 'pool';
      state.offeredTo = null;
      return;
    }
    const ids = await this.tracking.nearestDriverIds(
      state.pickupLat,
      state.pickupLng,
      state.tried,
    );
    if (ids.length === 0) {
      state.status = 'pool';
      state.offeredTo = null;
      return;
    }
    state.offeredTo = ids[0];
    state.attempt += 1;
    state.expiresAt = Date.now() + DispatchService.OFFER_SEC * 1000;
    state.status = 'offering';
  }

  /** Muddati o'tgan takliflarni keyingisiga/pool'ga o'tkazadi. */
  private async sweep(): Promise<void> {
    for (const state of this.offers.values()) {
      if (state.status === 'offering' && Date.now() > state.expiresAt) {
        if (state.offeredTo) state.tried.add(state.offeredTo);
        await this.assignNext(state);
      }
    }
  }

  /** Haydovchiga hozir taklif qilingan buyurtma (masofa + qolgan vaqt bilan). */
  async getOfferFor(
    driverId: string,
  ): Promise<(DispatchOffer & { distanceKm: number; secondsLeft: number }) | null> {
    for (const s of this.offers.values()) {
      if (
        s.status === 'offering' &&
        s.offeredTo === driverId &&
        Date.now() < s.expiresAt
      ) {
        const loc = await this.tracking.get(driverId);
        const distanceKm = loc
          ? Math.round(
              haversineKm(
                { text: '', lat: loc.lat, lng: loc.lng },
                { text: '', lat: s.pickupLat, lng: s.pickupLng },
              ) * 10,
            ) / 10
          : 0;
        return {
          ...this.toOffer(s),
          distanceKm,
          secondsLeft: Math.max(0, Math.ceil((s.expiresAt - Date.now()) / 1000)),
        };
      }
    }
    return null;
  }

  /** Pool (qabul qilinmagan) buyurtmalar — hammaga. */
  pool(): DispatchOffer[] {
    return [...this.offers.values()]
      .filter((s) => s.status === 'pool')
      .sort((a, b) => b.createdAt - a.createdAt)
      .map((s) => this.toOffer(s));
  }

  /** Buyurtma taklifi (vertikalni bilish uchun). */
  getById(orderId: string): DispatchOffer | null {
    const s = this.offers.get(orderId);
    return s ? this.toOffer(s) : null;
  }

  /** Haydovchi shu buyurtmani qabul qila oladimi (taklif yoki pool). */
  canAccept(driverId: string, orderId: string): boolean {
    const s = this.offers.get(orderId);
    if (!s) return false;
    if (s.status === 'pool') return true;
    return s.offeredTo === driverId && Date.now() < s.expiresAt;
  }

  /** Haydovchi o'tkazib yubordi — darhol keyingisiga. */
  async skip(driverId: string, orderId: string): Promise<void> {
    const s = this.offers.get(orderId);
    if (!s || s.offeredTo !== driverId) return;
    s.tried.add(driverId);
    await this.assignNext(s);
  }

  /** Buyurtma biriktirildi/yopildi — dispatchdan olib tashlaymiz. */
  clear(orderId: string): void {
    this.offers.delete(orderId);
  }

  private toOffer(s: OfferState): DispatchOffer {
    return {
      orderId: s.orderId,
      vertical: s.vertical,
      pickupLat: s.pickupLat,
      pickupLng: s.pickupLng,
      pickupName: s.pickupName,
      dropoffLat: s.dropoffLat ?? null,
      dropoffLng: s.dropoffLng ?? null,
      dropoffText: s.dropoffText ?? null,
      amount: s.amount,
      earning: s.earning,
    };
  }
}
