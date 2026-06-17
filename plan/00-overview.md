# 00 — Umumiy ko'rinish (Overview)

> Asosiy fayl: [README.md](README.md)

## 1. Maqsad (Vision)

Beshariq tumani aholisiga **bitta mobil ilova** orqali uchta xizmatni qulay, tez va ishonchli yetkazib berish:
1. **Taksi** — A nuqtadan B nuqtaga odam tashish.
2. **Dostavka (kuryer pochta)** — buyum/hujjat/paket bir manzildan boshqasiga.
3. **Ovqat yetkazib berish** — hamkor oshxonalardan taom buyurtma qilish.

Asosiy g'oya: **lokal monopoliya emas, lokal qulaylik** — katta shaharlardagi Yandex/Wolt darajasidagi tajribani kichik tumanga moslab, arzon va o'zbekcha qilib berish.

## 2. Nima uchun bu ish bo'ladi (loyiha mantiqi)

- Kichik hudud → xaritani **offline va aniq** qilish oson, marshrutlash arzon.
- Bitta haydovchi **uch xil rolda** ishlaydi → haydovchilar kam bo'lsa ham xizmat to'xtamaydi.
- Oshxonalar **o'zi menyusini boshqaradi** → bizning operatsion yukimiz kam.
- Hamma narsa **bitta admin panelda** → kichik jamoa ham boshqara oladi.

## 3. Ko'lam (Scope)

### Kiradi (MVP va keyin)
- Mijoz, haydovchi, oshxona, admin uchun to'liq oqimlar.
- Ovqat, taksi, dostavka — uchala xizmat.
- Real-time haydovchi kuzatuvi (live tracking).
- Ko'p tillilik (uz-latin, uz-kiril, ru).
- Naqd + onlayn to'lov (Payme/Click/Uzum).
- Promokod, tarif, foiz/ulush boshqaruvi.
- Hisobotlar (kun/hafta/oy/buyurtma).

### Hozircha kirmaydi (keyinchalik)
- Boshqa tumanlarga kengayish (lekin arxitektura tayyor bo'ladi).
- iOS App Store relizi (avval Android — bozor shu yerda).
- Mijozlar o'rtasida p2p (faqat biz orqali xizmat).
- Sun'iy intellekt tavsiyalari (keyingi faza).

## 4. Foydalanuvchi rollari (Roles)

| Rol | Tavsif | Asosiy ilova |
|-----|--------|--------------|
| **Customer** (mijoz) | Buyurtma beruvchi aholi | Mijoz ilovasi |
| **Driver** (haydovchi) | Taksichi / kuryer / dostavkachi — bir vaqtda bittasi | Haydovchi ilovasi |
| **Restaurant** (oshxona) | Hamkor oshxona xodimi/egasi | Oshxona paneli (web/WebView) |
| **Admin** | Tizim boshqaruvchisi | Admin workspace |
| **Operator** (call-markaz) | Buyurtmani qo'lda boshqaruvchi (ixtiyoriy) | Admin workspace (cheklangan) |
| **Super-admin** | To'liq huquq, sozlamalar, pul | Admin workspace |

> Rollar va huquqlar (RBAC) batafsil: [10-auth-security.md](10-auth-security.md).

## 5. Asosiy stsenariylar (User journeys)

### A. Ovqat buyurtmasi
1. Mijoz ilovani ochadi → tilni tanlaydi → ro'yxatdan o'tadi (telefon + OTP).
2. Yaqin oshxonalarni ko'radi → menyu → savatga qo'shadi → manzil → to'lov turini tanlaydi.
3. Buyurtma oshxonaga boradi → oshxona qabul qiladi, tayyorlaydi.
4. Tizim eng yaqin **bo'sh haydovchini** topadi → unga kuryer roli bilan biriktiradi.
5. Haydovchi oshxonadan oladi → mijozga yetkazadi → mijoz xaritada kuzatadi.
6. To'lov yopiladi, reyting qo'yiladi.

### B. Taksi
1. Mijoz "Taksi" → A (joriy joy) va B (manzil) → narx oldindan ko'rsatiladi.
2. Tizim yaqin haydovchini taklif qiladi → haydovchi qabul qiladi.
3. Mijoz haydovchini xaritada ko'radi → yo'l → yakun → to'lov + reyting.

### C. Dostavka (kuryer pochta)
1. Mijoz "Dostavka" → olib ketish manzili + yetkazish manzili + paket tavsifi.
2. Narx hisoblanadi → haydovchi (kuryer) biriktiriladi → olib boradi.

### D. Oshxona kuni
1. Oshxona panelni ochadi → yangi buyurtma signal/ovoz.
2. Qabul qiladi/rad etadi → tayyorlanmoqda → tayyor → kuryerga berildi.
3. Kun yakunida o'z hisobotini ko'radi.

### E. Admin kuni
1. Dashboard: bugungi buyurtma, daromad, faol haydovchi soni.
2. Hisobot, promokod, tarif, shartnoma, foyda/zarar nazorati.

## 6. Asosiy maqsadlar (KPI / muvaffaqiyat mezoni)

- Buyurtma yaratishdan haydovchi biriktirilgunga qadar < **60 soniya**.
- Real-time joylashuv yangilanishi < **5 soniya** kechikish.
- Ilova ishga tushishi < **3 soniya**.
- Buyurtma muvaffaqiyat darajasi > **95%**.
- Xarita/marshrut Beshariq ichida **100% qamrov**.

## 7. Lug'at (Glossary)

| Termin | Ma'nosi |
|--------|---------|
| **Order** | Har qanday buyurtma (ovqat/taksi/dostavka) — umumiy tushuncha |
| **Trip / Ride** | Taksi safari |
| **Dispatch** | Buyurtmani haydovchiga biriktirish jarayoni (matching) |
| **Commission** | Bizning ulush (oshxonadan/safardan olinadigan foiz) |
| **Tariff** | Narx qoidalari (boshlang'ich, km, daqiqa, minimal) |
| **POI** | Point of Interest — xaritadagi ahamiyatli nuqta |
| **ETA** | Estimated Time of Arrival — taxminiy yetib borish vaqti |
| **OTP** | Bir martalik SMS kod |
| **RBAC** | Rolga asoslangan ruxsatlar tizimi |
| **PWA** | Progressive Web App |

## 8. Bog'liq fayllar
- Arxitektura → [01-architecture.md](01-architecture.md)
- Yo'l xaritasi → [15-roadmap-mvp.md](15-roadmap-mvp.md)
- Tariflar va ulush → [11-pricing-promo.md](11-pricing-promo.md)
