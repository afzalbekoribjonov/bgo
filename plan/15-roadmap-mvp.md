# 15 — Yo'l xaritasi va MVP

> Asosiy fayl: [README.md](README.md) · Bu fayl — **birin-ketin nimani quramiz**.

## 1. Tamoyil: vertikal bo'laklar (vertical slices)
Hamma servisni birato'la qurmaymiz. Har bosqichda **bitta to'liq ishlaydigan oqim** (mijoz → backend → haydovchi → admin) yetkazamiz. Shunda har bosqich oxirida **ishlaydigan mahsulot** bo'ladi.

> **Birinchi navbat — OVQAT** (eng oson tekshiriladigan, hamkor oshxona kerak, taksidan sodda dispatch).

## 2. Bosqichlar (Phases)

### 🟢 Faza 0 — Poydevor (skelet)
**Maqsad:** ishga tushadigan bo'sh karkas.
- [ ] Monorepo (Turborepo + Flicha apps) — `apps/`, `services/`, `packages/`, `infra/`.
- [ ] Docker Compose: Postgres + PostGIS, Redis, NATS.
- [ ] API Gateway (NestJS) + sog'liq tekshiruvi.
- [ ] CI (lint, test, build).
- [ ] Flutter mijoz + haydovchi "hello world" + 3 til skeleti.
**Natija:** `docker compose up` bilan tizim ko'tariladi.

### 🟢 Faza 1 — Auth + Profil (hamma uchun asos)
- [ ] Auth servisi: OTP (dev rejimda kod logga), JWT, refresh, rollar.
- [ ] User servisi: profil, manzillar, qurilma (FCM).
- [ ] Mijoz ilovasi: til tanlash → ro'yxat/kirish → **maxfiylik roziligi** → profil.
- [ ] SMS gateway (Eskiz) ulanishi.
**Natija:** foydalanuvchi ro'yxatdan o'tib, kira oladi.

### 🟢 Faza 2 — OVQAT (birinchi to'liq xizmat) ⭐ MVP yadrosi
- [ ] Restaurant servisi: oshxona, kategoriya, menyu, narx (3 til).
- [ ] Oshxona paneli (Next.js): menyu boshqaruvi + buyurtma qabul qilish (live).
- [ ] Pricing (oddiy: taom + dostavka) + Promo (oddiy promokod).
- [ ] Order servisi: ovqat buyurtmasi oqimi.
- [ ] Mijoz ilovasi: oshxona ro'yxati → menyu → savat → buyurtma → kuzatish.
- [ ] Media servisi (R2): taom rasmlari.
- [ ] Notification: push (FCM) buyurtma holatlari.
**Natija:** mijoz ovqat buyurtma qiladi, oshxona qabul qiladi (haydovchisiz — o'zi olib ketish yoki keyingi fazada yetkazish).

### 🟢 Faza 3 — Haydovchi + Dostavka (ovqatni yetkazish)
- [ ] Location servisi (Go): GPS, Redis Geo, WebSocket.
- [ ] Routing servisi: OSRM (UZ extract) — masofa/ETA/marshrut.
- [ ] Delivery servisi: dispatch (yaqin haydovchi topish).
- [ ] Haydovchi ilovasi: online toggle, **fon GPS**, buyurtma taklifi, kuryer oqimi (oshxona→mijoz).
- [ ] Mijoz ilovasi: xaritada jonli kuzatuv.
**Natija:** ovqat oshxonadan mijozga yetkaziladi, jonli kuzatuv ishlaydi.

### 🟢 Faza 4 — TAKSI
- [ ] Taxi servisi: safar mantiqi, narx (min_fare, km, daqiqa).
- [ ] Mijoz ilovasi: taksi oqimi (A/B, narx, chaqirish, safar).
- [ ] Haydovchi ilovasi: taksi roli (bir xil online holat).
**Natija:** taksi to'liq ishlaydi.

### 🟢 Faza 5 — DOSTAVKA (kuryer pochta)
- [ ] Dostavka oqimi (A→B paket) — Delivery servisini kengaytirish.
- [ ] Mijoz ilovasi: dostavka oqimi.
**Natija:** uchala xizmat ham ishlaydi.

### 🟢 Faza 6 — ADMIN WORKSPACE (to'liq)
- [ ] Reporting servisi: agregatsiya (kun/hafta/oy).
- [ ] Admin: dashboard, buyurtmalar (filter/sort/search), oshxona/haydovchi boshqaruv.
- [ ] Shartnomalar, hamkorlik arizalari.
- [ ] Tarif/komissiya/promo boshqaruv, **foyda/zarar hisoblagich**.
- [ ] Payout/hisob-kitob.
**Natija:** to'liq boshqaruv paneli.

### 🟢 Faza 7 — To'lov + Yaxshilash
- [ ] Payme/Click/Uzum integratsiya.
- [ ] Reyting/sharh tizimi.
- [ ] Aksiya/banner, referal.
- [ ] Optimizatsiya, monitoring, xato kuzatuv (Sentry).

### 🟢 Faza 8 — Pilot ishga tushirish (Beshariq)
- [ ] 3–5 oshxona, 5–10 haydovchi bilan yopiq sinov.
- [ ] Fikr-mulohaza → tuzatish.
- [ ] Ommaviy reliz (APK tarqatish / Play Store).

## 3. MVP aniq ta'rifi (eng kichik ishlaydigan mahsulot)
> **MVP = Faza 0–3:** Auth + Ovqat buyurtma + Oshxona paneli + Haydovchi yetkazish + jonli kuzatuv.
> Taksi/Dostavka/To'liq admin keyin qo'shiladi. Bu bilan tezda real foydalanuvchida sinab ko'ramiz.

## 4. Birinchi sprint (amaliy boshlash)
1. Monorepo skeleti + Docker Compose (Postgres/Redis/NATS).
2. API Gateway + Auth (OTP dev rejim) + Mijoz ilovasi kirish ekrani (3 til).
3. Bitta test oshxona + menyu + bitta ovqat buyurtma oqimi (uchidan uchiga).

> Tayyor bo'lganda, har faza oxirida `README.md` dagi "Loyiha holati" belgilab boriladi.

## 5. Bog'liq fayllar
- Arxitektura → [01-architecture.md](01-architecture.md)
- Servislar → [04-backend-services.md](04-backend-services.md)
- Infra → [12-infrastructure-devops.md](12-infrastructure-devops.md)
- Xavflar → [16-risks-decisions.md](16-risks-decisions.md)
