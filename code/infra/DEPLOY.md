# Beshariq — production'ga joylashtirish qo'llanmasi

Bu hujjat butun tizimni (baza, marshrut serveri, 7 backend xizmat, 5 frontend) birinchi marta production'ga chiqarish uchun bosqichma-bosqich qo'llanma. Har bosqichda aniq buyruqlar/muhit o'zgaruvchilari ro'yxati bor.

**Muhim eslatma**: hisob yaratish va haqiqiy "Deploy" tugmasini bosish — har doim SIZ bajarasiz (avtomatlashtirib bo'lmaydigan, xavfsizlik nuqtai nazaridan sizga tegishli bosqichlar). Bu hujjat faqat aniq yo'l-yo'riq beradi.

## Tavsiya etilgan stack

| Qatlam | Xizmat | Nima uchun |
|---|---|---|
| Ma'lumotlar bazasi (6 ta) | **Neon** | Bepul, PostGIS kerak emas (tasdiqlangan), Prisma bilan mos — [`scripts/neon-setup.md`](scripts/neon-setup.md) |
| Marshrut serveri (OSRM) | **Fly.io** | Docker image'ni to'g'ridan-to'g'ri, doimiy volume bilan ishga tushiradi — [`osrm/README.md`](osrm/README.md) |
| Backend (gateway + 6 xizmat) | **Railway** | Dockerfile'siz avtomatik Node aniqlash (Nixpacks), bitta repo'dan ko'p xizmatni "root directory" orqali alohida deploy, xizmatlar orasidagi ichki tarmoq mavjud `*_SERVICE_URL` naqshiga to'g'ridan-to'g'ri mos keladi |
| Frontend (5 ta) | **Vercel** | Standart Next.js server-mode, hech qanday kod o'zgarishisiz (dinamik `[id]` marshrutlar bor — statik eksport hozircha ko'rib chiqilmagan), bepul tarifi bu ko'lam uchun yetarli |

**Muqobillar**: Backend uchun Render (bepul tarifi bor, lekin faolsizlikda "uxlaydi" — gateway+7-xizmat arxitektura uchun unchalik mos emas, sovuq boshlanish sezilarli bo'ladi). Frontend uchun Cloudflare Pages (bepul, cheksiz so'rov) — lekin bu 5 ilovaning barchasida dinamik `[id]` marshrutlar borligi sababli statik eksport (`output:'export'`) talab qiladi, bu katta va xavfli qayta qurish (alohida so'ralganda ko'rib chiqiladi).

---

## 1-bosqich: Neon (ma'lumotlar bazalari)

To'liq qo'llanma: [`scripts/neon-setup.md`](scripts/neon-setup.md). Qisqacha: hisob yaratish → 6 ta baza (`auth_db`, `restaurant_db`, `order_db`, `market_db`, `marketplace_db`, `support_db`) → har biri uchun `connection_limit=5&pool_timeout=20` bilan connection string olish. Bu bosqich boshqalardan MUSTAQIL — birinchi bajariladi, chunki 3-bosqichdagi backend xizmatlar shu `DATABASE_URL`larga muhtoj.

## 2-bosqich: Fly.io (OSRM)

