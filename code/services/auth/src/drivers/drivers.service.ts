import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { AccessTokenPayload, RefreshTokenPayload } from '@beshariq/nest-auth';
import { UserRepository } from '../users/user.repository';
import { NotificationService } from '../notifications/notification.service';
import {
  CreateDriverDto,
  SendDriverMessageDto,
  UpdateDriverDto,
} from './dto/driver.dto';
import { DriverProfileEntity } from './driver.entity';
import { DriverRepository } from './driver.repository';

/** Balans shu chegaradan past bo'lsa — ogohlantirish (so'm). */
const LOW_BALANCE_THRESHOLD = 2000;

@Injectable()
export class DriversService {
  private readonly logger = new Logger(DriversService.name);

  constructor(
    private readonly repo: DriverRepository,
    private readonly users: UserRepository,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly notifications: NotificationService,
  ) {}

  /**
   * Servislararo: bajarilgan buyurtma komissiyasini haydovchi balansidan
   * yechadi (manfiy topup). Balans pasaysa — bir martalik ogohlantirish.
   */
  async charge(
    userId: string,
    amount: number,
    note: string,
  ): Promise<{ balance: number }> {
    const profile = await this.repo.findByUserId(userId);
    if (!profile) return { balance: 0 };
    if (amount <= 0) return { balance: profile.balance };
    const updated = await this.repo.topup(profile.id, -amount, note);
    if (updated.balance < LOW_BALANCE_THRESHOLD) {
      await this.notifications
        .notifyUser(userId, {
          title: 'Balans kam qoldi',
          body: `Hisobingizda ${updated.balance.toLocaleString('ru-RU')} so'm qoldi. Liniyada qolish uchun hisobni to'ldiring.`,
          data: { type: 'balance_low', balance: String(updated.balance) },
        })
        .catch(() => undefined);
    }
    return { balance: updated.balance };
  }

  /**
   * Servislararo: haydovchiga SEZDIRMASDAN balans tuzatishi (masalan bekor
   * qilish jarimasi mijoz aybi bilan bo'lganda qaytariladi). Bildirishnoma
   * yuborilmaydi, tarix yozuvi `visible=false` — haydovchi "Hisobim"da
   * ko'rmaydi, faqat balans darhol to'g'ri bo'ladi.
   */
  async silentRefund(
    userId: string,
    amount: number,
    note: string,
  ): Promise<{ balance: number }> {
    const profile = await this.repo.findByUserId(userId);
    if (!profile) return { balance: 0 };
    if (amount <= 0) return { balance: profile.balance };
    const updated = await this.repo.topup(profile.id, amount, note, false);
    return { balance: updated.balance };
  }

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

  /** Hisobni to'ldirish (admin/office). */
  async topup(id: string, amount: number, note?: string) {
    await this.requireDriver(id);
    const updated = await this.repo.topup(id, amount, note);
    return this.toAdmin(updated);
  }

  /** Haydovchi balansi + to'ldirish tarixi (ilova — Hisobim). */
  async getBalance(phone: string) {
    const profile = await this.repo.findByPhone(phone);
    if (!profile) throw new NotFoundException('Haydovchi topilmadi');
    const topups = await this.repo.listTopups(profile.id);
    return { balance: profile.balance, topups };
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
    // Bloklangan haydovchi liniyaga chiqa olmaydi (offline bo'lishga ruxsat bor).
    if (isOnline && this.isCurrentlyBlocked(profile)) {
      throw new ForbiddenException({
        code: 'DRIVER_BLOCKED',
        message: 'Siz vaqtinchalik bloklangansiz.',
        reason: profile.blockReason ?? null,
        blockedUntil: profile.blockedUntil ?? null,
      });
    }
    // Balans 0 yoki manfiy bo'lsa — liniyaga chiqishga ruxsat berilmaydi.
    if (isOnline && profile.balance <= 0) {
      throw new ForbiddenException(
        'Balansingiz 0. Liniyaga chiqish uchun hisobni to‘ldiring.',
      );
    }
    const updated = await this.repo.update(profile.id, { isOnline });
    return this.toApp(updated);
  }

  private isCurrentlyBlocked(profile: DriverProfileEntity): boolean {
    return !!profile.blockedUntil && new Date(profile.blockedUntil) > new Date();
  }

  /** Admin: haydovchini ma'lum muddatga bloklaydi (sabab bilan). */
  async blockDriver(id: string, reason: string, minutes: number) {
    await this.requireDriver(id);
    const blockedUntil = new Date(Date.now() + minutes * 60_000);
    const updated = await this.repo.update(id, { blockedUntil, blockReason: reason });
    return this.toAdmin(updated);
  }

  /** Admin: blokdan darhol chiqarish (masalan ofisda jarima to'langach). */
  async unblockDriver(id: string) {
    await this.requireDriver(id);
    const updated = await this.repo.update(id, {
      blockedUntil: null,
      blockReason: null,
    });
    return this.toAdmin(updated);
  }

  /**
   * Servislararo: haydovchi buyurtmani bekor qildi — ketma-ket hisoblagichni
   * oshiradi (order servisi chaqiradi). Topilmasa jim o'tkaziladi.
   */
  async recordCancellation(userId: string): Promise<{ count: number }> {
    const profile = await this.repo.findByUserId(userId);
    if (!profile) return { count: 0 };
    const count = profile.consecutiveCancellations + 1;
    await this.repo.update(profile.id, { consecutiveCancellations: count });
    return { count };
  }

