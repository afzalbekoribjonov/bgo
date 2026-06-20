// ⚠️ ZAHIRA KOD (reserve) — provayder stublari. Hali implementatsiya qilinmagan.
// Har biri yoqilganda haqiqiy API bilan to'ldiriladi (Merchant API'lar).

import {
  ChargeRequest,
  ChargeResult,
  PaymentProvider,
  PaymentProviderName,
  PayoutProvider,
  PayoutRequest,
  PayoutResult,
  WebhookResult,
} from './payment.types';

const NOT_IMPLEMENTED = (name: string): never => {
  throw new Error(
    `[reserve] ${name} to'lov provayderi hali ulanmagan (PAYMENTS_ONLINE_ENABLED=false)`,
  );
};

/** Click — https://docs.click.uz (Merchant API). TODO: implementatsiya. */
export class ClickProvider implements PaymentProvider, PayoutProvider {
  readonly name: PaymentProviderName = 'CLICK';
  async createCharge(_req: ChargeRequest): Promise<ChargeResult> {
    return NOT_IMPLEMENTED('Click');
  }
  async verifyWebhook(_payload: unknown, _sig?: string): Promise<WebhookResult> {
    return NOT_IMPLEMENTED('Click');
  }
  async createPayout(_req: PayoutRequest): Promise<PayoutResult> {
    return NOT_IMPLEMENTED('Click payout');
  }
}

/** Payme — https://developer.help.paycom.uz (Merchant API). TODO. */
export class PaymeProvider implements PaymentProvider, PayoutProvider {
  readonly name: PaymentProviderName = 'PAYME';
  async createCharge(_req: ChargeRequest): Promise<ChargeResult> {
    return NOT_IMPLEMENTED('Payme');
  }
  async verifyWebhook(_payload: unknown, _sig?: string): Promise<WebhookResult> {
    return NOT_IMPLEMENTED('Payme');
  }
  async createPayout(_req: PayoutRequest): Promise<PayoutResult> {
    return NOT_IMPLEMENTED('Payme payout');
  }
}

/** Paynet — https://paynet.uz (Merchant API). TODO. */
export class PaynetProvider implements PaymentProvider, PayoutProvider {
  readonly name: PaymentProviderName = 'PAYNET';
  async createCharge(_req: ChargeRequest): Promise<ChargeResult> {
    return NOT_IMPLEMENTED('Paynet');
  }
  async verifyWebhook(_payload: unknown, _sig?: string): Promise<WebhookResult> {
    return NOT_IMPLEMENTED('Paynet');
  }
  async createPayout(_req: PayoutRequest): Promise<PayoutResult> {
    return NOT_IMPLEMENTED('Paynet payout');
  }
}
