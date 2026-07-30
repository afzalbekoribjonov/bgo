import type { CorsOptions } from '@nestjs/common/interfaces/external/cors-options.interface';

/**
 * `CORS_ORIGIN` muhit o'zgaruvchisidan ruxsat etilgan manzillar ro'yxati.
 * Format: vergul bilan ajratilgan (`https://a.uz,https://b.uz`).
 *
 * O'zgaruvchi berilmagan yoki faqat bo'sh/probel qiymatlardan iborat bo'lsa —
 * servisning o'z zaxira ro'yxati qaytariladi (dev rejim uchun localhost
 * portlari). Bo'sh elementlar (`"a,,b"`, oxirgi vergul) tashlab yuboriladi:
 * bo'sh satr CORS manzili sifatida hech qachon to'g'ri emas.
 */
export function resolveCorsOrigins(fallback: string[]): string[] {
  const raw = process.env.CORS_ORIGIN;
  if (!raw) return fallback;
  const list = raw
    .split(',')
    .map((o) => o.trim())
    .filter((o) => o.length > 0);
  return list.length > 0 ? list : fallback;
}

/**
 * Barcha Beshariq servislari uchun bir xil CORS siyosati. Faqat ruxsat etilgan
 * manzillar farq qiladi — metodlar/sarlavhalar/credentials hamma joyda bir xil.
 *
 * `X-Internal-Key` ro'yxatda — brauzer emas, lekin ba'zi dev vositalari
 * preflight yuboradi; yo'qligi ichki chaqiruvlarni bloklab qo'yishi mumkin.
 */
export function buildCorsOptions(origin: string[]): CorsOptions {
  return {
    origin,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Internal-Key'],
    credentials: true,
  };
}
