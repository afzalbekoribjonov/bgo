# Apps — Frontend ilovalar

Ikki guruhga ajratilgan (server joylashtirish va kelgusi microservice migratsiyasi uchun tartibli):

- **`mobile/`** — Flutter ilovalar, APK/store orqali tarqatiladi (serverga deploy qilinmaydi).
- **`web/`** — Next.js ilovalar, har biri mustaqil, o'z portida ishlaydigan va mustaqil deploy qilinadigan.

## mobile/

| Ilova | Kim uchun | Reja |
|-------|-----------|------|
| **customer_app** | Mijoz | [`../../plan/05-customer-app.md`](../../plan/05-customer-app.md) |
| **driver_app** | Haydovchi | [`../../plan/06-driver-app.md`](../../plan/06-driver-app.md) |

- Android avval (iOS keyin).
- 3 til: uz / uz-Cyrl / ru (ARB fayllar, `flutter gen-l10n`).
- Umumiy data-layer: `packages/beshariq_core` (`path: ../../../packages/beshariq_core`).
- Ishga tushirish: `cd apps/mobile/<app> && flutter pub get && flutter run`.

## web/

| Ilova | Port | Kim uchun | Reja |
|-------|------|-----------|------|
| **admin_web** | 3200 | Admin | [`../../plan/08-admin-workspace.md`](../../plan/08-admin-workspace.md) |
| **restaurant_web** | 3100 | Oshxona egasi | [`../../plan/07-restaurant-app.md`](../../plan/07-restaurant-app.md) |
| **market_web** | 3300 | Mijoz (Beshariq Market) | — |
| **shops_web** | 3400 | Mijoz (Do'konlar/Qurilish) | — |
| **seller_web** | 3500 | Sotuvchi | — |

- Next.js + TypeScript, pnpm workspace ichida (`pnpm-workspace.yaml`: `apps/web/*`).
- restaurant_web/market_web/shops_web — customer_app ichida WebView orqali ham ochiladi (`AppWebViewScreen`, `?token=` bilan avtomatik kirish).
- Ishga tushirish: `cd apps/web/<app> && pnpm dev` (yoki repo ildizidan `pnpm --filter @beshariq/<nom>-web dev`).
