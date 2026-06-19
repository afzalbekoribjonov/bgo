# Oshxona paneli (restaurant_web)

Hamkor oshxonalar uchun **buyurtma boshqaruvi** va **menyu boshqaruvi**. Next.js (App Router).
Reja: [`../../../plan/07-restaurant-app.md`](../../../plan/07-restaurant-app.md)

## Ishga tushirish (dev)
```bash
# repo ildizidan
cd code
pnpm install
cp apps/restaurant_web/.env.example apps/restaurant_web/.env   # birinchi marta

# Backend ishlab turishi kerak (gateway 3000 + auth/restaurant/order)
pnpm --filter @beshariq/restaurant-web dev
# -> http://localhost:3100
```

## Sahifalar
- `/` — oshxonani tanlash (GET /restaurants).
- `/restaurants/:id/orders` — **buyurtmalar doskasi**: kelgan buyurtmalar, har 5s yangilanadi, Qabul/Tayyorlanmoqda/Tayyor/Rad tugmalari.
- `/restaurants/:id/menu` — **menyu boshqaruvi**: kategoriya/taom qo'shish, mavjudlik (bor/yo'q), o'chirish.

## Backend bog'lanishi (gateway orqali)
- Buyurtmalar: `/api/v1/kitchen/...` (order servisi)
- Menyu: `/api/v1/restaurants/:id/categories|menu-items` (restaurant servisi)

## Cheklovlar (TODO)
- **Auth yo'q** (dev): oshxona tanlanadi. Keyin restaurant roli (telefon+OTP) + egalik tekshiruvi.
- **UI tili:** hozir faqat o'zbekcha. Keyin 3 til (uz/uz-Cyrl/ru).
- Real vaqt: hozir polling (5s). Keyin WebSocket + ovozli signal.
- WebView: apk ichida ochish — keyingi bosqich.
