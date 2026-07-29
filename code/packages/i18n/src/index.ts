/**
 * Beshariq Super-App — DB'da saqlanadigan ko'p tilli kontent yordamchilari.
 * Til: plan/13-localization.md
 *
 * Eslatma: Flutter ilovalar o'z ARB fayllaridan foydalanadi; bu paket
 * FaqItem/mahsulot/kategoriya kabi DB yozuvlaridagi {uz, ru, uz_Cyrl}
 * shaklidagi ko'p tilli qiymatlar uchun (backend + Next.js veb ilovalar).
 */

/** Ko'p tilli matn. plan/13-localization.md */
export interface I18nString {
  uz: string;
  uz_Cyrl?: string;
  ru?: string;
}

export type SupportedLocale = 'uz' | 'uz_Cyrl' | 'ru';

/** Accept-Language header -> qo'llab-quvvatlanadigan til. */
export function localeFromHeader(header?: string): SupportedLocale {
  if (!header) return 'uz';
  const value = header.split(',')[0].trim();
  if (value === 'uz-Cyrl' || value === 'uz_Cyrl') return 'uz_Cyrl';
  if (value.startsWith('ru')) return 'ru';
  return 'uz';
}

/** i18n obyektidan tilga mos matn (fallback: uz -> mavjud birinchi). */
export function pickLocale(value: I18nString, locale: SupportedLocale): string {
  return value[locale] ?? value.uz ?? Object.values(value).find(Boolean) ?? '';
}
