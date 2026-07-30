import {
  CanActivate,
  ExecutionContext,
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { timingSafeEqual } from 'node:crypto';
import { Request } from 'express';

/** Ichki so'rov sarlavhasi — barcha servislarda bir xil nom. */
export const INTERNAL_KEY_HEADER = 'x-internal-key';

/**
 * Ikkita satrni uzunlik oshkor bo'lishidan boshqa ma'lumot sizdirmasdan
 * solishtiradi. Oddiy `===` birinchi farqda to'xtaydi va (nazariy jihatdan)
 * kalitni belgima-belgi topishga imkon beradi.
 */
function safeEqual(a: string, b: string): boolean {
  const bufA = Buffer.from(a, 'utf8');
  const bufB = Buffer.from(b, 'utf8');
  if (bufA.length !== bufB.length) return false;
  return timingSafeEqual(bufA, bufB);
}

/**
 * Sarlavha qiymati sozlangan `INTERNAL_API_KEY` ga mos keladimi.
 *
 * Guard'dan TASHQARIDA — masalan `express-rate-limit`ning `skip` funksiyasida —
 * ishlatiladi: u yerda Nest DI mavjud emas, shuning uchun `process.env`
 * to'g'ridan-to'g'ri o'qiladi. Guard bilan BIR XIL mantiqdan foydalanadi,
 * shuning uchun ikkalasi hech qachon bir-biridan uzoqlashib ketmaydi.
 *
 * Kalit sozlanmagan bo'lsa har doim `false` — ya'ni "ichki so'rov" deb
 * hisoblanmaydi (rate-limit'dan ozod qilinmaydi).
 */
export function matchesInternalKey(
  headerValue: string | string[] | undefined,
): boolean {
  const expected = process.env.INTERNAL_API_KEY?.trim();
  if (!expected || typeof headerValue !== 'string') return false;
  return safeEqual(headerValue, expected);
}

/**
 * Servislararo (internal) endpointlar himoyasi — `x-internal-key` sarlavhasi
 * `INTERNAL_API_KEY` bilan mos kelishi kerak. Gateway bu yo'llarni tashqariga
 * chiqarmaydi; bu qatlam — qo'shimcha himoya (defense-in-depth).
 *
 * MUHIM: kalit sozlanmagan bo'lsa endpoint OCHILMAYDI (503 qaytaradi).
 * Zaxira ("default") kalit ATAYLAB yo'q — aks holda kalitni sozlash unutilsa,
 * ichki endpointlar hamma biladigan satr bilan "himoyalangan" bo'lib qolardi.
 */
@Injectable()
export class InternalKeyGuard implements CanActivate {
  private readonly key?: string;

  constructor(config: ConfigService) {
    this.key = config.get<string>('INTERNAL_API_KEY')?.trim() || undefined;
  }

  canActivate(context: ExecutionContext): boolean {
    if (!this.key) {
      throw new ServiceUnavailableException('Internal API kaliti sozlanmagan');
    }

    const req = context.switchToHttp().getRequest<Request>();
    const raw = req.headers[INTERNAL_KEY_HEADER];
    // Sarlavha ikki marta yuborilsa express massiv beradi — bunday so'rov
    // ishonchsiz, rad etamiz (birinchi qiymatni "tanlab olish" xavfli).
    if (typeof raw !== 'string' || !safeEqual(raw, this.key)) {
      throw new UnauthorizedException("Internal kalit noto'g'ri");
    }
    return true;
  }
}
