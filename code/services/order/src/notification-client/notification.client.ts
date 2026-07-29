import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/** Android push yetkazish sozlamasi (yuqori muhimlik / data-only). */
export interface AndroidPushOptions {
  priority?: 'high' | 'normal';
  channelId?: string;
  dataOnly?: boolean;
}

/**
 * Auth servisining push (FCM) endpointiga xabar yuboradi (servislararo).
 * BEST-EFFORT: xato bo'lsa ham buyurtma/safar oqimini TO'XTATMAYDI (log + qaytadi).
 * plan/10-auth-security.md
 */
@Injectable()
export class NotificationClient {
  private readonly logger = new Logger(NotificationClient.name);
  private readonly baseUrl: string;
  private readonly key?: string;
  /** Osilib qolgan ichki chaqiruv butun so'rovni cheksiz ushlab turmasin. */
  private static readonly FETCH_TIMEOUT_MS = 5_000;

  constructor(config: ConfigService) {
    this.baseUrl =
      config.get<string>('AUTH_SERVICE_URL') ?? 'http://localhost:4001';
    this.key = config.get<string>('INTERNAL_API_KEY');
  }

  /** Foydalanuvchiga push yuboradi (xato bo'lsa jim log qiladi). */
  async notify(
    userId: string,
    title: string,
    body: string,
    data?: Record<string, string>,
    android?: AndroidPushOptions,
  ): Promise<void> {
    if (!userId) return;
    if (!this.key) {
      this.logger.warn("INTERNAL_API_KEY yo'q — push o'tkazib yuborildi");
      return;
    }
    try {
      const res = await fetch(
        `${this.baseUrl}/api/v1/internal/notifications/send`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-internal-key': this.key,
          },
          body: JSON.stringify({ userId, title, body, data, android }),
          signal: AbortSignal.timeout(NotificationClient.FETCH_TIMEOUT_MS),
        },
      );
      if (!res.ok) this.logger.warn(`Push yuborilmadi: ${res.status}`);
    } catch (err) {
      this.logger.warn(
        `Push xizmatiga ulanib bo'lmadi: ${(err as Error).message}`,
      );
    }
  }
}
