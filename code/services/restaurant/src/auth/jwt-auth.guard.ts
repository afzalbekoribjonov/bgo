import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';
import { AccessTokenPayload } from './jwt-payload.interface';

/**
 * Auth servisi bergan access token'ni tekshiradi (bir xil JWT_ACCESS_SECRET).
 * TODO: packages/ ichidagi umumiy guardga ajratish (auth/order bilan takrorlanmoqda).
 */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const header = request.headers.authorization;
    const token =
      header && header.startsWith('Bearer ') ? header.slice(7) : undefined;
    if (!token) throw new UnauthorizedException('Token topilmadi');

    try {
      const payload = await this.jwt.verifyAsync<AccessTokenPayload>(token, {
        secret: this.config.get<string>('JWT_ACCESS_SECRET'),
      });
      (request as Request & { user: AccessTokenPayload }).user = payload;
      return true;
    } catch {
      throw new UnauthorizedException('Token yaroqsiz yoki muddati tugagan');
    }
  }
}
