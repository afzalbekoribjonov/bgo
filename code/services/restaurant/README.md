# Restaurant / Catalog servisi

Oshxonalar, kategoriyalar, taomlar (menyu) va narxlar. 3 til (uz/uz-Cyrl/ru).
Reja: [`../../../plan/07-restaurant-app.md`](../../../plan/07-restaurant-app.md), [`../../../plan/03-databases.md`](../../../plan/03-databases.md)

## Ishga tushirish (dev)
```bash
cd code/services/restaurant
cp .env.example .env      # birinchi marta
# repo ildizidan:  pnpm restaurant:dev
pnpm start:dev            # http://localhost:4003/api/v1
```
Ishga tushganda namunaviy katalog (2 oshxona) yuklanadi (`SEED_ON_START=true`).

## Endpointlar (`/api/v1` ostida)

### Public katalog (mijoz)
| Metod | Yo'l | Tavsif |
|-------|------|--------|
| GET | `/restaurants` | Faol oshxonalar ro'yxati |
| GET | `/restaurants/:id` | Oshxona ma'lumoti |
| GET | `/restaurants/:id/menu` | Menyu (kategoriya bo'yicha, `Accept-Language` ga moslangan) |

### Boshqaruv (oshxona egasi)
| Metod | Yo'l | Tavsif |
|-------|------|--------|
| GET/POST | `/restaurants/:id/categories` | Kategoriyalar |
| PATCH/DELETE | `/restaurants/:id/categories/:catId` | Tahrirlash/o'chirish |
| GET/POST | `/restaurants/:id/menu-items` | Taomlar |
| PATCH/DELETE | `/restaurants/:id/menu-items/:itemId` | Tahrirlash/o'chirish |
| PATCH | `/restaurants/:id/menu-items/:itemId/availability` | `{ isAvailable }` |

- Nom/tavsif i18n obyekt: `{ "uz": "...", "uz_Cyrl": "...", "ru": "..." }` (kamida `uz`).
- Narx — so'mda butun son.

## Hozirgi cheklovlar (TODO)
- **Saqlash:** PostgreSQL (Prisma).
- **Boshqaruv auth:** JWT + rol + egalik tekshiruvi (`RestaurantOwnerGuard`) ulangan.
- **Rasm yuklash:** lokal diskka saqlanadi (`uploads/`); tashqi CDN/media servisiga o'tish keyingi bosqichda.
