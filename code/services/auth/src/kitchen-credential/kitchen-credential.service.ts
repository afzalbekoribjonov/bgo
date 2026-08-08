import {
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import {
  randomBytes,
  scryptSync,
  timingSafeEqual,
} from 'node:crypto';
import { AccessTokenPayload } from '@beshariq/nest-auth';
import { PrismaService } from '../prisma/prisma.service';

/**
 * Oshxona paneli login/parol kirishi. Parol scrypt bilan xeshlanadi
 * (native bog'liqliksiz). Kirishda JWT (role 'restaurant' + restaurantId).
 */
@Injectable()
export class KitchenCredentialService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  private hash(password: string): string {
    const salt = randomBytes(16).toString('hex');
    const derived = scryptSync(password, salt, 32).toString('hex');
    return `${salt}:${derived}`;
  }

  private verifyHash(password: string, stored: string): boolean {
    const [salt, hash] = stored.split(':');
    if (!salt || !hash) return false;
    const derived = scryptSync(password, salt, 32);
    const expected = Buffer.from(hash, 'hex');
    return (
      derived.length === expected.length && timingSafeEqual(derived, expected)
    );
  }

  /** Admin: oshxonaga login/parol o'rnatadi (yangilaydi). */
  async setCredential(restaurantId: string, username: string, password: string) {
    const passwordHash = this.hash(password);
    const cred = await this.prisma.kitchenCredential.upsert({
      where: { restaurantId },
      update: { username, passwordHash },
      create: { restaurantId, username, passwordHash },
    });
    return { restaurantId: cred.restaurantId, username: cred.username };
  }

  /** Admin: oshxona kirish ma'lumoti bor-yo'qligi. */
  async getInfo(restaurantId: string) {
    const cred = await this.prisma.kitchenCredential.findUnique({
      where: { restaurantId },
    });
    return {
      exists: !!cred,
      username: cred?.username ?? null,
    };
  }

  /**
   * Oshxona o'chirilganda kirish ma'lumotini ham tozalaydi — aks holda
   * mavjud bo'lmagan restaurantId'ga ishora qiluvchi login abadiy qolib
   * ketardi. `deleteMany` — qator bo'lmasa ham xato bermaydi (idempotent).
   */
  async deleteCredential(restaurantId: string): Promise<void> {
    await this.prisma.kitchenCredential.deleteMany({ where: { restaurantId } });
  }

  /** Sayt kirishi: login/parol -> JWT (role 'restaurant', restaurantId claim). */
  async login(username: string, password: string) {
    const cred = await this.prisma.kitchenCredential.findUnique({
      where: { username },
    });
    if (!cred || !this.verifyHash(password, cred.passwordHash)) {
      throw new UnauthorizedException("Login yoki parol noto'g'ri");
    }
    const payload: AccessTokenPayload = {
      sub: `kitchen:${cred.restaurantId}`,
      phone: '',
      roles: ['restaurant'],
      restaurantId: cred.restaurantId,
    };
    const accessToken = await this.jwt.signAsync(payload, {
      secret: this.config.get<string>('JWT_ACCESS_SECRET'),
      expiresIn: this.config.get<string>('JWT_ACCESS_TTL') ?? '30m',
    });
    return { accessToken, restaurantId: cred.restaurantId };
  }
}
