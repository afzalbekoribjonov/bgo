# 02 — Texnologiya to'plami (Tech Stack)

> Asosiy fayl: [README.md](README.md)
> Bu yerda har bir tanlov **nega** qilingani va alternativalari yozilgan. Yakuniy qaror sizniki — bu kuchli tavsiya.

## 1. Mobil ilovalar — **Flutter (Dart)**

**Nega:**
- Bitta kod baza → Android + iOS (kelajakda). Kichik jamoa uchun ideal.
- Kuchli **fon rejimi va GPS** kutubxonalari (`flutter_background_geolocation`, `geolocator`).
- **MapLibre GL** (`maplibre_gl`) — bepul vektorli xarita, offline qo'llab-quvvatlaydi.
- **WebView** (`webview_flutter`) — oshxona panelini ilova ichida ochish uchun.
- Yuqori unumdorlik (native kompilyatsiya), silliq animatsiya.
- Push: `firebase_messaging`.

**Alternativa:** React Native (agar jamoa JS/React kuchli bo'lsa). Lekin fon GPS va xarita bo'yicha Flutter barqarorroq.

**Asosiy paketlar:**
| Maqsad | Paket |
|--------|-------|
| State management | `riverpod` yoki `bloc` |
| Tarmoq | `dio` + `retrofit` |
| Xarita | `maplibre_gl` |
| Joylashuv | `geolocator`, `flutter_background_geolocation` |
| Push | `firebase_messaging`, `flutter_local_notifications` |
| Til (i18n) | `flutter_localizations` + `intl` (ARB fayllar) |
| Saqlash | `flutter_secure_storage` (token), `hive`/`isar` (kesh) |
| WebView | `webview_flutter` |
| Real-time | `web_socket_channel` |

## 2. Backend — **NestJS (TypeScript)** + **Go** (location)

**Nega NestJS (asosiy):**
- Microservice'ga moslangan tuzilma (module, provider, DI) → **clean, mantiqli kod** (siz so'ragandek).
- TypeScript butun loyihada (mobil emas, lekin web + backend + shared types) → kontekst almashinuvi kam.
- O'rnatilgan microservice transport (NATS, RabbitMQ, gRPC), WebSocket (Gateway), validation, Swagger.
- Async/await tabiiy — Node.js event loop bilan I/O-og'ir ishlar (buyurtma, to'lov) uchun tez.

**Nega Go (faqat Location/Tracking):**
- Real-time GPS — minglab ulanish, yuqori chastota → Go goroutine'lari bilan juda tezkor va kam resurs.
- Boshqa servislar yukni ko'tara olmasa, faqat shu kritik qismni Go'da yozamiz.

**Alternativa:** FastAPI (Python) — toza va asinxron, agar jamoa Python kuchli bo'lsa. Lekin TS bir butunlik afzalligini yo'qotamiz.

## 3. Veb (Admin + Oshxona) — **Next.js + TypeScript**

**Nega:**
- SSR/SSG → tez yuklanish, SEO (oshxona sahifalari uchun foydali).
- **PWA** qilib o'rnatish mumkin → oshxona paneli WebView ichida va alohida ham ishlaydi.
- React ekotizimi — admin panel komponentlari ko'p.

**UI kutubxonasi:**
- **Admin:** Ant Design (Pro) yoki **shadcn/ui + TanStack Table** — boy jadval, filter, sort, grafik.
- **Oshxona:** sodda, yirik tugmali, mobil-birinchi (oshxona xodimi telefon/planshetda ishlatadi).
- Grafiklar: **Recharts** yoki **ECharts**.

## 4. Ma'lumot bazasi — **PostgreSQL + PostGIS** + **Redis**

- **PostgreSQL** — asosiy tranzaksion DB (kuchli, bepul, ishonchli). Har servisga alohida DB/sxema.
- **PostGIS** — geo so'rovlar (POI, hudud, masofa) PostgreSQL ustida.
- **Redis** — kesh, sessiya, **real-time joylashuv (Redis Geo)**, pub/sub, rate-limit, navbat (BullMQ).
- ORM: **Prisma** (NestJS bilan toza, type-safe) yoki **TypeORM**.

**Nega NoSQL emas (asosiy sifatida):** buyurtma/to'lov/pul — qat'iy tranzaksiya va bog'lanish kerak → relational to'g'ri tanlov. Menyu kabi moslashuvchan qismlar uchun JSONB ustun yetarli.

Batafsil model → [03-databases.md](03-databases.md).

## 5. Event Bus — **NATS** (yoki RabbitMQ)

