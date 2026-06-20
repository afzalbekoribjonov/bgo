// ⚠️ ZAHIRA KOD (reserve) — kelajakda onlayn to'lov uchun. plan/11-pricing-promo.md
// Hozir to'lov FAQAT NAQD (CASH). Bu interfeyslar hech qayerga ulanmagan va
// foydalanuvchiga ko'rinmaydi. Onlayn to'lov yoqilganda (PAYMENTS_ONLINE_ENABLED)
// shu abstraksiya ishlatiladi — keyin alohida Payment servisiga ko'chiriladi.

export type PaymentProviderName = 'CLICK' | 'PAYME' | 'PAYNET';

export interface ChargeRequest {
  orderId: string;
  amount: number; // so'm
  returnUrl?: string;
}

export interface ChargeResult {
  providerRef: string; // provayder tranzaksiya id'si
  payUrl?: string; // foydalanuvchini yo'naltirish uchun (bo'lsa)
}

export interface WebhookResult {
  orderId: string;
  paid: boolean;
  providerRef: string;
}

/** Onlayn to'lov provayderi (mijoz buyurtma uchun to'laydi). */
export interface PaymentProvider {
  readonly name: PaymentProviderName;
  /** To'lovni boshlaydi (provayderda tranzaksiya yaratadi). */
  createCharge(req: ChargeRequest): Promise<ChargeResult>;
  /** Provayder webhook'ini tekshiradi (imzo) va natijani qaytaradi. */
  verifyWebhook(payload: unknown, signature?: string): Promise<WebhookResult>;
}

// --- Payout (yechib olish) — haydovchi/oshxonaga pul o'tkazish ---

export type PayeeType = 'DRIVER' | 'RESTAURANT';

export interface PayoutRequest {
  payeeType: PayeeType;
  payeeId: string;
  amount: number; // so'm
  cardToken?: string; // saqlangan karta (keyin)
}

export interface PayoutResult {
  payoutRef: string;
  status: 'PENDING' | 'SENT' | 'FAILED';
}

/** Payout provayderi (Click/Payme/Paynet orqali yechib olish). */
export interface PayoutProvider {
  readonly name: PaymentProviderName;
  createPayout(req: PayoutRequest): Promise<PayoutResult>;
}
