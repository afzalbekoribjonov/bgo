# Beshariq Super-App — Bosh Reja (Master Plan)

> **Loyiha:** Beshariq tumani uchun yagona super-ilova — **Taksi + Dostavka + Ovqat yetkazib berish**.
> **Bu fayl** — barcha reja hujjatlarini bog'lab turuvchi asosiy indeks. Har bir mavzu alohida faylda batafsil yozilgan.
> **Holat:** 📝 Rejalashtirish bosqichi (v0.1) — 2026-06-17.

---

## 🎯 Bir qatorda loyiha

Beshariq tumani aholisi bitta mobil ilova orqali **taksi chaqirishi**, **pochta/dostavka** yuborishi va **oshxonalardan ovqat buyurtma qilishi** mumkin. Haydovchilar bitta ilovada uchala xizmatni bajaradi. Oshxonalar o'z menyusini o'zlari boshqaradi. Administrator esa hamma narsani — buyurtmalar, pul, foiz, promokod, hisobotlar — bitta veb-panel orqali nazorat qiladi.

---

## 🧩 Tizim qismlari (mahsulotlar)

| # | Mahsulot | Kim uchun | Texnologiya | Hujjat |
|---|----------|-----------|-------------|--------|
| 1 | **Mijoz ilovasi** | Foydalanuvchilar | Flutter (Android/iOS) | [05-customer-app.md](05-customer-app.md) |
| 2 | **Haydovchi ilovasi** | Haydovchi/kuryer | Flutter (fon rejimi, GPS) | [06-driver-app.md](06-driver-app.md) |
| 3 | **Oshxona paneli** | Hamkor oshxonalar | Web (PWA) + WebView | [07-restaurant-app.md](07-restaurant-app.md) |
| 4 | **Admin workspace** | Adminstratorlar | Next.js veb-panel | [08-admin-workspace.md](08-admin-workspace.md) |
| 5 | **Backend (microservices)** | Tizim yadrosi | NestJS + Go (location) | [04-backend-services.md](04-backend-services.md) |
| 6 | **Xarita / Navigator** | Hamma ilovalar | OpenStreetMap + OSRM + MapLibre | [09-maps-navigation.md](09-maps-navigation.md) |

---

## 📚 Reja hujjatlari (to'liq ro'yxat)

### Poydevor
- **[00-overview.md](00-overview.md)** — Maqsad, ko'lam (scope), foydalanuvchi rollari, lug'at (glossary), asosiy stsenariylar.
- **[01-architecture.md](01-architecture.md)** — Umumiy tizim arxitekturasi, microservice'lar diagrammasi, ma'lumot oqimi.
- **[02-tech-stack.md](02-tech-stack.md)** — Texnologiya tanlovlari va **nega aynan shular** (asoslar bilan).

### Ma'lumot va backend
- **[03-databases.md](03-databases.md)** — Polyglot persistence, har servisga alohida DB, asosiy ma'lumot modeli.
- **[04-backend-services.md](04-backend-services.md)** — Har bir microservice batafsil: vazifasi, API, DB, hodisalar (events).
- **[14-api-design.md](14-api-design.md)** — API konvensiyalari, API Gateway, namunaviy endpoint'lar, real-time (WebSocket).

### Ilovalar (frontend)
- **[05-customer-app.md](05-customer-app.md)** — Mijoz ilovasi: ekranlar, oqimlar, hamkorlik bo'limi.
- **[06-driver-app.md](06-driver-app.md)** — Haydovchi ilovasi: fon rejimi, ruxsatlar, buyurtma oqimi.
- **[07-restaurant-app.md](07-restaurant-app.md)** — Oshxona paneli: menyu, narx, kategoriya, buyurtma qabul qilish.
- **[08-admin-workspace.md](08-admin-workspace.md)** — Admin panel: hisobotlar, shartnomalar, hamkorlar, sozlamalar.

