import { Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { TelegramRepository } from './telegram.repository';

/** Telegram raqamini standartlash: faqat raqamlar + boshida '+'. */
export function normalizePhone(raw: string): string {
  const digits = String(raw).replace(/[^\d]/g, '');
  return digits ? `+${digits}` : '';
}

interface TgUser {
  id?: number;
  username?: string;
}
interface TgMessage {
  chat?: { id?: number };
  from?: TgUser;
  text?: string;
  contact?: { phone_number?: string; user_id?: number };
}
interface TgUpdate {
  message?: TgMessage;
}

/**
 * Telegram bot orqali OTP yetkazish + telefon bog'lash. plan/10-auth-security.md
 * Dev rejimda (TELEGRAM_DEV_MODE=true) haqiqiy API chaqirilmaydi — log'ga chiqadi.
 * Jonli: TELEGRAM_ENABLED=true + TELEGRAM_BOT_TOKEN.
 */
@Injectable()
export class TelegramService {
  private readonly logger = new Logger(TelegramService.name);
  private readonly token?: string;
  private readonly botUsername?: string;
  private readonly webhookSecret?: string;
  private readonly live: boolean;
  private readonly devMode: boolean;

  constructor(
    private readonly config: ConfigService,
    private readonly repo: TelegramRepository,
  ) {
    this.token = config.get<string>('TELEGRAM_BOT_TOKEN');
    this.botUsername = config.get<string>('TELEGRAM_BOT_USERNAME');
    this.webhookSecret = config.get<string>('TELEGRAM_WEBHOOK_SECRET');
    this.devMode = String(config.get('TELEGRAM_DEV_MODE') ?? 'false') === 'true';
    this.live =
      String(config.get('TELEGRAM_ENABLED') ?? 'false') === 'true' &&
      !!this.token;
  }

  /** Telegram kanali umuman ishlatiladimi (dev yoki jonli). */
  get isEnabled(): boolean {
    return this.devMode || this.live;
  }

  /** Bot'ga ulanish havolasi (foydalanuvchi raqamini bog'lashi uchun). */
  get botUrl(): string | undefined {
    return this.botUsername
      ? `https://t.me/${this.botUsername}?start=otp`
      : undefined;
  }

  async findChatId(phone: string): Promise<string | null> {
    const link = await this.repo.findByPhone(phone);
    return link?.chatId ?? null;
  }

  /** OTP kodni Telegram orqali yuboradi. Muvaffaqiyatli bo'lsa true. */
  async sendCode(chatId: string, code: string): Promise<boolean> {
    const text = `🔐 Beshariq tasdiqlash kodi: ${code}\n\nKodni hech kimga bermang.`;
    return this.sendMessage(chatId, text);
  }

  /** Telegram webhook update'ini qayta ishlaydi (/start, raqam ulash). */
  async processUpdate(update: TgUpdate, secret?: string): Promise<void> {
    if (this.webhookSecret && secret !== this.webhookSecret) {
      throw new UnauthorizedException('Webhook secret noto‘g‘ri');
    }
    const msg = update?.message;
    if (!msg) return;
    const chatId = String(msg.chat?.id ?? msg.from?.id ?? '');
    if (!chatId) return;

    if (msg.text && msg.text.startsWith('/start')) {
      await this.requestContact(chatId);
      return;
    }

    if (msg.contact?.phone_number) {
      // Faqat o'z raqamini ulash mumkin
      if (
        msg.contact.user_id &&
        msg.from?.id &&
        msg.contact.user_id !== msg.from.id
      ) {
        await this.sendMessage(chatId, 'Iltimos, o‘z raqamingizni ulashing.');
        return;
      }
      const phone = normalizePhone(msg.contact.phone_number);
      if (!phone) return;
      await this.repo.upsert({ phone, chatId, username: msg.from?.username });
      this.logger.log(`Telegram bog'landi: ${phone} -> ${chatId}`);
      await this.sendMessage(
        chatId,
        '✅ Raqamingiz ulandi. Endi tasdiqlash kodlari shu yerga keladi (bepul).',
      );
    }
  }

  private async requestContact(chatId: string): Promise<void> {
    await this.sendMessage(
      chatId,
      'Salom! Beshariq kodlarini bepul olish uchun raqamingizni ulashing 👇',
      {
        keyboard: [[{ text: '📱 Raqamni ulashish', request_contact: true }]],
        resize_keyboard: true,
        one_time_keyboard: true,
      },
    );
  }

  private async sendMessage(
    chatId: string,
    text: string,
    replyMarkup?: unknown,
  ): Promise<boolean> {
    if (!this.live) {
      this.logger.warn(`📨 [DEV TELEGRAM] ${chatId} -> "${text}"`);
      return true;
    }
    try {
      const res = await fetch(
        `https://api.telegram.org/bot${this.token}/sendMessage`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            chat_id: chatId,
            text,
            reply_markup: replyMarkup,
          }),
        },
      );
      if (!res.ok) {
        this.logger.error(`Telegram sendMessage xato: ${res.status}`);
        return false;
      }
      return true;
    } catch (err) {
      this.logger.error(`Telegram ulanish xatosi: ${(err as Error).message}`);
      return false;
    }
  }
}
