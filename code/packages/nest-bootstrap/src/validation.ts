import type { ValidationPipeOptions } from '@nestjs/common';

/**
 * Barcha servislarda bir xil validatsiya siyosati:
 * - `whitelist` — DTO'da e'lon qilinmagan maydonlar olib tashlanadi
 * - `forbidNonWhitelisted` — ortiqcha maydon yuborilsa 400 (jimgina yutilmaydi)
 * - `transform` — kelgan JSON DTO klassiga (va `@Type` bilan son/sanaga) o'giriladi
 */
export const VALIDATION_PIPE_OPTIONS: ValidationPipeOptions = {
  whitelist: true,
  forbidNonWhitelisted: true,
  transform: true,
};
