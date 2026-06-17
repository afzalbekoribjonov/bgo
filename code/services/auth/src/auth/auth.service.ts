import { Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { OtpService } from '../otp/otp.service';
import { SmsService } from '../sms/sms.service';
import { UserEntity } from '../users/user.entity';
import { UserRepository } from '../users/user.repository';
import { AccessTokenPayload, RefreshTokenPayload } from './jwt-payload.interface';

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
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  /** OTP so'rash — kod yaratiladi va (dev'da logga) yuboriladi. */
  async requestOtp(phone: string): Promise<{ devCode?: string }> {
    const code = this.otp.generate(phone);
    await this.sms.sendOtp(phone, code);
    // Dev rejimda kodni javobda ham qaytaramiz (test qulayligi uchun).
    return this.sms.isDevMode ? { devCode: code } : {};
  }

  /** OTP tasdiqlash — foydalanuvchini topadi/yaratadi va tokenlar beradi. */
  async verifyOtp(phone: string, code: string) {
    this.otp.verify(phone, code);

    let user = await this.users.findByPhone(phone);
    let isNew = false;
    if (!user) {
      user = await this.users.create({ phone });
      isNew = true;
      this.logger.log(`Yangi foydalanuvchi: ${phone}`);
    }

    const tokens = await this.issueTokens(user);
    return { ...tokens, user: this.sanitize(user), isNew };
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
