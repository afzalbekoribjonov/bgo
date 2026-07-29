# Order servisi

Buyurtma yaratish va hayot sikli (MVP: ovqat). Narx **server tomonda** katalogdan hisoblanadi.
Reja: [`../../../plan/04-backend-services.md`](../../../plan/04-backend-services.md)

## Ishga tushirish (dev)
```bash
cd code/services/order
cp .env.example .env      # birinchi marta
# repo ildizidan:  pnpm order:dev
pnpm start:dev            # http://localhost:4004/api/v1
```
> `JWT_ACCESS_SECRET` auth servisi bilan **bir xil** bo'lishi shart (token tekshiruvi).
> Restaurant servisi (4003) ishlab turishi kerak (narx/nom katalogdan olinadi).
>
> **Eslatma:** bu servis endi ovqatdan tashqari taksi, dostavka (pochta) va Market buyurtmalarini ham
> boshqaradi (`src/taxi/`, `src/parcel/`, `src/store-orders/`) — to'liq endpoint ro'yxati uchun
> [`../README.md`](../README.md) va shu papkalardagi kontrollerlarga qarang.

## Endpointlar (`/api/v1`, barchasi Bearer token bilan)

| Metod | Yo'l | Tavsif |
|-------|------|--------|
| POST | `/orders` | Buyurtma yaratish (FOOD) |
| GET | `/orders` | Mening buyurtmalarim |
| GET | `/orders/:id` | Bitta buyurtma (faqat egasi) |
| POST | `/orders/:id/cancel` | Bekor qilish (faqat PENDING) |

So'rov namunasi (`POST /orders`):
```json
{
  "type": "FOOD",
  "restaurantId": "r1",
  "paymentType": "CASH",
  "address": { "text": "Beshariq, uy 5" },
  "items": [ { "menuItemId": "m1", "qty": 2 } ]
}
```

## Muhim qoidalar
- **Narx mijozdan olinmaydi** — Order servisi katalogdan (Restaurant servisi) narx/nomni oladi va snapshot qiladi. plan/10-auth-security.md
- Mavjud bo'lmagan yoki "yo'q" taom → 400.
- `total = itemsTotal + deliveryFee` (dostavka MVP'da qat'iy `DELIVERY_FEE`).

## Cheklovlar (TODO)
- **Saqlash:** PostgreSQL (Prisma, `order_db`).
- **Narx:** hozircha Order servisi ichida hisoblanadi (alohida Pricing servisiga ajratish rejalashtirilmagan).
- **To'lov:** hozir faqat CASH; Payme/Click/Uzum uchun zahira kod bor (`src/payment/`), lekin hech qaysi provayder hali ulanmagan.
