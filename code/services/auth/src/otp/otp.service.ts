import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash, randomInt } from 'node:crypto';
import { PrismaService } from '../prisma/prisma.service';

/**
 * Bir martalik kod (OTP) yaratish va tekshirish.
 * Kod ochiq saqlanmaydi (sha256 hash). DB'da (otp_codes) — auth xizmati
 * bir nechta mashinada parallel ishlashi mumkinligi sababli xotirada
 * saqlash yaroqsiz (so'ragan va tekshiruvchi so'rov boshqa-boshqa
 * mashinaga tushishi mumkin).
 */
@Injectable()
export class OtpService {
  private readonly length: number;
  private readonly ttlSeconds: number;
  private readonly maxAttempts: number;

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {
    this.length = Number(this.config.get('OTP_LENGTH') ?? 6);
    this.ttlSeconds = Number(this.config.get('OTP_TTL_SECONDS') ?? 120);
    this.maxAttempts = Number(this.config.get('OTP_MAX_ATTEMPTS') ?? 5);
  }

  /** Yangi kod yaratib saqlaydi va ochiq kodni qaytaradi (SMS yuborish uchun). */
  async generate(phone: string): Promise<string> {
    const max = 10 ** this.length;
    const code = randomInt(0, max).toString().padStart(this.length, '0');
    const data = {
      codeHash: this.hash(code),
      expiresAt: new Date(Date.now() + this.ttlSeconds * 1000),
      attempts: 0,
    };
    await this.prisma.otpCode.upsert({
      where: { phone },
      create: { phone, ...data },
      update: data,
    });
    return code;
  }

  /** Kodni tekshiradi. Muvaffaqiyatda yozuvni o'chiradi. */
  async verify(phone: string, code: string): Promise<void> {
    const record = await this.prisma.otpCode.findUnique({ where: { phone } });
    if (!record) {
      throw new BadRequestException('Kod so\'ralmagan yoki muddati tugagan');
    }
    if (Date.now() > record.expiresAt.getTime()) {
      await this.prisma.otpCode.delete({ where: { phone } }).catch(() => undefined);
      throw new BadRequestException('Kod muddati tugagan');
    }
    if (record.attempts >= this.maxAttempts) {
      await this.prisma.otpCode.delete({ where: { phone } }).catch(() => undefined);
      throw new BadRequestException('Urinishlar soni tugadi, qaytadan kod so\'rang');
    }
    if (record.codeHash !== this.hash(code)) {
      await this.prisma.otpCode.update({
        where: { phone },
        data: { attempts: { increment: 1 } },
      });
      throw new BadRequestException('Kod noto\'g\'ri');
    }
    await this.prisma.otpCode.delete({ where: { phone } });
  }

  private hash(code: string): string {
    return createHash('sha256').update(code).digest('hex');
  }
}
