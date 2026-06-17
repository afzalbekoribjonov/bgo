# 04 — Backend Microservislar

> Asosiy fayl: [README.md](README.md) · Bog'liq: [01-architecture.md](01-architecture.md), [03-databases.md](03-databases.md), [14-api-design.md](14-api-design.md)

Har bir servis: **vazifasi**, **asosiy API**, **DB**, **chiqaradigan/eshitadigan eventlar**.

---

## 1. API Gateway / BFF
**Vazifa:** barcha clientlar uchun yagona kirish nuqtasi.
- JWT tekshirish, rol/ruxsat, rate-limit, CORS.
- `Accept-Language` → locale uzatish.
- REST'ni servislarga marshrutlash + WebSocket proxy (tracking).
- Client-ga moslangan javob (mobil vs admin uchun har xil BFF mumkin).

**DB:** yo'q (faqat Redis: rate-limit, kesh).

---

## 2. Auth / Identity
**Vazifa:** ro'yxatdan o'tish, kirish, OTP, token, rol.
**API (namuna):**
```
POST /auth/otp/request      { phone }
POST /auth/otp/verify       { phone, code } -> { access, refresh, user }
POST /auth/refresh          { refresh }
POST /auth/logout
GET  /auth/me
POST /auth/consent          { privacy: true, version }   # maxfiylik roziligi
```
**DB:** `auth_db`.
**Events:** `UserRegistered`, `UserLoggedIn`.
> Batafsil → [10-auth-security.md](10-auth-security.md).

---

## 3. User / Profile
**Vazifa:** profil, manzillar, qurilmalar (FCM token), sevimlilar.
```
GET/PUT /users/me/profile
GET/POST/DELETE /users/me/addresses
POST /users/me/devices       { fcm_token, platform }
GET/POST /users/me/favorites
```
**DB:** `user_db`. **Events:** `ProfileUpdated`, `DeviceRegistered`.

---

## 4. Order (Orchestrator)
**Vazifa:** har qanday buyurtmaning hayot sikli va orkestratsiyasi (saga).
```
POST /orders                 # FOOD | TAXI | DELIVERY
GET  /orders/:id
GET  /orders (mine)
POST /orders/:id/cancel
```
**Holatlar (status mashina):**
```
DRAFT → PENDING → ACCEPTED → ASSIGNED → IN_PROGRESS
      → (PICKED_UP) → DELIVERED/COMPLETED → CLOSED
      ↘ CANCELLED / FAILED
```
**DB:** `order_db`.
**Events (chiqaradi):** `OrderCreated`, `OrderCancelled`, `OrderCompleted`.
**Eshitadi:** `PaymentConfirmed`, `DriverAssigned`, `RestaurantAccepted`.

> Order — **saga orchestrator**: u Pricing, Restaurant, Dispatch, Payment'ni ketma-ket/parallel chaqiradi va kompensatsiya (rollback) boshqaradi.

---

## 5. Taxi / Ride
**Vazifa:** safar mantiqi, narx, holatlar, yo'l izi.
```
POST /taxi/estimate          { from, to } -> narx + ETA
POST /taxi/trips             # order ichidan chaqiriladi
POST /taxi/trips/:id/start
POST /taxi/trips/:id/finish
```
**DB:** `taxi_db`.
**Events:** `TripRequested`, `TripStarted`, `TripFinished`.
**Eshitadi:** `DriverAssigned`, `LocationUpdate`.

---

## 6. Delivery / Courier
**Vazifa:** dostavka mantiqi + **dispatch (haydovchi topish/biriktirish)**.
```
POST /delivery/estimate
POST /delivery               # order ichidan
POST /delivery/:id/pickup
POST /delivery/:id/dropoff
```
**Dispatch algoritmi (oddiy → aqlli):**
1. Location'dan radius ichidagi bo'sh haydovchilarni ol (`GEOSEARCH`).
2. Eng yaqin/eng yuqori reytingni tanla → taklif yubor (push).
3. N soniyada javob bo'lmasa → keyingisiga (round-robin / nearest).
4. Ovqat uchun: oshxonaga eng yaqin haydovchi (mijozga emas) — taom sovumasin.

**DB:** `delivery_db`.
**Events:** `DriverAssigned`, `Picked`, `Delivered`, `DispatchFailed`.

---

## 7. Restaurant / Catalog
**Vazifa:** oshxona profili, menyu, kategoriya, narx, ish vaqti, buyurtma qabul qilish.
```
# Oshxona paneli uchun
GET/PUT  /restaurant/me
GET/POST/PUT/DELETE /restaurant/me/categories
GET/POST/PUT/DELETE /restaurant/me/menu-items
POST /restaurant/me/items/:id/availability   { is_available }
GET  /restaurant/me/orders                    # kelgan buyurtmalar
POST /restaurant/me/orders/:id/accept|reject|ready

# Mijoz uchun (katalog)
GET /restaurants?lat&lng                       # yaqinlar
GET /restaurants/:id/menu
```
**DB:** `restaurant_db`. **Kesh:** menyu Redis'da (tez-tez o'qiladi).
**Events:** `RestaurantAccepted`, `OrderReady`, `MenuUpdated`.
> Batafsil → [07-restaurant-app.md](07-restaurant-app.md).

