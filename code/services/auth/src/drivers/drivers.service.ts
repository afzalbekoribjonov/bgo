import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { AccessTokenPayload, RefreshTokenPayload } from '@beshariq/nest-auth';
import { UserRepository } from '../users/user.repository';
import { CreateDriverDto, UpdateDriverDto } from './dto/driver.dto';
import { DriverProfileEntity } from './driver.entity';
import { DriverRepository } from './driver.repository';

@Injectable()
export class DriversService {
  private readonly logger = new Logger(DriversService.name);

  constructor(
    private readonly repo: DriverRepository,
    private readonly users: UserRepository,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  // ---------- Admin ----------

  /** Yangi haydovchi: foydalanuvchi (driver roli) + profil + 8 xonali kod. */
  async createDriver(dto: CreateDriverDto) {
    const existing = await this.repo.findByPhone(dto.phone);
    if (existing) {
      throw new BadRequestException(
        "Bu raqam allaqachon haydovchi sifatida ro'yxatda",
      );
    }

    let user = await this.users.findByPhone(dto.phone);
    if (user) {
      if (!user.roles.includes('driver')) {
        user = await this.users.update(user.id, {
          roles: [...user.roles, 'driver'],
        });
      }
    } else {
      user = await this.users.create({ phone: dto.phone });
      user = await this.users.update(user.id, {
        roles: [...user.roles, 'driver'],
      });
      this.logger.log(`Yangi haydovchi foydalanuvchisi: ${dto.phone}`);
    }

    const profile = await this.repo.create({
      userId: user.id,
      phone: dto.phone,
      fullName: dto.fullName,
      age: dto.age ?? null,
      carName: dto.carName ?? null,
      carYear: dto.carYear ?? null,
      plateNumber: dto.plateNumber ?? null,
      licenseInfo: dto.licenseInfo ?? null,
      loginCode: this.genCode(),
    });
    return this.toAdmin(profile);
  }

  async listDrivers() {
    const drivers = await this.repo.findAll();
    return drivers.map((d) => this.toAdmin(d));
  }

  async getDriver(id: string) {
    return this.toAdmin(await this.requireDriver(id));
  }

  async updateDriver(id: string, dto: UpdateDriverDto) {
    await this.requireDriver(id);
    const updated = await this.repo.update(id, dto);
    return this.toAdmin(updated);
  }

  /** Yangi 8 xonali kod (admin haydovchiga uzatadi). */
  async regenerateCode(id: string) {
    await this.requireDriver(id);
    const updated = await this.repo.update(id, { loginCode: this.genCode() });
    return this.toAdmin(updated);
  }

  // ---------- Haydovchi ilovasi ----------

  /** Raqam bizning haydovchimi (login inputi uchun). */
  async checkPhone(phone: string): Promise<{ exists: boolean }> {
    const profile = await this.repo.findByPhone(phone);
    return { exists: Boolean(profile && profile.isActive) };
  }

  /** Telefon + 8 xonali kod bilan kirish — uzoq muddatli token. */
  async login(phone: string, code: string) {
    const profile = await this.repo.findByPhone(phone);
    if (!profile) {
      throw new UnauthorizedException('Siz bizning haydovchi emassiz');
    }
    if (!profile.isActive) {
      throw new UnauthorizedException('Hisobingiz faol emas, admin bilan bog‘laning');
    }
    if (profile.loginCode !== code) {
      throw new UnauthorizedException("Kod noto'g'ri");
    }
    const user = await this.users.findById(profile.userId);
    if (!user) throw new UnauthorizedException('Foydalanuvchi topilmadi');

    const tokens = await this.issueDriverTokens(
      user.id,
      user.phone,
      user.roles,
    );
    return {
      ...tokens,
      driver: this.toApp(profile),
      user: {
        id: user.id,
        phone: user.phone,
        fullName: user.fullName ?? profile.fullName,
        roles: user.roles,
      },
    };
  }

  /** Onlayn/oflayn holat (Liniyaga chiqish / Ishni yakunlash). */
  async setOnline(phone: string, isOnline: boolean) {
    const profile = await this.repo.findByPhone(phone);
    if (!profile) throw new NotFoundException('Haydovchi topilmadi');
    const updated = await this.repo.update(profile.id, { isOnline });
    return this.toApp(updated);
  }

  /** Joriy haydovchi profili (ilova — token egasiga). */
  async getByPhone(phone: string) {
    const profile = await this.repo.findByPhone(phone);
    if (!profile) throw new NotFoundException('Haydovchi topilmadi');
    return this.toApp(profile);
  }

  // ---------- yordamchilar ----------

  private async requireDriver(id: string): Promise<DriverProfileEntity> {
    const driver = await this.repo.findById(id);
    if (!driver) throw new NotFoundException('Haydovchi topilmadi');
    return driver;
  }

  private genCode(): string {
    return String(Math.floor(10000000 + Math.random() * 90000000));
  }

  private async issueDriverTokens(
    userId: string,
    phone: string,
    roles: string[],
  ) {
    const accessPayload: AccessTokenPayload = { sub: userId, phone, roles };
    const refreshPayload: RefreshTokenPayload = { sub: userId, type: 'refresh' };
    // Haydovchi sessiyasi ilova o'chirilmaguncha saqlanadi — uzoq TTL.
    const ttl = this.config.get<string>('JWT_DRIVER_TTL') ?? '3650d';
    const accessToken = await this.jwt.signAsync(accessPayload, {
      secret: this.config.get<string>('JWT_ACCESS_SECRET'),
      expiresIn: ttl,
    });
    const refreshToken = await this.jwt.signAsync(refreshPayload, {
      secret: this.config.get<string>('JWT_REFRESH_SECRET'),
      expiresIn: ttl,
    });
    return { accessToken, refreshToken };
  }

  /** Admin ko'rinishi — 8 xonali kod bilan (admin haydovchiga uzatadi). */
  private toAdmin(d: DriverProfileEntity) {
    return { ...d };
  }

  /** Ilova ko'rinishi — kodni qaytarmaydi. */
  private toApp(d: DriverProfileEntity) {
    const { loginCode: _loginCode, ...rest } = d;
    return rest;
  }
}
