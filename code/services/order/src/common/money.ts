/**
 * Mijozga ko'rinadigan narxni yaxlitlash — summa har doim 500 so'mga karrali
 * bo'ladi (masalan 8000, 8500, 9000; 8743 emas). plan/11-pricing-promo.md
 */
export function roundFare(value: number, step = 500): number {
  if (value <= 0) return 0;
  return Math.round(value / step) * step;
}
