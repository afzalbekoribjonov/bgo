import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DeviceTokenRepository } from './device-token.repository';
import {
  DevicePlatform,
  DeviceToken,
  NotificationPayload,
  NotificationResult,
} from './notification.types';

/**
 * Push bildirishnomalar (FCM). plan/10-auth-security.md
 * Dev rejimda (FCM_DEV_MODE=true, standart) haqiqiy FCM chaqirilmaydi — log'ga
 * chiqadi va yetkazilgan token soni qaytadi (e2e tekshira oladi).
 * Jonli: FCM_ENABLED=true + FCM_PROJECT_ID (+ FCM_ACCESS_TOKEN — service account
 * OAuth2 access token, deploy bosqichida olinadi).
 */
@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);
  private readonly projectId?: string;
  private readonly accessToken?: string;
  private readonly live: boolean;
  private readonly devMode: boolean;

  constructor(
    private readonly config: ConfigService,
    private readonly repo: DeviceTokenRepository,
  ) {
    this.projectId = config.get<string>('FCM_PROJECT_ID');
    this.accessToken = config.get<string>('FCM_ACCESS_TOKEN');
    this.devMode = String(config.get('FCM_DEV_MODE') ?? 'true') === 'true';
    this.live =
      String(config.get('FCM_ENABLED') ?? 'false') === 'true' &&
      !!this.projectId;
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
    let delivered = 0;
    for (const token of tokens) {
      if (await this.sendOne(token, payload)) delivered++;
    }
    return { delivered, channel: 'fcm' };
  }

  /** Bitta tokenga FCM HTTP v1 orqali yuboradi. */
  private async sendOne(
    token: string,
    payload: NotificationPayload,
  ): Promise<boolean> {
    if (!this.accessToken) {
      this.logger.error(
        "FCM jonli rejim: FCM_ACCESS_TOKEN yo'q (service account OAuth2 kerak)",
      );
      return false;
    }
    try {
      const res = await fetch(
        `https://fcm.googleapis.com/v1/projects/${this.projectId}/messages:send`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${this.accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: {
              token,
              notification: { title: payload.title, body: payload.body },
              data: payload.data ?? {},
            },
          }),
        },
      );
      // Token eskirgan/yaroqsiz — tozalaymiz
      if (res.status === 404 || res.status === 410) {
        await this.repo.removeToken(token);
        return false;
      }
      if (!res.ok) {
        this.logger.error(`FCM xato: ${res.status}`);
        return false;
      }
      return true;
    } catch (err) {
      this.logger.error(`FCM ulanish xatosi: ${(err as Error).message}`);
      return false;
    }
  }
}
