# Neon (bepul PostgreSQL) — production uchun sozlash

## Nima uchun Neon?
- **Bepul** — 512 MB, 3 ta database, kunlik avtomatik zaxira (7 kun)
- **Serverless** — restart bo'lsa ham ma'lumot yo'qolmaydi
- **Prisma bilan to'liq mos** — faqat DATABASE_URL o'zgaradi

---

## 1-qadam: Hisob yaratish
1. https://neon.tech → "Sign up" (GitHub bilan kirish)
2. "New project" → nom: `beshariq-prod`, region: **Europe (Frankfurt)** yoki **US East**

## 2-qadam: 3 ta database yaratish
Neon Console → SQL Editor:
```sql
CREATE DATABASE auth_db;
CREATE DATABASE restaurant_db;
CREATE DATABASE order_db;
```

## 3-qadam: Connection string olish
Dashboard → Connection details → **Connection string** (har baza uchun):
```
postgresql://username:password@ep-xxxx.eu-central-1.aws.neon.tech/auth_db?sslmode=require
postgresql://username:password@ep-xxxx.eu-central-1.aws.neon.tech/restaurant_db?sslmode=require
postgresql://username:password@ep-xxxx.eu-central-1.aws.neon.tech/order_db?sslmode=require
```

## 4-qadam: Servislar .env ni yangilash

**code/services/auth/.env** (production):
```
DATABASE_URL="postgresql://username:password@ep-xxxx.eu-central-1.aws.neon.tech/auth_db?sslmode=require"
```

**code/services/restaurant/.env** (production):
```
DATABASE_URL="postgresql://username:password@ep-xxxx.eu-central-1.aws.neon.tech/restaurant_db?sslmode=require"
SEED_ON_START=false
```

**code/services/order/.env** (production):
```
DATABASE_URL="postgresql://username:password@ep-xxxx.eu-central-1.aws.neon.tech/order_db?sslmode=require"
```

## 5-qadam: Migratsiyalarni ishlatish
Har servis papkasidan:
```powershell
cd code/services/auth
pnpm exec prisma migrate deploy

cd ../restaurant
pnpm exec prisma migrate deploy

cd ../order
pnpm exec prisma migrate deploy
```

## 6-qadam: Mavjud ma'lumotni ko'chirish (ixtiyoriy)
Lokal DB → Neon (agar lokal ma'lumot bo'lsa):
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

## Prisma connection pool muammosi (serverless)
Neon serverless da connection limit bor. `prisma.schema`'dagi connection URL ga qo'shing:
```
?sslmode=require&connection_limit=5&pool_timeout=20
```

---

## Alternativlar (bepul)
| Xizmat | Saqlash | Zaxira | Eslatma |
|--------|---------|--------|---------|
| **Neon** | 512 MB | Avtomatik 7 kun | Tavsiya etiladi |
| **Supabase** | 500 MB | Haftalik | PostGIS to'liq |
| **Railway** | 1 GB | Yo'q (bepul) | $5/oy kredit |
| **Render** | 1 GB | 1 kun | Bepul tier sekin |
