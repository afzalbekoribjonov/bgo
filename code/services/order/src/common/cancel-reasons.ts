/**
 * Haydovchi/kuryer buyurtmani bekor qilish sababi — tanlovli, majburiy.
 * Har bir sabab uchun "mijoz aybi" belgisi bor: shu bo'lsa, haydovchidan
 * yechilgan jarima ORQAGA (sezdirmasdan) qaytariladi.
 */
export const DRIVER_CANCEL_REASONS = [
  'VEHICLE_PROBLEM',
  'TOO_FAR',
  'CANNOT_REACH_CUSTOMER',
  'CUSTOMER_NOT_AT_ADDRESS',
  'OTHER',
] as const;

export type DriverCancelReason = (typeof DRIVER_CANCEL_REASONS)[number];

/** Shu sabab bilan bekor qilinsa — mijoz aybi (jarima yashirincha qaytariladi). */
export const CANCEL_REASON_CUSTOMER_FAULT: Record<DriverCancelReason, boolean> = {
  VEHICLE_PROBLEM: false,
  TOO_FAR: false,
  CANNOT_REACH_CUSTOMER: true,
  CUSTOMER_NOT_AT_ADDRESS: true,
  OTHER: false,
};

export function isDriverCancelReason(v: unknown): v is DriverCancelReason {
  return typeof v === 'string' && (DRIVER_CANCEL_REASONS as readonly string[]).includes(v);
}
