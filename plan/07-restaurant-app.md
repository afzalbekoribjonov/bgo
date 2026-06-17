# 07 — Oshxona paneli (Restaurant App)

> Asosiy fayl: [README.md](README.md) · Texnologiya: **Next.js PWA** (WebView ichida ham, brauzerda ham) · Bog'liq: [04-backend-services.md](04-backend-services.md)

## 1. Maqsad
Hamkor oshxonalar **o'z menyusini, narxini, kategoriyalarini o'zlari boshqarsin** va **kelgan buyurtmalarni** real vaqtda qabul qilib, tayyorlab, kuryerga topshirsin.

## 2. Nega Web (PWA) + WebView?
- Bitta kod baza → desktopda (oshxona kompyuteri/planshet) ham, mobil ilova ichida (WebView) ham ishlaydi.
- Siz so'ragandek: **apk ichida WebView shaklida ochiladi**, lekin brauzerda alohida ham kira oladi.
- PWA → "ilova kabi" o'rnatish, push, offline kesh.
- Yangilanish oson (server tomonda — store relizi shart emas).

> Ixtiyoriy: yengil Flutter qobiq ilova WebView'ni ochadi + native push/ovoz. MVP: PWA yetarli.

## 3. Ekranlar

### Kirish
1. **Kirish** — telefon + OTP (yoki login/parol), `restaurant` roli.
2. **Oshxona tanlash** (agar bir egada bir nechta filial bo'lsa).

### Asosiy panel
3. **Dashboard** — bugungi buyurtma soni, daromad, o'rtacha tayyorlash vaqti, reyting.
4. **Buyurtmalar (live)** — eng muhim ekran:
   - Yangi buyurtma → **ovozli signal + popup**.
   - Holatlar: **Yangi → Qabul qildim → Tayyorlanmoqda → Tayyor → Kuryerga berildi**.
   - Har buyurtmada: taomlar, miqdor, izoh, mijoz manzili (umumiy), taxminiy tayyorlash vaqti.
   - Rad etish (sababi bilan).
5. **Menyu boshqaruvi** (siz alohida so'ragan):
   - **Kategoriyalar** — qo'shish/tahrirlash/tartiblash (Issiq taomlar, Salatlar, Ichimliklar...).
   - **Taomlar** — nom (3 til), tavsif, **narx**, rasm, kategoriya, mavjudlik (bor/yo'q).
   - **Opsiyalar** — porsiya (kichik/katta), qo'shimchalar (masalan +go'sht), narx farqi.
   - **Tezkor amal** — "Bugun yo'q" deb belgilash (stop-list).
6. **Ish vaqti** — har kun uchun ochilish/yopilish; "Hozir yopiq" tugmasi (band bo'lganda).
7. **Hisobotlar** — kun/hafta/oy: buyurtma, daromad, komissiya (bizning ulush), eng ko'p sotilgan taom.
8. **Sozlamalar / Profil** — oshxona ma'lumoti, logotip, telefon, manzil (xaritada), til.

## 4. Menyu modeli (eslatma)
- Nom/tavsif **3 tilda** (JSONB `name_i18n`). → [13-localization.md](13-localization.md).
- Narx so'mda, butun son.
- Rasm → Media servisi (R2), webp, kichraytirilgan.
- Mavjudlik (`is_available`) tez o'zgaradi → kesh invalidatsiya.
> Model → [03-databases.md](03-databases.md) (Restaurant bo'limi).

## 5. Real-time buyurtma (muhim)
- Yangi buyurtma: **WebSocket / FCM** + **ovozli signal** (oshxona e'tibor bermay qolmasin).
- Avtomatik qabul taymeri: N daqiqada javob bo'lmasa → admin/operatorga ogohlantirish.
- Holat o'zgarishi mijoz ilovasiga real-time uzatiladi.

## 6. UX tamoyillari
- **Mobil-birinchi, yirik tugma** — oshxona xodimi band, tez ishlashi kerak.
- Kam matn, aniq ranglar (yangi=ko'k, tayyor=yashil).
- Bitta ekrandan buyurtmani boshqarish (kam tap).
- Ovoz/bildirishnoma o'chib qolmasligi (PWA notification + keep-awake).

## 7. Texnik
- Next.js (App Router) + TypeScript, PWA (service worker).
- State: React Query (server holati) + Zustand (lokal).
- Real-time: WebSocket (Gateway orqali) + FCM (fon push).
- WebView'da: native push'ni Flutter qobiq orqali (kelajak) yoki PWA push.

## 8. Bog'liq fayllar
- Restaurant servisi/API → [04-backend-services.md](04-backend-services.md)
- Menyu modeli → [03-databases.md](03-databases.md)
- Til → [13-localization.md](13-localization.md)
- Komissiya/ulush → [11-pricing-promo.md](11-pricing-promo.md)
