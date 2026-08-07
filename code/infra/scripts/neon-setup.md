# Neon (bepul PostgreSQL) — production uchun sozlash

## Nima uchun Neon?
- **Bepul** — 512 MB, ko'p sonli database (bitta loyiha ichida), kunlik avtomatik zaxira (7 kun)
- **Serverless** — restart bo'lsa ham ma'lumot yo'qolmaydi
- **Prisma bilan to'liq mos** — faqat DATABASE_URL o'zgaradi
- **PostGIS SHART EMAS** — tekshirildi: birorta ham `schema.prisma` fayli `postgis`/`geography`/`ST_*` funksiyasidan foydalanmaydi (barcha masofa/yaqin-qidiruv hisoblari dastur kodida oddiy lat/lng + OSRM orqali). Shuning uchun Neon'ning ODDIY (kengaytmasiz) bepul Postgres'i to'liq yetarli — qo'shimcha sozlash kerak emas.

---

## 1-qadam: Hisob yaratish
1. https://neon.tech → "Sign up" (GitHub bilan kirish)
2. "New project" → nom: `beshariq-prod`, region: **Europe (Frankfurt)** yoki **US East**

## 2-qadam: 6 ta database yaratish
Beshariq'da 6 ta faol xizmat o'z alohida bazasiga ega (`gateway`ning o'z bazasi yo'q — faqat proxy). Neon Console → SQL Editor:
```sql
CREATE DATABASE auth_db;
CREATE DATABASE restaurant_db;
CREATE DATABASE order_db;
CREATE DATABASE market_db;
CREATE DATABASE marketplace_db;
CREATE DATABASE support_db;
```

## 3-qadam: Connection string olish
Dashboard → Connection details → **Connection string** (har baza uchun alohida, faqat baza nomi farq qiladi):
```
postgresql://username:password@ep-xxxx.eu-central-1.aws.neon.tech/auth_db?sslmode=require
postgresql://username:password@ep-xxxx.eu-central-1.aws.neon.tech/restaurant_db?sslmode=require
postgresql://username:password@ep-xxxx.eu-central-1.aws.neon.tech/order_db?sslmode=require
postgresql://username:password@ep-xxxx.eu-central-1.aws.neon.tech/market_db?sslmode=require
postgresql://username:password@ep-xxxx.eu-central-1.aws.neon.tech/marketplace_db?sslmode=require
postgresql://username:password@ep-xxxx.eu-central-1.aws.neon.tech/support_db?sslmode=require
```

Neon serverless'da connection-pool cheklovi bor — har bir URL'ga **shart** `connection_limit=5&pool_timeout=20` qo'shiladi (lokal Docker Postgres'dagi `connection_limit=10`dan farqli, pastroq — Neon'ning pooler cheklovlariga mos):
```
postgresql://username:password@ep-xxxx.eu-central-1.aws.neon.tech/auth_db?sslmode=require&connection_limit=5&pool_timeout=20
```

## 4-qadam: Servislar .env ni yangilash

**code/services/auth/.env** (production):
```
DATABASE_URL="postgresql://username:password@ep-xxxx.eu-central-1.aws.neon.tech/auth_db?sslmode=require&connection_limit=5&pool_timeout=20"
```

**code/services/restaurant/.env** (production):
```
DATABASE_URL="postgresql://username:password@ep-xxxx.eu-central-1.aws.neon.tech/restaurant_db?sslmode=require&connection_limit=5&pool_timeout=20"
SEED_ON_START=false
```

**code/services/order/.env** (production):
```
DATABASE_URL="postgresql://username:password@ep-xxxx.eu-central-1.aws.neon.tech/order_db?sslmode=require&connection_limit=5&pool_timeout=20"
```

**code/services/market/.env** (production):
```
DATABASE_URL="postgresql://username:password@ep-xxxx.eu-central-1.aws.neon.tech/market_db?sslmode=require&connection_limit=5&pool_timeout=20"
```

**code/services/marketplace/.env** (production):
```
DATABASE_URL="postgresql://username:password@ep-xxxx.eu-central-1.aws.neon.tech/marketplace_db?sslmode=require&connection_limit=5&pool_timeout=20"
```

**code/services/support/.env** (production):
```
DATABASE_URL="postgresql://username:password@ep-xxxx.eu-central-1.aws.neon.tech/support_db?sslmode=require&connection_limit=5&pool_timeout=20"
```

## 5-qadam: Migratsiyalarni ishlatish
Har servis `package.json`sida endi `start:prod` skripti avtomatik `prisma migrate deploy`ni birinchi ishga tushirishda bajaradi (`prisma migrate deploy && node dist/main.js`) — birinchi deploy'dan keyin qo'lda bajarish shart emas. Lekin birinchi marta qo'lda tekshirib ko'rish uchun, har servis papkasidan:
```powershell
cd code/services/auth
pnpm exec prisma migrate deploy

cd ../restaurant
pnpm exec prisma migrate deploy

cd ../order
pnpm exec prisma migrate deploy

cd ../market
pnpm exec prisma migrate deploy

cd ../marketplace
pnpm exec prisma migrate deploy

cd ../support
pnpm exec prisma migrate deploy
```

## 6-qadam: Mavjud ma'lumotni ko'chirish (ixtiyoriy)
Lokal DB → Neon (agar lokal ma'lumot bo'lsa), har bir baza uchun takrorlanadi:
```powershell
# Lokal dan export
$env:PGPASSWORD="beshariq_dev_password"
pg_dump -h localhost -U beshariq -F plain auth_db > auth_dump.sql

# Neon ga import
$env:PGPASSWORD="neon_parol"
psql "postgresql://username:password@ep-xxxx.neon.tech/auth_db?sslmode=require" -f auth_dump.sql
```

---

## Neon zaxira sozlamalari
- **Avtomatik**: har kuni 1 marta (bepul = 7 kun saqlaydi)
- **Qo'lda**: Console → Backups → "Create backup"
- **Tiklash**: Console → Backups → restore point tanlash

---

## Migratsiyadan keyin: Docker'dagi Postgres nima bo'ladi?
`infra/docker/docker-compose.yml`dagi `postgres` konteyneri **lokal ishlab chiqish (dev) uchun qoladi** — u olib tashlanmaydi. Faqat production `.env`larda `DATABASE_URL` Neon'ga ko'rsatiladi; lokal `.env`lar o'zgarishsiz `localhost:5432`ga ishora qilishda davom etadi. Ya'ni ikkita muhit parallel yashaydi: dev — lokal Docker Postgres, prod — Neon.

---

## Alternativlar (bepul)
| Xizmat | Saqlash | Zaxira | Eslatma |
|--------|---------|--------|---------|
| **Neon** | 512 MB | Avtomatik 7 kun | Tavsiya etiladi — loyihada PostGIS kerak emasligi tasdiqlangan |
| **Supabase** | 500 MB | Haftalik | PostGIS to'liq (bizga kerak emas, lekin mavjud) |
| **Railway** | 1 GB | Yo'q (bepul) | $5/oy kredit |
| **Render** | 1 GB | 1 kun | Bepul tier sekin |
