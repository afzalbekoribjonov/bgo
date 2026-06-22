import {
  CanActivate,
  ExecutionContext,
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * Servislararo (internal) endpointlar uchun himoya — `x-internal-key` sarlavhasi
 * INTERNAL_API_KEY bilan mos kelishi kerak. Gateway bu yo'llarni tashqariga
 * chiqarmaydi; bu qatlam — qo'shimcha himoya (defense-in-depth).
 */
@Injectable()
export class InternalKeyGuard implements CanActivate {
  private readonly key?: string;

  constructor(config: ConfigService) {
    this.key = config.get<string>('INTERNAL_API_KEY');
  }

  canActivate(context: ExecutionContext): boolean {
    if (!this.key) {
      throw new ServiceUnavailableException('Internal API kaliti sozlanmagan');
    }
    const req = context.switchToHttp().getRequest<{
      headers: Record<string, string | undefined>;
    }>();
    if (req.headers['x-internal-key'] !== this.key) {
      throw new UnauthorizedException("Internal kalit noto'g'ri");
    }
    return true;
  }
}
