/**
 * Beshariq Super-App — umumiy tarjimalar (backend xabarlari, veb ilovalar).
 * Til: plan/13-localization.md
 *
 * Eslatma: Flutter ilovalar o'z ARB fayllaridan foydalanadi; bu paket
 * backend (notif/xato xabarlari) va Next.js veb ilovalar uchun.
 */
import uz from './locales/uz.json';
import uzCyrl from './locales/uz-Cyrl.json';
import ru from './locales/ru.json';

export type Locale = 'uz' | 'uz-Cyrl' | 'ru';

export const DEFAULT_LOCALE: Locale = 'uz';
export const SUPPORTED_LOCALES: Locale[] = ['uz', 'uz-Cyrl', 'ru'];

export const translations: Record<Locale, Record<string, unknown>> = {
  uz,
  'uz-Cyrl': uzCyrl,
  ru,
};

/** So'ralgan locale qaytariladi, mavjud bo'lmasa standart (uz) — fallback. */
export function getTranslations(locale: string): Record<string, unknown> {
  return translations[locale as Locale] ?? translations[DEFAULT_LOCALE];
}

// ---- Ko'p tilli DB kontent (I18nString) — FaqItem/mahsulot/kategoriya kabi
// yozuvlarning {uz, ru, uz_Cyrl} shaklidagi maydonlari uchun. yuqoridagi
// translations/getTranslations statik ilova matnlari uchun; bu esa har bir
// DB yozuvida saqlanadigan alohida ko'p tilli qiymatlar uchun. ----

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