To'liq qo'llanma: [`osrm/README.md`](osrm/README.md#production-joylashtirish-flyio). Natijada `https://beshariq-osrm.fly.dev` kabi doimiy URL olasiz — 3-bosqichda `order` xizmatining `OSRM_URL`iga qo'yiladi.

## 3-bosqich: Railway (backend — gateway + 6 xizmat)

1. https://railway.app → GitHub bilan kirish → "New Project" → "Deploy from GitHub repo" → shu repo tanlanadi.
2. Har bir backend xizmat uchun **alohida service** yaratiladi (bitta repo, 7 marta "New Service" → "GitHub Repo" → xuddi shu repo, lekin **Root Directory** har birida farq qiladi):
   - `services/gateway`
   - `services/auth`
   - `services/restaurant`
   - `services/order`
   - `services/market`
   - `services/marketplace`
   - `services/support`
3. Har bir xizmat "Settings" → "Networking":
   - **Faqat `gateway`ga** public domain beriladi ("Generate Domain") — u yagona tashqi (brauzer/mobil ilova) chaqiradigan xizmat.
   - Qolgan 6 xizmat FAQAT ichki (private) tarmoqda qoladi — Railway avtomatik `<service>.railway.internal` domenini beradi, bu boshqa xizmatlarning muhit o'zgaruvchilarida ishlatiladi (pastga qarang). Bu xavfsizlik uchun ham foydali — 6 xizmat internetdan to'g'ridan-to'g'ri chaqirilmaydi.
4. Har bir xizmatga muhit o'zgaruvchilari (`.env.example`lardagi kalitlar asosida, "Variables" bo'limi):

   **Barcha 7 xizmatda umumiy** (bir xil qiymat — aks holda JWT/ichki-chaqiruvlar ishlamaydi):
   ```
   NODE_ENV=production
   JWT_ACCESS_SECRET=<xavfsiz tasodifiy satr — barcha xizmatlarda AYNAN bir xil>
   INTERNAL_API_KEY=<xavfsiz tasodifiy satr — barcha xizmatlarda AYNAN bir xil>
   ```

   **`gateway`**:
   ```
   GATEWAY_PORT=4000
   AUTH_SERVICE_URL=http://<auth-service>.railway.internal:4001
   RESTAURANT_SERVICE_URL=http://<restaurant-service>.railway.internal:4003
   ORDER_SERVICE_URL=http://<order-service>.railway.internal:4004
   MARKET_SERVICE_URL=http://<market-service>.railway.internal:4005
   MARKETPLACE_SERVICE_URL=http://<marketplace-service>.railway.internal:4006
   SUPPORT_SERVICE_URL=http://<support-service>.railway.internal:4007
   CORS_ORIGIN=https://admin-web.vercel.app,https://market-web.vercel.app,https://restaurant-web.vercel.app,https://shops-web.vercel.app,https://seller-web.vercel.app
   ```
   (4-bosqichdan keyin, Vercel'dagi haqiqiy domenlar bilan `CORS_ORIGIN`ni yangilang.)

   **`auth`**: `AUTH_PORT=4001`, `DATABASE_URL=<Neon auth_db>`, Firebase/Telegram kalitlari (mavjud `.env.example`dan).

   **`restaurant`**: `RESTAURANT_PORT=4003`, `DATABASE_URL=<Neon restaurant_db>`, `AUTH_SERVICE_URL=http://<auth-service>.railway.internal:4001`, `SEED_ON_START=false`, `PUBLIC_API_URL=https://<gateway-domain>` (ImageKit sozlanmagan holatda lokal-disk rasm URL'lari shu orqali quriladi — lekin Railway'ning fayl tizimi ephemeral, shuning uchun ImageKit kalitlarini sozlash TAVSIYA ETILADI), `IMAGEKIT_PUBLIC_KEY`/`IMAGEKIT_PRIVATE_KEY`/`IMAGEKIT_URL_ENDPOINT`.

   **`order`**: `ORDER_PORT=4004`, `DATABASE_URL=<Neon order_db>`, `OSRM_URL=https://beshariq-osrm.fly.dev` (2-bosqich), qolgan `*_SERVICE_URL`lar boshqa xizmatlarning `.railway.internal` manzillariga.

   **`market`**/**`marketplace`**: mos `DATABASE_URL`, `PUBLIC_API_URL`, `IMAGEKIT_*` (ikkalasida allaqachon bor).

   **`support`**: `DATABASE_URL=<Neon support_db>`, `GEMINI_API_KEY=<sizning kalitingiz>`.

5. Har xizmat avtomatik `pnpm install` (→ yangi `postinstall: prisma generate`) va `start:prod` (→ `prisma migrate deploy && node dist/main.js`) ishga tushiradi — Railway "Root Directory"da `package.json`ni topib standart Node buyruqlarini avtomatik ishlatadi (Nixpacks), qo'shimcha sozlash shart emas.
6. Tekshirish: `https://<gateway-domain>/api/v1/health` — 200 qaytishi kerak (barcha 6 xizmatning DB-health-check'i endi haqiqiy — birortasi noto'g'ri sozlansa, o'sha xizmatning `/health`i 503 qaytaradi, buni Railway loglarida ko'rasiz).

## 4-bosqich: Vercel (5 frontend)

Har bir ilova uchun alohida Vercel loyihasi (bitta repo, "Root Directory" har birida farqli):

| Ilova | Root Directory | Muhit o'zgaruvchisi |
|---|---|---|
| admin_web | `apps/web/admin_web` | `NEXT_PUBLIC_API_BASE_URL=https://<gateway-domain>/api/v1` |
| market_web | `apps/web/market_web` | xuddi shu |
| restaurant_web | `apps/web/restaurant_web` | xuddi shu |
| shops_web | `apps/web/shops_web` | xuddi shu |
| seller_web | `apps/web/seller_web` | xuddi shu |

1. https://vercel.com → GitHub bilan kirish → "Add New Project" → repo tanlanadi → "Root Directory"ni yuqoridagi jadvaldan tanlang (Vercel Next.js'ni avtomatik aniqlaydi, qo'shimcha build-sozlash shart emas).
2. "Environment Variables"ga yuqoridagi qatorni qo'shing.
3. Deploy tugmasi bosiladi — natijada `https://<app-nomi>.vercel.app` domeni olinadi.
4. Barcha 5 domen aniq bo'lgach, **3-bosqichning `gateway` xizmatidagi `CORS_ORIGIN`ni shu 5 domen bilan yangilang** (Railway'da redeploy talab qiladi).

### Tekshirish
Har bir Vercel domenini brauzerda ochib, login/OTP oqimi ishlashini, va rasm yuklangan sahifalarda (masalan admin_web'ning Market bo'limi, restaurant_web'ning Menyu sahifasi) rasmlar to'g'ri ko'rinishini tasdiqlash (bu — B qismida tuzatilgan `images.remotePatterns` gapini production'da haqiqatan tekshirish imkoni).

---

## Mobil ilovalar (customer_app, driver_app)

Bu hujjat doirasidan tashqarida (Play Store/App Store'ga chiqarish alohida jarayon), lekin production backend tayyor bo'lgach, ikkala ilova release APK/build paytida `--dart-define=API_BASE_URL=https://<gateway-domain>/api/v1` bilan quriladi (hozirgi lokal-test qurilmalarida ishlatilgan `--dart-define` naqshi bilan bir xil, faqat qiymat production URL'ga almashadi).

---

## Xavfsizlik eslatmasi

`JWT_ACCESS_SECRET` va `INTERNAL_API_KEY` — bularni **hech qachon** repo'ga commit qilmang (`.env` fayllar allaqachon `.gitignore`'da, faqat `.env.example`lar tracked). Production qiymatlari uchun tasodifiy, uzun (32+ belgi) satrlardan foydalaning, masalan: `openssl rand -hex 32`.
