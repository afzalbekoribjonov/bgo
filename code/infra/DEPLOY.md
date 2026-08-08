# Beshariq — production'ga joylashtirish qo'llanmasi

Bu hujjat butun tizimni (baza, marshrut serveri, 7 backend xizmat, 5 frontend) birinchi marta production'ga chiqarish uchun bosqichma-bosqich qo'llanma. Har bosqichda aniq buyruqlar/muhit o'zgaruvchilari ro'yxati bor.

**Muhim eslatma**: hisob yaratish va haqiqiy "Deploy" tugmasini bosish — har doim SIZ bajarasiz (avtomatlashtirib bo'lmaydigan, xavfsizlik nuqtai nazaridan sizga tegishli bosqichlar). Bu hujjat faqat aniq yo'l-yo'riq beradi.

## Tavsiya etilgan stack

| Qatlam | Xizmat | Nima uchun |
|---|---|---|
| Ma'lumotlar bazasi (6 ta) | **Neon** | Bepul, PostGIS kerak emas (tasdiqlangan), Prisma bilan mos — [`scripts/neon-setup.md`](scripts/neon-setup.md) |
| Marshrut serveri (OSRM) | **Fly.io** | Docker image'ni to'g'ridan-to'g'ri, doimiy volume bilan ishga tushiradi — [`osrm/README.md`](osrm/README.md) |
| Backend (gateway + 6 xizmat) | **Fly.io** | Har xizmat — alohida Fly app, `Dockerfile`+`turbo prune` orqali quriladi, auto-stop/auto-start (bo'sh turganda $0 xarajat), xizmatlar orasi Flycast (xususiy tarmoq) orqali |
| Frontend (5 ta) | **Vercel** | Standart Next.js server-mode, hech qanday kod o'zgarishisiz (dinamik `[id]` marshrutlar bor — statik eksport hozircha ko'rib chiqilmagan), bepul tarifi bu ko'lam uchun yetarli |

**Muqobillar**: Frontend uchun Cloudflare Pages (bepul, cheksiz so'rov) — lekin bu 5 ilovaning barchasida dinamik `[id]` marshrutlar borligi sababli statik eksport (`output:'export'`) talab qiladi, bu katta va xavfli qayta qurish (alohida so'ralganda ko'rib chiqiladi).

**Eslatma — Fly.io xarajati**: yangi hisoblarga endi doimiy bepul tarif berilmaydi (2024-yildan buyon), faqat bir martalik ~$5 kredit. Auto-stop/auto-start yoqilgan holda (bu qo'llanmada shunday sozlangan) sinov davrida xarajat deyarli nolga yaqin — xizmatlar so'rov bo'lmasa avtomatik to'xtaydi, kelganda ~1-2s ichida uyg'onadi. Doimiy, uzluksiz ishlatilganda taxminan $25-50/oy (9 ta xizmat: 7 backend + gateway + OSRM).

---

## 1-bosqich: Neon (ma'lumotlar bazalari)

To'liq qo'llanma: [`scripts/neon-setup.md`](scripts/neon-setup.md). Qisqacha: hisob yaratish → 6 ta baza (`auth_db`, `restaurant_db`, `order_db`, `market_db`, `marketplace_db`, `support_db`) → har biri uchun `connection_limit=5&pool_timeout=20` bilan connection string olish. Bu bosqich boshqalardan MUSTAQIL — birinchi bajariladi, chunki 3-bosqichdagi backend xizmatlar shu `DATABASE_URL`larga muhtoj.

## 2-bosqich: Fly.io (OSRM)

To'liq qo'llanma: [`osrm/README.md`](osrm/README.md#production-joylashtirish-flyio). Natijada `https://beshariq-osrm.fly.dev` kabi doimiy URL olasiz — 3-bosqichda `order` xizmatining `OSRM_URL`iga qo'yiladi.

## 3-bosqich: Fly.io (backend — gateway + 6 xizmat)

**Holat**: bu bosqich BAJARILGAN va jonli ishlab turibdi — quyida amalda ishlatilgan aniq oqim tasvirlangan (kelajakda qayta joylashtirish/yangi muhit uchun ma'lumotnoma sifatida).

Konteynerlash uchun repo ildizida bitta umumiy `Dockerfile` (`turbo prune --docker` orqali har bir xizmat uchun qayta ishlatiladi, `SERVICE` build-arg bilan farqlanadi), `.dockerignore`, `docker-entrypoint.sh` bor. Har xizmat uchun alohida `fly.<xizmat>.toml` (`fly.gateway.toml`, `fly.auth.toml`, `fly.restaurant.toml`, `fly.order.toml`, `fly.market.toml`, `fly.marketplace.toml`, `fly.support.toml`) — barchasi `auto_stop_machines="stop"`/`auto_start_machines=true`/`min_machines_running=0` bilan (bo'sh turganda $0 xarajat).

1. `flyctl` o'rnatish + login: `iwr https://fly.io/install.ps1 -useb | iex` (Windows), so'ng `flyctl auth login` (brauzer orqali, o'zingiz tasdiqlaysiz).
2. Har bir xizmat uchun Fly app yaratish: `flyctl apps create beshariq-<xizmat>` (7 marta: gateway, auth, restaurant, order, market, marketplace, support).
3. Tarmoq — **faqat `gateway`ga** ochiq IP, qolgan 6 tasi FAQAT xususiy (Flycast):
   ```powershell
   flyctl ips allocate-v6 --private -a beshariq-auth
   flyctl ips allocate-v6 --private -a beshariq-restaurant
   flyctl ips allocate-v6 --private -a beshariq-order
   flyctl ips allocate-v6 --private -a beshariq-market
   flyctl ips allocate-v6 --private -a beshariq-marketplace
   flyctl ips allocate-v6 --private -a beshariq-support
   flyctl ips allocate-v4 --shared -a beshariq-gateway
   flyctl ips allocate-v6 -a beshariq-gateway
   ```
   **MUHIM — Flycast port gotcha**: Flycast (`<app>.flycast`) Fly Proxy orqali o'tadi (shu sababli auto-stop/start ichki chaqiruvlar uchun ham ishlaydi — oddiy `.internal` buni CHETLAB o'tadi va uxlab qolgan xizmatni uyg'otmaydi). Lekin bu degani boshqa xizmatga chaqiruv xizmatning ICHKI portiga emas (masalan `:4001`), balki **standart HTTP portiga (80, port ko'rsatilmasdan)** qilinishi kerak: `http://beshariq-auth.flycast` — TO'G'RI; `http://beshariq-auth.flycast:4001` — ADASHADI (ECONNRESET).
4. Sirlar (`fly secrets set`) — barcha 7 xizmatga umumiy:
   ```powershell
   $jwt = <openssl rand -hex 32>; $key = <openssl rand -hex 32>
   flyctl secrets set JWT_ACCESS_SECRET=$jwt INTERNAL_API_KEY=$key -a beshariq-<xizmat>
   ```
   Har xizmatga xos: `DATABASE_URL` (Neon connection string + `&connection_limit=5&pool_timeout=20`, 6 DB'li xizmatning har biriga), `auth`ga qo'shimcha `JWT_REFRESH_SECRET`, `ADMIN_PHONES`, `FIREBASE_SERVICE_ACCOUNT_B64` (`firebase-service-account.json`ning base64'i — fayl image'ga yozilmaydi/commit qilinmaydi, konteyner ishga tushishda dekodlanadi), `support`ga `GEMINI_API_KEY`, (agar mavjud bo'lsa) `restaurant`/`market`/`marketplace`ga `IMAGEKIT_PUBLIC_KEY`/`IMAGEKIT_PRIVATE_KEY`/`IMAGEKIT_URL_ENDPOINT`.

   **Bilinган cheklov**: agar ImageKit sozlanmasa, bu 3 xizmat lokal diskka yozadi — Fly'ning fayl tizimi vaqtinchalik, shuning uchun yuklangan rasmlar HAR auto-stop/redeploy'da yo'qoladi. Production'da ImageKit hisob ochib kalitlarni qo'shish qat'iy tavsiya etiladi.
5. Joylashtirish tartibi — barg-xizmatlardan boshlab (har birini `fly deploy -c fly.<xizmat>.toml --remote-only`):
   1. **auth** (bog'liqligi yo'q)
   2. **restaurant, market, marketplace, support** (faqat auth'ga bog'liq — istalgan tartibda)
   3. **order** (auth+market+restaurant+OSRM'ga bog'liq — 2-bosqichdagi OSRM avval jonli bo'lishi kerak)
   4. **gateway** (barcha 6 tasiga bog'liq — ENG OXIRIDA)
6. Tekshirish: `curl https://beshariq-gateway.fly.dev/api/v1/health` — 200 qaytishi kerak. Ichki xizmatlarni tekshirish uchun (ochiq IP'siz) `flyctl ssh console -a beshariq-<xizmat> -C "node -e \"fetch('http://localhost:<port>/api/v1/health').then(r=>r.text()).then(console.log)\""` (slim image'da `curl` yo'q, Node'ning o'z `fetch`idan foydalaniladi).

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
4. Barcha 5 domen aniq bo'lgach, **3-bosqichning `gateway` xizmatidagi `CORS_ORIGIN`ni shu 5 domen bilan yangilang** (`flyctl secrets set CORS_ORIGIN="https://..." -a beshariq-gateway`, avtomatik redeploy qiladi).

### Tekshirish
Har bir Vercel domenini brauzerda ochib, login/OTP oqimi ishlashini, va rasm yuklangan sahifalarda (masalan admin_web'ning Market bo'limi, restaurant_web'ning Menyu sahifasi) rasmlar to'g'ri ko'rinishini tasdiqlash (bu — B qismida tuzatilgan `images.remotePatterns` gapini production'da haqiqatan tekshirish imkoni).

---

## Mobil ilovalar (customer_app, driver_app)

Bu hujjat doirasidan tashqarida (Play Store/App Store'ga chiqarish alohida jarayon), lekin production backend tayyor bo'lgach, ikkala ilova release APK/build paytida `--dart-define=API_BASE_URL=https://<gateway-domain>/api/v1` bilan quriladi (hozirgi lokal-test qurilmalarida ishlatilgan `--dart-define` naqshi bilan bir xil, faqat qiymat production URL'ga almashadi).

---

## Xavfsizlik eslatmasi

`JWT_ACCESS_SECRET` va `INTERNAL_API_KEY` — bularni **hech qachon** repo'ga commit qilmang (`.env` fayllar allaqachon `.gitignore`'da, faqat `.env.example`lar tracked). Production qiymatlari uchun tasodifiy, uzun (32+ belgi) satrlardan foydalaning, masalan: `openssl rand -hex 32`.
