# Beshariq Super-App — Kod (Monorepo)

Beshariq tumani (Farg'ona viloyati) uchun yagona mobil super-ilova: **Taksi + Dostavka + Ovqat yetkazib berish**.

> 📋 **To'liq texnik reja:** [`../plan/README.md`](../plan/README.md) — arxitektura, servislar, ma'lumot bazasi, yo'l xaritasi.
> Bu papka (`code/`) — butun monorepo. Reja hujjatlari bir daraja yuqorida (`../plan/`).

## Monorepo tuzilishi

```
beshariq_food/
├── plan/                # Loyiha rejasi (hujjatlar)
└── code/                # ◀ SIZ SHU YERDASIZ (monorepo)
    ├── apps/
    │   ├── mobile/              # Flutter ilovalar (APK/store orqali tarqatiladi)
    │   │   ├── customer_app/        # Mijoz (Android)
    │   │   └── driver_app/          # Haydovchi (Android)
    │   └── web/                 # Next.js ilovalar (har biri mustaqil deploy qilinadi)
    │       ├── admin_web/            # Admin panel
    │       ├── restaurant_web/       # Oshxona paneli
    │       ├── market_web/           # Beshariq Market — mijoz sayti
    │       ├── shops_web/            # Do'konlar/Qurilish — mijoz sayti
    │       └── seller_web/           # Sotuvchi paneli
    ├── services/            # Backend mikroservislar (NestJS)
    │   ├── gateway/             # API Gateway
    │   ├── auth/                # Auth + foydalanuvchi/haydovchi profillari
    │   ├── restaurant/          # Oshxona katalogi
    │   ├── order/               # Buyurtma/taksi/dostavka/market buyurtmalari + dispatch
    │   ├── market/              # Beshariq Market katalogi
    │   ├── marketplace/         # Do'konlar/Qurilish katalogi
    │   └── support/             # Yordam chati (FAQ + AI)
    ├── packages/            # Umumiy paketlar
    │   ├── i18n/                # Umumiy tarjimalar (uz, uz-Cyrl, ru)
    │   ├── nest-auth/           # Umumiy JWT/rol guard (backend)
    │   └── beshariq_core/       # Umumiy Flutter data-layer (mobil)
    └── infra/               # Docker, DB, OSRM
```

## Texnologiyalar

| Qatlam | Texnologiya |
|--------|-------------|
| Mobil | Flutter (Android avval) |
| Backend | NestJS |
| Veb | Next.js + TypeScript |
| DB | PostgreSQL + PostGIS |
| Xarita | OpenStreetMap + MapLibre + OSRM |
| Monorepo | pnpm workspaces + Turborepo |

Batafsil: [`../plan/02-tech-stack.md`](../plan/02-tech-stack.md).

## Boshlash (development)

**Talablar:** Node.js ≥ 20, pnpm ≥ 10, Flutter ≥ 3.27. (Infra uchun: Docker Desktop.)
**Eslatma:** barcha buyruqlar `code/` papkasi ichidan ishga tushiriladi.

```bash
# 0. code/ papkasiga kirish (repo ildizidan)
cd code

# 1. Bog'liqliklarni o'rnatish
pnpm install

# 2. Muhit faylini tayyorlash
cp .env.example .env

# 3. Infratuzilma (Postgres + OSRM) — Docker kerak
pnpm infra:up

# 4. API Gateway'ni ishga tushirish
pnpm gateway:dev
# -> http://localhost:4000/api/v1/health
```

### Flutter ilovalar
```bash
cd apps/mobile/customer_app && flutter pub get && flutter run
cd apps/mobile/driver_app   && flutter pub get && flutter run
```

## Holat
Barcha asosiy vertikallar (ovqat, taksi, dostavka, market, marketplace) va admin/oshxona/sotuvchi panellari ishlab chiqilgan, aktiv rivojlantirilmoqda. Har bir servisning batafsil holati: [`services/README.md`](services/README.md).