---

## 8. Pricing / Tariff
**Vazifa:** narx hisoblash — taksi, dostavka, ovqat yetkazish + ulush/komissiya.
```
POST /pricing/quote   { service, from, to, items?, time } -> { breakdown, total }
GET/PUT /pricing/tariffs           # admin
GET/PUT /pricing/commissions       # admin (oshxona %, kuryer foydasi)
```
**DB:** `pricing_db`.
> Formulalar → [11-pricing-promo.md](11-pricing-promo.md).

---

## 9. Promo / Promotion
**Vazifa:** promokod va aksiyalar.
```
POST /promo/validate  { code, order_draft } -> { valid, discount }
GET/POST/PUT/DELETE /promo/codes   # admin
```
**DB:** `promo_db`. **Eshitadi:** `OrderCompleted` (used_count yangilash).

---

## 10. Payment
**Vazifa:** Payme/Click/Uzum + naqd, hisob-kitob, payout.
```
POST /payments/init     { order_id, provider }
POST /payments/webhook/:provider   # provider callback
GET  /payments/:id
# Hisob-kitob
GET  /payouts (driver/restaurant)
```
**DB:** `payment_db`. **Events:** `PaymentConfirmed`, `PaymentFailed`, `PayoutCreated`.
> Idempotency va webhook xavfsizligi muhim.

---

## 11. Location / Tracking (**Go**)
**Vazifa:** real-time GPS, geo-qidiruv, jonli kuzatuv.
```
WS   /ws/driver        # haydovchi GPS yuboradi (3-5 s)
WS   /ws/track/:order  # mijoz/admin kuzatadi
POST /location/nearby  { lat, lng, radius, role } # dispatch uchun (ichki)
```
**Saqlash:** Redis Geo (`driver_locations`), `driver_status:<id>`.
**Events:** `LocationUpdate` (faqat kuzatuvchilarga pub/sub).
> Tez, kam resurs, alohida masshtablanadi. Batafsil → [09-maps-navigation.md](09-maps-navigation.md).

---

## 12. Routing / Navigation
**Vazifa:** marshrut, masofa, ETA — OSRM ustida.
```
GET /route?from=lat,lng&to=lat,lng     -> polyline, distance, duration
GET /matrix                            -> bir nechta nuqta orasidagi masofa (dispatch)
```
**Ma'lumot:** OSRM (UZ extract), Nominatim (geokoding).
> Batafsil → [09-maps-navigation.md](09-maps-navigation.md).

---

## 13. Notification
**Vazifa:** push (FCM), SMS, in-app xabarnoma.
```
# ichki API (boshqa servislar chaqiradi)
POST /notify/push   { user_id, template, data }
POST /notify/sms    { phone, template, data }
GET  /notify/me     # in-app inbox
```
**DB:** `notif_db` (shablon + log). **Eshitadi:** ko'p eventlar (`OrderCreated`, `DriverAssigned`, ...).
> Til bo'yicha shablon → [13-localization.md](13-localization.md).

---

## 14. Reporting / Analytics
**Vazifa:** hisobotlar — kun/hafta/oy/buyurtma, foyda/zarar, agregatsiya.
```
GET /reports/summary?period=day|week|month&from&to
GET /reports/orders?filters...&sort&page      # filter/sort/search
GET /reports/revenue, /reports/drivers, /reports/restaurants
GET /reports/profit-loss?from&to
GET /reports/export?format=xlsx|csv
```
**DB:** `report_db` (read-replica + materialized views; keyin ClickHouse).
**Eshitadi:** barcha biznes eventlar (event sourcing'ga yaqin) → agregat jadvallar.
> Batafsil → [08-admin-workspace.md](08-admin-workspace.md), [11-pricing-promo.md](11-pricing-promo.md).

---

## 15. Media / Storage
**Vazifa:** rasm/fayl yuklash (taom rasmi, avatar, hujjat), optimizatsiya.
```
POST /media/upload      (multipart) -> { url }
POST /media/sign        -> presigned URL (to'g'ridan R2'ga)
```
**Saqlash:** Cloudflare R2. Rasm: resize/webp.

---

## 16. Servislararo aloqa qoidalari
- **Sinxron** (so'rov-javob, kerak bo'lganda): REST/gRPC — masalan Order → Pricing.
- **Asinxron** (xabar tarqatish): Event Bus (NATS) — `OrderCreated` → ko'p tinglovchi.
- **Idempotency-Key** — yaratish/to'lovda majburiy.
- **Saga + kompensatsiya** — Order orchestrator buzilganda rollback (masalan to'lov bo'lib, haydovchi topilmasa → qaytarish).
- **Circuit breaker / retry** — tashqi servis (to'lov, SMS) uchun.

## 17. Bog'liq fayllar
- API dizayni va namunalar → [14-api-design.md](14-api-design.md)
- Ma'lumot modeli → [03-databases.md](03-databases.md)
- Arxitektura diagrammasi → [01-architecture.md](01-architecture.md)
