import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import { DeviceTokenRepository } from './device-token.repository';
import {
  DevicePlatform,
  DeviceToken,
  NotificationPayload,
  NotificationResult,
} from './notification.types';

/** FCM eskirgan/yaroqsiz token xato kodlari — bunda tokenni tozalaymiz. */
const STALE_TOKEN_ERRORS = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

/**
 * Push bildirishnomalar (FCM, firebase-admin SDK). plan/10-auth-security.md
 * Dev rejimda (FCM_DEV_MODE=true, standart) haqiqiy FCM chaqirilmaydi — log'ga
 * chiqadi va yetkazilgan token soni qaytadi (e2e tekshira oladi).
 * Jonli: FCM_ENABLED=true + FCM_SERVICE_ACCOUNT (service account JSON yo'li).
 * SDK access tokenni avtomatik yaratadi (1 soatlik eskirish muammosi yo'q).
 */
@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);
  private readonly serviceAccountPath?: string;
  private readonly live: boolean;
  private readonly devMode: boolean;
  private app?: admin.app.App;

  constructor(
    private readonly config: ConfigService,
    private readonly repo: DeviceTokenRepository,
  ) {
    this.serviceAccountPath = config.get<string>('FCM_SERVICE_ACCOUNT');
    this.devMode = String(config.get('FCM_DEV_MODE') ?? 'true') === 'true';
    this.live = String(config.get('FCM_ENABLED') ?? 'false') === 'true';
  }

  /** Dev rejimda yuborilgan xabarlar (e2e introspeksiyasi uchun, RAM). */
  private readonly recent: Array<{
    userId: string;
    title: string;
    body: string;
    delivered: number;
    at: string;
  }> = [];

  get isEnabled(): boolean {
    return this.devMode || this.live;
  }

  /** Dev introspeksiya — foydalanuvchiga yuborilgan oxirgi xabarlar. */
  recentFor(userId: string) {
    return this.recent.filter((r) => r.userId === userId);
  }

  registerToken(
    userId: string,
    token: string,
    platform: DevicePlatform,
  ): Promise<DeviceToken> {
    return this.repo.upsert(userId, token, platform);
  }

  unregisterToken(userId: string, token: string): Promise<void> {
    return this.repo.deleteByToken(userId, token);
  }

  listTokens(userId: string): Promise<DeviceToken[]> {
    return this.repo.findByUser(userId);
  }

  /** Foydalanuvchining barcha qurilmalariga push yuboradi. */
  async notifyUser(
    userId: string,
    payload: NotificationPayload,
  ): Promise<NotificationResult> {
    const tokens = (await this.repo.findByUser(userId)).map((t) => t.token);
    const result =
      tokens.length === 0
        ? ({ delivered: 0, channel: 'none' } as NotificationResult)
        : await this.sendPush(tokens, payload);
    // Dev introspeksiya — trigger ishlaganini e2e tekshira oladi
    if (this.devMode) {
      this.recent.push({
        userId,
        title: payload.title,
        body: payload.body,
        delivered: result.delivered,
        at: new Date().toISOString(),
      });
      if (this.recent.length > 200) this.recent.shift();
    }
    return result;
  }

  /** firebase-admin App'ni lazy-init qiladi (service account JSON'dan). */
  private messaging(): admin.messaging.Messaging | null {
    if (this.app) return this.app.messaging();
    if (!this.serviceAccountPath) {
      this.logger.error("FCM jonli: FCM_SERVICE_ACCOUNT yo'li sozlanmagan");
      return null;
    }
    const path = resolve(this.serviceAccountPath);
    if (!existsSync(path)) {
      this.logger.error(`FCM jonli: service account fayli topilmadi: ${path}`);
      return null;
    }
    try {
      const sa = JSON.parse(readFileSync(path, 'utf8')) as admin.ServiceAccount;
      this.app = admin.initializeApp(
        { credential: admin.credential.cert(sa) },
        'beshariq',
      );
      this.logger.log('FCM (firebase-admin) ishga tushdi');
      return this.app.messaging();
    } catch (err) {
      this.logger.error(`FCM init xatosi: ${(err as Error).message}`);
      return null;
    }
  }

  private async sendPush(
    tokens: string[],
    payload: NotificationPayload,
  ): Promise<NotificationResult> {
    if (!this.live) {
      this.logger.warn(
        `📲 [DEV PUSH] ${tokens.length} ta qurilma -> "${payload.title}: ${payload.body}"`,
      );
      return { delivered: tokens.length, channel: 'dev' };
    }
    const messaging = this.messaging();
    if (!messaging) return { delivered: 0, channel: 'fcm' };

    try {
      const res = await messaging.sendEachForMulticast({
        tokens,
        notification: { title: payload.title, body: payload.body },
        data: payload.data ?? {},
      });
      // Eskirgan/yaroqsiz tokenlarni tozalaymiz
      res.responses.forEach((r, i) => {
        if (!r.success && r.error && STALE_TOKEN_ERRORS.has(r.error.code)) {
          this.repo.removeToken(tokens[i]).catch(() => {});
        }
      });
      return { delivered: res.successCount, channel: 'fcm' };
    } catch (err) {
      this.logger.error(`FCM yuborish xatosi: ${(err as Error).message}`);
      return { delivered: 0, channel: 'fcm' };
    }
  }
}
