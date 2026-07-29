# Services — Backend mikroservislar

Har servis mustaqil: o'z Postgres bazasi (Prisma), o'z API'si. Servislararo aloqa —
REST orqali `x-internal-key` bilan himoyalangan `/internal/*` endpointlar (thin-client
naqshi, masalan `src/*-client/*.client.ts`). Dev'da hammasi hostda `node dist/main.js`
bilan ishlaydi; Docker faqat infra (Postgres, OSRM) uchun ishlatiladi — [`../infra/`](../infra/).

## Servislar

| Servis | Port | Baza | Vazifasi |
|--------|------|------|----------|
| **gateway** | 4000 | — | Reverse proxy — barcha `/api/v1/*` so'rovlarni tegishli servisga yo'naltiradi. Baza yo'q, `@beshariq/nest-auth`ga bog'liq emas. |
| **auth** | 4001 | auth_db | Telefon+OTP/haydovchi-kod autentifikatsiya, JWT, mijoz/haydovchi profili, manzillar, xabarlar (admin→mijoz/haydovchi), push token, bloklash. |
| **restaurant** | 4003 | restaurant_db | Oshxonalar, menyu/kategoriya katalogi, egalik (owner), boshqaruv paneli endpointlari. |
| **order** | 4004 | order_db | Uchta vertikal: ovqat buyurtmasi, taksi (TaxiTrip), pochta (ParcelDelivery) — narxlash, dispatch, tarif/promo, hisobot. |
| **market** | 4005 | market_db | Beshariq Market — katalog, buyurtma, izoh/layk, support chat. |
| **marketplace** | 4006 | marketplace_db | Uchinchi tomon sotuvchilar do'konlari — katalog, buyurtma. |
| **support** | 4007 | support_db | AI (Gemini) yordamchi chat — mijoz/haydovchi, FAQ, admin eskalatsiya. |

## Umumiy paketlar (`../packages/`)

- `@beshariq/nest-auth` — `JwtAuthGuard`, `RolesGuard`, `@Roles`, `@CurrentUser` (barcha DB'li servislarda ishlatiladi, gateway'da yo'q).
- `@beshariq/i18n` — ilova matnlari tarjima katalogi (`getTranslations`) + ko'p tilli DB kontent yordamchilari (`I18nString`, `pickLocale`, `localeFromHeader`) — `restaurant`, `market`, `marketplace`, `support`da ishlatiladi.

## Yangi servis qo'shish

`market` yoki `marketplace`ni namuna sifatida ko'chiring (`package.json` nomini
`@beshariq/<servis>` qiling). `tsconfig.json` root'dagi [`../tsconfig.base.json`](../tsconfig.base.json)ni
`extends` qilishi shart — faqat `outDir`/`baseUrl`/`include`/`exclude` servisga xos qoladi.