### Asosiy tizimlar
- **[09-maps-navigation.md](09-maps-navigation.md)** — Bepul xarita, marshrut (routing), navigatsiya — Beshariq uchun.
- **[10-auth-security.md](10-auth-security.md)** — Ro'yxatdan o'tish, kirish, OTP, maxfiylik roziligi, xavfsizlik.
- **[11-pricing-promo.md](11-pricing-promo.md)** — Tariflar, taksi minimal narxi, kuryer foydasi, oshxona ulushi, promokodlar, foyda/zarar hisoblagich.
- **[13-localization.md](13-localization.md)** — Ko'p tillilik: O'zbek (lotin), O'zbek (kiril), Rus.

### Operatsion
- **[12-infrastructure-devops.md](12-infrastructure-devops.md)** — Cloud, hosting, bepul trial'lar, Docker, CI/CD.
- **[15-roadmap-mvp.md](15-roadmap-mvp.md)** — Bosqichma-bosqich yo'l xaritasi, MVP, milestone'lar.
- **[16-risks-decisions.md](16-risks-decisions.md)** — Xavflar, ochiq qarorlar, arxitektura qarorlari (ADR).

---

## 🗺️ Qayerdan o'qishni boshlash kerak?

1. **Tushunish uchun:** `00-overview` → `01-architecture` → `02-tech-stack`.
2. **Backend qurish uchun:** `03-databases` → `04-backend-services` → `14-api-design`.
3. **Ilova qurish uchun:** tegishli ilova hujjati (`05`–`08`) → `09-maps` → `10-auth` → `13-localization`.
4. **Ishni boshlash uchun:** `15-roadmap-mvp` (birinchi nimani quramiz).

---

## ⚡ Asosiy qarorlar (qisqacha snapshot)

| Mavzu | Tanlov | Sabab (qisqa) |
|-------|--------|---------------|
| Mobil ilovalar | **Flutter** | Bitta kod baza, Android+iOS, kuchli fon GPS, WebView, MapLibre |
| Backend | **NestJS** (asosiy) + **Go** (location) | TypeScript bir butun, tartibli microservice, tezkor GPS servisi |
| Veb (admin, oshxona) | **Next.js + TypeScript** | SSR, PWA, tez, WebView'ga mos |
| Ma'lumot bazasi | **PostgreSQL + PostGIS** (servisga 1 ta) + **Redis** | Tranzaksiya + geo + kesh/real-time |
| Xarita | **OpenStreetMap + MapLibre GL** | To'liq bepul, vektorli, Beshariq offline mumkin |
| Marshrut | **OSRM** (o'z serverimizda) | Bepul, faqat O'zbekiston extract'i, tezkor ETA |
| Push | **Firebase Cloud Messaging** | Bepul, ishonchli |
| OTP / SMS | **Eskiz.uz / Play Mobile** | O'zbekiston raqamlari uchun |
| To'lov | **Payme, Click, Uzum** + naqd | Mahalliy standart |
| Hosting (trial) | **Oracle Cloud Always Free** + **Supabase** + **Cloudflare R2** | Eng saxiy bepul resurslar |

> To'liq asoslar: [02-tech-stack.md](02-tech-stack.md) va [16-risks-decisions.md](16-risks-decisions.md).

---

## ✅ Tasdiqlangan qarorlar (2026-06-17)

- **Platforma:** birinchi **faqat Android** (iOS keyin).
- **To'lov:** MVP'da **naqd**; Payme/Click/Uzum keyingi fazada.
- **Boshlash:** **Faza 0 — Monorepo skeleti**.

## 🚦 Loyiha holati

- [x] Reja tuzilmoqda (bu papka)
- [x] MVP ko'lami tasdiqlandi
- [x] Monorepo skeleti yaratildi (✅ Faza 0 — gateway ishlaydi, Flutter ilovalar tayyor)
- [ ] Auth + Mijoz ilovasi (faqat ovqat) — birinchi vertikal
- [ ] Haydovchi ilovasi
- [ ] Taksi moduli
- [ ] Admin panel
- [ ] Ishga tushirish (pilot)

Keyingi qadam → [15-roadmap-mvp.md](15-roadmap-mvp.md).
