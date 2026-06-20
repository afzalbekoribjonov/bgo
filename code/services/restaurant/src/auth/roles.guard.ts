import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Request } from 'express';
import { AccessTokenPayload } from './jwt-payload.interface';
import { ROLES_KEY } from './roles.decorator';

/**
 * Endpoint uchun zarur rolni tekshiradi. JwtAuthGuard'dan KEYIN:
 * @UseGuards(JwtAuthGuard, RolesGuard).
 */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const required = this.reflector.getAllAndOverride<string[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!required || required.length === 0) return true;

    const request = context
      .switchToHttp()
      .getRequest<Request & { user?: AccessTokenPayload }>();
    const roles = request.user?.roles ?? [];
    if (!required.some((r) => roles.includes(r))) {
      throw new ForbiddenException('Ruxsat yetarli emas');
    }
    return true;
  }
}
