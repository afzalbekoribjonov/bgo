// ⚠️ ZAHIRA KOD (reserve) — onlayn to'lov registri. HOZIR HECH QAYERGA ULANMAGAN.
// To'lov hozir faqat NAQD (CASH). Onlayn yoqilganda (PAYMENTS_ONLINE_ENABLED=true)
// bu xizmat OrdersModule'ga provider sifatida qo'shiladi va webhook controller ulanadi.

import { ClickProvider, PaymeProvider, PaynetProvider } from './providers';
import {
  PaymentProvider,
  PaymentProviderName,
  PayoutProvider,
} from './payment.types';

/**
 * Provayderni nomi bo'yicha tanlaydi. Onlayn to'lov o'chiq bo'lsa (default),
 * tanlash mumkin emas — faqat NAQD ishlaydi (order servisida paymentType=CASH).
 */
export class PaymentService {
  private readonly online =
    String(process.env.PAYMENTS_ONLINE_ENABLED ?? 'false') === 'true';

  private readonly providers: Record<
    PaymentProviderName,
    PaymentProvider & PayoutProvider
  > = {
    CLICK: new ClickProvider(),
    PAYME: new PaymeProvider(),
    PAYNET: new PaynetProvider(),
  };

  get isOnlineEnabled(): boolean {
    return this.online;
  }

  getProvider(name: PaymentProviderName): PaymentProvider & PayoutProvider {
    if (!this.online) {
      throw new Error(
        "[reserve] Onlayn to'lov o'chirilgan. Hozir faqat naqd (CASH).",
      );
    }
    return this.providers[name];
  }
}