- **NATS** — yengil, juda tez, oddiy. Microservice'lar orasidagi asinxron eventlar uchun ideal.
- **RabbitMQ** — agar murakkab routing/kafolatli yetkazish kerak bo'lsa.
- Boshida: NestJS event-emitter (monolith ichida) → keyin NATS (ajralganda).

## 6. Xarita / Navigatsiya — **OSM + MapLibre + OSRM** (hammasi bepul)

| Qism | Yechim | Bepulmi |
|------|--------|---------|
| Xarita ma'lumoti | OpenStreetMap (Geofabrik UZ extract) | ✅ |
| Xarita ko'rsatish | MapLibre GL (mobil + web) | ✅ |
| Tile (plitka) | MapTiler free / o'z OpenMapTiles serverimiz | ✅ (limit bilan) |
| Marshrut (routing) | OSRM (o'z serverimizda, UZ extract) | ✅ |
| Geokoding (manzil↔koordinata) | Nominatim (o'z serverimizda) | ✅ |
| Real-time geo | Redis Geo | ✅ |

Batafsil → [09-maps-navigation.md](09-maps-navigation.md).

## 7. Autentifikatsiya

- **Telefon raqami + OTP (SMS)** — O'zbekistonda standart.
- **JWT** access (qisqa muddatli) + refresh token (Redis'da).
- SMS gateway: **Eskiz.uz** yoki **Play Mobile** (mahalliy).
- Batafsil → [10-auth-security.md](10-auth-security.md).

## 8. To'lov

- **Payme**, **Click**, **Uzum** — mahalliy to'lov tizimlari (integratsiya API).
- **Naqd** — yetkazishda to'lash (asosiy boshlanish usuli).
- Batafsil → [11-pricing-promo.md](11-pricing-promo.md).

## 9. Push va xabarnoma

- **Firebase Cloud Messaging (FCM)** — bepul push (Android + iOS).
- SMS — kritik holatlar (OTP, buyurtma tasdiqi) uchun.

## 10. Media saqlash

- **Cloudflare R2** — bepul egress, S3-mos API, arzon. (Taom rasmlari, hujjatlar, avatar.)
- Alternativa: Supabase Storage, Backblaze B2.

## 11. Infratuzilma / DevOps

- **Docker + Docker Compose** — dev va boshlang'ich prod.
- **Oracle Cloud Always Free** (4 ARM core, 24GB RAM) — OSRM, DB, backend uchun saxiy bepul.
- **Supabase** — Postgres + Auth + Storage bepul trial (tez start uchun).
- CI/CD: **GitHub Actions**.
- Batafsil → [12-infrastructure-devops.md](12-infrastructure-devops.md).

## 12. Monorepo tuzilishi

```
beshariq_food/
├── plan/                          # reja hujjatlari (bu papka)
└── code/                          # monorepo (barcha kod shu yerda)
    ├── apps/
    │   ├── customer_app/          # Flutter — mijoz
    │   ├── driver_app/            # Flutter — haydovchi
    │   ├── admin_web/             # Next.js — admin
    │   └── restaurant_web/        # Next.js — oshxona (PWA/WebView)
    ├── services/
    │   ├── gateway/               # NestJS API Gateway
    │   ├── auth/                  # NestJS
    │   ├── user/
    │   ├── order/
    │   ├── taxi/
    │   ├── delivery/
    │   ├── restaurant/
    │   ├── pricing/
    │   ├── promo/
    │   ├── payment/
    │   ├── notification/
    │   ├── reporting/
    │   ├── media/
    │   ├── location/              # Go
    │   └── routing/               # Go / OSRM proxy
    ├── packages/
    │   ├── shared-types/          # TS umumiy tiplar (DTO)
    │   ├── i18n/                  # umumiy tarjimalar
    │   └── ui/                    # umumiy web UI komponentlar
    └── infra/
        ├── docker/                # Dockerfile, compose
        ├── osrm/                  # OSRM tayyorlash skriptlari
        └── db/                    # migration, seed
```

> **Eslatma:** reja (`plan/`) va kod (`code/`) yuqori darajada ajratilgan — aralashmasligi uchun. Barcha `pnpm`/`flutter` buyruqlari `code/` ichidan ishga tushiriladi.

> Monorepo uchun **Turborepo** (web/backend TS) + Flutter ilovalar alohida papkada (`melos` bilan boshqarilishi mumkin).

## 13. Bog'liq fayllar
- Arxitektura → [01-architecture.md](01-architecture.md)
- Infratuzilma → [12-infrastructure-devops.md](12-infrastructure-devops.md)
- Qarorlar (ADR) → [16-risks-decisions.md](16-risks-decisions.md)