  /**
   * Servislararo: haydovchi buyurtmani muvaffaqiyatli yakunladi — ketma-ket
   * hisoblagich 0'ga tushadi (order servisi chaqiradi).
   */
  async recordCompletion(userId: string): Promise<void> {
    const profile = await this.repo.findByUserId(userId);
    if (!profile || profile.consecutiveCancellations === 0) return;
    await this.repo.update(profile.id, { consecutiveCancellations: 0 });
  }

  /**
   * Servislararo: ketma-ket `threshold`dan ortiq bekor qilgan haydovchilar
   * ro'yxati — order servisi "Shubhali haydovchilar" bilan birlashtiradi.
   */
  async listHighCancellationDrivers(threshold: number) {
    const all = await this.repo.findAll();
    return all
      .filter((d) => d.consecutiveCancellations > threshold)
      .map((d) => ({
        userId: d.userId,
        driverName: d.fullName,
        carName: d.carName,
        plateNumber: d.plateNumber,
        consecutiveCancellations: d.consecutiveCancellations,
      }))
      .sort((a, b) => b.consecutiveCancellations - a.consecutiveCancellations);
  }

  /** Joriy haydovchi profili (ilova — token egasiga). */
  async getByPhone(phone: string) {
    const profile = await this.repo.findByPhone(phone);
    if (!profile) throw new NotFoundException('Haydovchi topilmadi');
    return this.toApp(profile);
  }

  /**
   * Servislararo: haydovchining ommaviy ma'lumoti (userId bo'yicha) — order
   * servisi mijozga ko'rsatish uchun (ism, mashina). Topilmasa null.
   */
  async getPublicByUserId(userId: string) {
    const profile = await this.repo.findByUserId(userId);
    if (!profile) return null;
    return {
      fullName: profile.fullName,
      carName: profile.carName,
      carYear: profile.carYear,
      plateNumber: profile.plateNumber,
    };
  }

  /** Servislararo: bir nechta haydovchining ommaviy ma'lumoti (userId -> info) bitta so'rovda. */
  async getPublicByUserIds(userIds: string[]) {
    if (userIds.length === 0) return [];
    const profiles = await this.repo.findByUserIds(userIds);
    return profiles.map((profile) => ({
      userId: profile.userId,
      fullName: profile.fullName,
      carName: profile.carName,
      carYear: profile.carYear,
      plateNumber: profile.plateNumber,
    }));
  }

  /**
   * Servislararo: foydalanuvchi telefon raqami (userId bo'yicha) — suhbatdagi
   * qo'ng'iroq tugmasi uchun (mijoz yoki haydovchi raqami). Topilmasa null.
   */
  async getUserPhone(userId: string): Promise<{ phone: string | null }> {
    const user = await this.users.findById(userId);
    return { phone: user?.phone ?? null };
  }

  /**
   * Servislararo: Comfort tarifi yoqilgan haydovchilarning userId ro'yxati —
   * order servisi dispatch/pool filtrlashi uchun.
   */
  async comfortUserIds(): Promise<string[]> {
    const all = await this.repo.findAll();
    return all.filter((d) => d.isComfort && d.isActive).map((d) => d.userId);
  }

  // ---------- Xabarlar (admin → haydovchi) ----------

  /**
   * Admin xabar yuboradi: driverUserId berilsa — bitta haydovchiga,
   * bo'lmasa barcha haydovchilarga (broadcast). Push ham ketadi.
   */
  async sendMessage(dto: SendDriverMessageDto) {
    if (dto.driverUserId) {
      const profile = await this.repo.findByUserId(dto.driverUserId);
      if (!profile) throw new NotFoundException('Haydovchi topilmadi');
    }
    const msg = await this.repo.createMessage({
      driverUserId: dto.driverUserId ?? null,
      title: dto.title?.trim() || null,
      body: dto.body.trim(),
    });

    // Push — banner darhol ko'rinsin (xato bo'lsa xabar baribir saqlangan).
    const push = {
      title: msg.title ?? 'Beshariq — yangi xabar',
      body: msg.body,
      data: { type: 'driver_message', messageId: msg.id },
    };
    if (dto.driverUserId) {
      this.notifications.notifyUser(dto.driverUserId, push).catch(() => undefined);
    } else {
      const all = await this.repo.findAll();
      for (const d of all.filter((x) => x.isActive)) {
        this.notifications.notifyUser(d.userId, push).catch(() => undefined);
      }
    }
    return msg;
  }

  /** Admin: yuborilgan xabarlar tarixi (oxirgi 200). */
  async listSentMessages() {
    return this.repo.listAllMessages(200);
  }

  /**
   * Haydovchi: menga tegishli xabarlar (broadcast + shaxsiy, yangi birinchi)
   * + oxirgi o'qilgan payt (ilova "yangi" belgisini o'zi hisoblaydi).
   */
  async myMessages(userId: string) {
    const profile = await this.repo.findByUserId(userId);
    if (!profile) throw new NotFoundException('Haydovchi topilmadi');
    const messages = await this.repo.listMessagesFor(userId, 100);
    return { messages, readAt: profile.messagesReadAt ?? null };
  }

  /** Haydovchi: o'qilmagan xabarlar soni (qo'ng'iroqcha badge). */
  async unreadMessagesCount(userId: string): Promise<{ count: number }> {
    const profile = await this.repo.findByUserId(userId);
    if (!profile) return { count: 0 };
    const since = profile.messagesReadAt
      ? new Date(profile.messagesReadAt)
      : null;
    return { count: await this.repo.countMessagesSince(userId, since) };
  }

  /** Haydovchi: xabarlar ekrani ochildi — hammasi o'qilgan deb belgila. */
  async markMessagesRead(userId: string) {
    const profile = await this.repo.findByUserId(userId);
    if (!profile) throw new NotFoundException('Haydovchi topilmadi');
    await this.repo.markMessagesRead(profile.id);
    return { ok: true };
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
