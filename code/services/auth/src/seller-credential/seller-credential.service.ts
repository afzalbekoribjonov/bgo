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
 * Sotuvchi paneli (Do'konlar/Qurilish) login/parol kirishi. Parol scrypt
 * bilan xeshlanadi. Kirishda JWT (role 'seller' + sellerId + sellerType).
 */
@Injectable()
export class SellerCredentialService {
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

  /** Admin: sotuvchiga login/parol o'rnatadi (yangilaydi). */
  async setCredential(
    sellerId: string,
    username: string,
    password: string,
    sellerType: string,
  ) {
    const passwordHash = this.hash(password);
    const cred = await this.prisma.sellerCredential.upsert({
      where: { sellerId },
      update: { username, passwordHash, sellerType },
      create: { sellerId, username, passwordHash, sellerType },
    });
    return { sellerId: cred.sellerId, username: cred.username };
  }

  /** Admin: sotuvchi kirish ma'lumoti bor-yo'qligi. */
  async getInfo(sellerId: string) {
    const cred = await this.prisma.sellerCredential.findUnique({
      where: { sellerId },
    });
    return {
      exists: !!cred,
      username: cred?.username ?? null,
    };
  }

  /** Sayt kirishi: login/parol -> JWT (role 'seller', sellerId+sellerType claim). */
  async login(username: string, password: string) {
    const cred = await this.prisma.sellerCredential.findUnique({
      where: { username },
    });
    if (!cred || !this.verifyHash(password, cred.passwordHash)) {
      throw new UnauthorizedException("Login yoki parol noto'g'ri");
    }
    const payload: AccessTokenPayload = {
      sub: `seller:${cred.sellerId}`,
      phone: '',
      roles: ['seller'],
      sellerId: cred.sellerId,
      sellerType: cred.sellerType,
    };
    const accessToken = await this.jwt.signAsync(payload, {
      secret: this.config.get<string>('JWT_ACCESS_SECRET'),
      expiresIn: this.config.get<string>('JWT_ACCESS_TTL') ?? '30m',
    });
    return { accessToken, sellerId: cred.sellerId, sellerType: cred.sellerType };
  }
}
