import {
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { OtpService } from '../otp/otp.service';
import { SmsService } from '../sms/sms.service';
import { TelegramService } from '../telegram/telegram.service';
import { UserEntity } from '../users/user.entity';
import { UserRepository } from '../users/user.repository';
import { AccessTokenPayload, RefreshTokenPayload } from '@beshariq/nest-auth';

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly users: UserRepository,
    private readonly otp: OtpService,
    private readonly sms: SmsService,
    private readonly telegram: TelegramService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  /**
   * OTP so'rash. Kanal tanlash: foydalanuvchi raqamini Telegram bot'ga ulagan
   * bo'lsa — kod Telegram orqali (BEPUL), aks holda SMS (zaxira).
   */
  async requestOtp(
    phone: string,
  ): Promise<{
    channel: 'telegram' | 'sms';
    devCode?: string;
    telegramBotUrl?: string;
  }> {
    const code = await this.otp.generate(phone);

    let channel: 'telegram' | 'sms' = 'sms';
    if (this.telegram.isEnabled) {
      const chatId = await this.telegram.findChatId(phone);
      if (chatId && (await this.telegram.sendCode(chatId, code))) {
        channel = 'telegram';
      }
    }
    if (channel === 'sms') {
      await this.sms.sendOtp(phone, code);
    }

    const devCode =
      this.sms.isDevMode || this.telegram.isEnabled ? code : undefined;
    return {
      channel,
      ...(devCode ? { devCode } : {}),
      // Telegramga ulanmagan bo'lsa — bepul kanal uchun bot havolasini taklif qilamiz
      ...(channel === 'sms' && this.telegram.botUrl
        ? { telegramBotUrl: this.telegram.botUrl }
        : {}),
    };
  }

  /** OTP tasdiqlash — foydalanuvchini topadi/yaratadi va tokenlar beradi. */
  async verifyOtp(phone: string, code: string) {
    await this.otp.verify(phone, code);

    let user = await this.users.findByPhone(phone);
    let isNew = false;
    if (!user) {
      user = await this.users.create({ phone });
      isNew = true;
      this.logger.log(`Yangi foydalanuvchi: ${phone}`);
    }

    if (user.isBlocked) {
      throw new ForbiddenException(
        user.blockedReason
          ? `Hisobingiz bloklangan: ${user.blockedReason}`
          : 'Hisobingiz bloklangan. Administratorlarga murojaat qiling.',
      );
    }

    user = await this.ensureSeededRoles(user);

    const tokens = await this.issueTokens(user);
    return { ...tokens, user: this.sanitize(user), isNew };
  }

  /** ADMIN_PHONES ro'yxatidagi raqamga 'admin' rolini avtomatik beradi (bootstrap). */
  private async ensureSeededRoles(user: UserEntity): Promise<UserEntity> {
    const adminPhones = (this.config.get<string>('ADMIN_PHONES') ?? '')
      .split(',')
      .map((p) => p.trim())
      .filter(Boolean);
    if (adminPhones.includes(user.phone) && !user.roles.includes('admin')) {
      const updated = await this.users.update(user.id, {
        roles: [...user.roles, 'admin'],
      });
      this.logger.log(`Admin roli berildi (bootstrap): ${user.phone}`);
      return updated;
    }
    return user;
  }

  /** Barcha foydalanuvchilar (admin). */
  async listUsers() {
    const users = await this.users.findAll();
    return users.map((u) => this.sanitize(u));
  }

  /** Foydalanuvchi rollarini o'rnatish (admin). */
  async setRoles(userId: string, roles: string[]) {
    const existing = await this.users.findById(userId);
    if (!existing) throw new NotFoundException('Foydalanuvchi topilmadi');
    const user = await this.users.update(userId, { roles });
    return this.sanitize(user);
  }

  /** Refresh token bilan yangi tokenlar olish. */
  async refresh(refreshToken: string) {
    let payload: RefreshTokenPayload;
    try {
      payload = await this.jwt.verifyAsync<RefreshTokenPayload>(refreshToken, {
        secret: this.config.get<string>('JWT_REFRESH_SECRET'),
      });
    } catch {
      throw new UnauthorizedException('Refresh token yaroqsiz');
    }
    const user = await this.users.findById(payload.sub);
    if (!user) throw new UnauthorizedException('Foydalanuvchi topilmadi');
    return this.issueTokens(user);
  }

  async getMe(userId: string) {
    const user = await this.users.findById(userId);
    if (!user) throw new UnauthorizedException('Foydalanuvchi topilmadi');
    return this.sanitize(user);
  }

  /** Maxfiylik roziligini saqlash. */
  async saveConsent(userId: string, privacy: boolean, version: string) {
    const user = await this.users.update(userId, {
      consent: { privacy, version, acceptedAt: new Date().toISOString() },
    });
    return this.sanitize(user);
  }

  private async issueTokens(user: UserEntity): Promise<TokenPair> {
    const accessPayload: AccessTokenPayload = {
      sub: user.id,
      phone: user.phone,
      roles: user.roles,
    };
    const refreshPayload: RefreshTokenPayload = { sub: user.id, type: 'refresh' };

    const accessToken = await this.jwt.signAsync(accessPayload, {
      secret: this.config.get<string>('JWT_ACCESS_SECRET'),
      expiresIn: this.config.get<string>('JWT_ACCESS_TTL') ?? '30m',
    });
    const refreshToken = await this.jwt.signAsync(refreshPayload, {
      secret: this.config.get<string>('JWT_REFRESH_SECRET'),
      expiresIn: this.config.get<string>('JWT_REFRESH_TTL') ?? '30d',
    });
    return { accessToken, refreshToken };
  }

  private sanitize(user: UserEntity) {
    return {
      id: user.id,
      phone: user.phone,
      fullName: user.fullName ?? null,
      locale: user.locale,
      roles: user.roles,
      hasConsent: Boolean(user.consent?.privacy),
    };
  }
}
