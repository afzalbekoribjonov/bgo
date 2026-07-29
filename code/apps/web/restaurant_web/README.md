# Oshxona paneli (restaurant_web)

Hamkor oshxonalar uchun **buyurtma boshqaruvi** va **menyu boshqaruvi**. Next.js (App Router).
Reja: [`../../../../plan/07-restaurant-app.md`](../../../../plan/07-restaurant-app.md)

## Ishga tushirish (dev)
```bash
# repo ildizidan
cd code
pnpm install
cp apps/web/restaurant_web/.env.example apps/web/restaurant_web/.env   # birinchi marta

# Backend ishlab turishi kerak (gateway 4000 + auth/restaurant/order)
pnpm --filter @beshariq/restaurant-web dev
# -> http://localhost:3100
```

## Sahifalar
- `/` — telefon+OTP kirish (yoki WebView'dan avtomatik token bilan).
- `/restaurants/:id/orders` — **buyurtmalar doskasi**: kelgan buyurtmalar, har 5s yangilanadi, Qabul/Tayyorlanmoqda/Tayyor/Rad tugmalari, yangi buyurtmada ovozli signal.
- `/restaurants/:id/menu` — **menyu boshqaruvi**: kategoriya/taom qo'shish, mavjudlik (bor/yo'q), rasm yuklash, o'chirish.
- `/restaurants/:id/history` — yopilgan/bekor qilingan buyurtmalar tarixi.
- `/restaurants/:id/income` — daromad statistikasi.
- `/restaurants/:id/settings` — oshxona profili (nom/tavsif/logo/ochiq-yopiq holat).

## Backend bog'lanishi (gateway orqali)
- Buyurtmalar: `/api/v1/kitchen/...` (order servisi)
- Menyu/profil: `/api/v1/restaurants/:id/...` (restaurant servisi)
- Auth: `/api/v1/auth/...` (auth servisi)

## Cheklovlar (TODO)
- **UI tili:** hozir faqat o'zbekcha. Keyin 3 til (uz/uz-Cyrl/ru).
- Real vaqt: polling (5s) + ovozli signal. WebSocket'ga o'tish keyingi bosqich bo'lishi mumkin.
