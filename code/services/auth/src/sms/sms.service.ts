import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * SMS yuborish. Dev rejimda (SMS_DEV_MODE=true) kod faqat logga chiqadi —
 * haqiqiy SMS yuborilmaydi (test uchun qulay, pul ketmaydi).
 * TODO(Faza 1D): Eskiz.uz integratsiyasi (plan/10-auth-security.md).
 */
@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);
  private readonly devMode: boolean;

  constructor(private readonly config: ConfigService) {
    this.devMode = String(this.config.get('SMS_DEV_MODE') ?? 'true') === 'true';
  }

  get isDevMode(): boolean {
    return this.devMode;
  }

  async sendOtp(phone: string, code: string): Promise<void> {
    const message = `Beshariq tasdiqlash kodi: ${code}`;
    if (this.devMode) {
      this.logger.warn(`📱 [DEV SMS] ${phone} -> "${message}"`);
      return;
    }
    // TODO: Eskiz.uz API orqali yuborish
    this.logger.error('SMS provayder (Eskiz) hali ulanmagan — SMS_DEV_MODE=true qiling');
    throw new Error('SMS provider not configured');
  }
}
