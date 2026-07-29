import {
  BadRequestException,
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash, randomInt } from 'node:crypto';

interface OtpRecord {
  codeHash: string;
  expiresAt: number;
  attempts: number;
}

/**
 * Bir martalik kod (OTP) yaratish va tekshirish.
 * Kod ochiq saqlanmaydi (sha256 hash). Dev'da xotirada — keyin Redis (TTL).
 * Har 5 daqiqada muddati o'tgan yozuvlar tozalanadi (xotira sizmasligi uchun).
 */
@Injectable()
export class OtpService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(OtpService.name);
  private readonly store = new Map<string, OtpRecord>();
  private cleanupTimer?: ReturnType<typeof setInterval>;

  private readonly length: number;
  private readonly ttlSeconds: number;
  private readonly maxAttempts: number;

  constructor(private readonly config: ConfigService) {
    this.length = Number(this.config.get('OTP_LENGTH') ?? 6);
    this.ttlSeconds = Number(this.config.get('OTP_TTL_SECONDS') ?? 120);
    this.maxAttempts = Number(this.config.get('OTP_MAX_ATTEMPTS') ?? 5);
  }

  onModuleInit() {
    this.cleanupTimer = setInterval(() => this.purgeExpired(), 5 * 60 * 1000);
  }

  onModuleDestroy() {
    if (this.cleanupTimer) clearInterval(this.cleanupTimer);
  }

  private purgeExpired() {
    const now = Date.now();
    let removed = 0;
    for (const [phone, r] of this.store) {
      if (now > r.expiresAt) {
        this.store.delete(phone);
        removed++;
      }
    }
    if (removed > 0) this.logger.debug(`OTP: ${removed} ta muddati o'tgan yozuv tozalandi`);
  }

  /** Yangi kod yaratib saqlaydi va ochiq kodni qaytaradi (SMS yuborish uchun). */
  generate(phone: string): string {
    const max = 10 ** this.length;
    const code = randomInt(0, max).toString().padStart(this.length, '0');
    this.store.set(phone, {
      codeHash: this.hash(code),
      expiresAt: Date.now() + this.ttlSeconds * 1000,
      attempts: 0,
    });
    return code;
  }

  /** Kodni tekshiradi. Muvaffaqiyatda yozuvni o'chiradi. */
  verify(phone: string, code: string): void {
    const record = this.store.get(phone);
    if (!record) {
      throw new BadRequestException('Kod so\'ralmagan yoki muddati tugagan');
    }
    if (Date.now() > record.expiresAt) {
      this.store.delete(phone);
      throw new BadRequestException('Kod muddati tugagan');
    }
    if (record.attempts >= this.maxAttempts) {
      this.store.delete(phone);
      throw new BadRequestException('Urinishlar soni tugadi, qaytadan kod so\'rang');
    }
    if (record.codeHash !== this.hash(code)) {
      record.attempts += 1;
      throw new BadRequestException('Kod noto\'g\'ri');
    }
    this.store.delete(phone);
  }

  private hash(code: string): string {
    return createHash('sha256').update(code).digest('hex');
  }
}
