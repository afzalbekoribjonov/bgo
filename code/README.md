# Beshariq Super-App — Kod (Monorepo)

Beshariq tumani (Farg'ona viloyati) uchun yagona mobil super-ilova: **Taksi + Dostavka + Ovqat yetkazib berish**.

> 📋 **To'liq texnik reja:** [`../plan/README.md`](../plan/README.md) — arxitektura, servislar, ma'lumot bazasi, yo'l xaritasi.
> Bu papka (`code/`) — butun monorepo. Reja hujjatlari bir daraja yuqorida (`../plan/`).

## Monorepo tuzilishi

```
beshariq_food/
├── plan/                # Loyiha rejasi (hujjatlar)
└── code/                # ◀ SIZ SHU YERDASIZ (monorepo)
    ├── apps/                # Frontend ilovalar
    │   ├── customer_app/        # Flutter — mijoz (Android)
    │   ├── driver_app/          # Flutter — haydovchi (Android)
    │   ├── admin_web/           # Next.js — admin panel (keyin)
    │   └── restaurant_web/      # Next.js — oshxona paneli (keyin)
    ├── services/            # Backend microservislar
    │   └── gateway/             # NestJS — API Gateway (✅ Faza 0)
    ├── packages/            # Umumiy paketlar
    │   ├── shared-types/        # TS umumiy tiplar/enum
    │   └── i18n/                # Umumiy tarjimalar (uz, uz-Cyrl, ru)
    └── infra/               # Docker, DB, OSRM
```

## Texnologiyalar

| Qatlam | Texnologiya |
|--------|-------------|
| Mobil | Flutter (Android avval) |
| Backend | NestJS (+ Go: location) |
| Veb | Next.js + TypeScript |
| DB | PostgreSQL + PostGIS, Redis |
| Event bus | NATS |
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

# 3. Infratuzilma (Postgres/Redis/NATS) — Docker kerak
pnpm infra:up

# 4. API Gateway'ni ishga tushirish
pnpm gateway:dev
# -> http://localhost:3000/api/v1/health
```

### Flutter ilovalar
```bash
cd apps/customer_app && flutter pub get && flutter run
cd apps/driver_app   && flutter pub get && flutter run
```

## Holat
Hozir: **Faza 0 — Monorepo skeleti** (bajarildi). Keyingi qadamlar: [`../plan/15-roadmap-mvp.md`](../plan/15-roadmap-mvp.md).
