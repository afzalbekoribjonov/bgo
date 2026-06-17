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
