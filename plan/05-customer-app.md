# 05 — Mijoz ilovasi (Customer App)

> Asosiy fayl: [README.md](README.md) · Texnologiya: **Flutter** · Bog'liq: [10-auth-security.md](10-auth-security.md), [13-localization.md](13-localization.md)

## 1. Maqsad
Beshariq aholisi uchun **bitta qulay ilova** orqali ovqat buyurtma qilish, taksi chaqirish va dostavka yuborish. Sodda, tez, 3 tilda.

## 2. Asosiy navigatsiya (Bottom tabs)
```
🏠 Bosh sahifa  |  🍽 Ovqat  |  🚕 Taksi/Dostavka  |  🧾 Buyurtmalar  |  👤 Profil
```
> Boshqa variant: bitta "Xizmatlar" ekranida 3 ta katta karta (Ovqat / Taksi / Dostavka). MVP uchun shu soddaroq.

## 3. Ekranlar ro'yxati

### Kirish oqimi
1. **Splash** — logotip, til/sessiya tekshiruvi.
2. **Til tanlash** (birinchi marta) — O'zbek / Ўзбек / Русский.
3. **Onboarding** (2–3 slayd) — qisqacha tanishtiruv.
4. **Ro'yxatdan o'tish / Kirish** — telefon raqami → OTP.
5. **Maxfiylik va rozilik** — foydalanish shartlari + maxfiylik siyosatiga rozilik (majburiy). → [10-auth-security.md](10-auth-security.md).
6. **Joylashuvga ruxsat** — nega kerakligini tushuntirib so'rash.

### Bosh sahifa
- Joriy manzil (yuqorida, o'zgartirish mumkin).
- 3 ta xizmat kartasi: **Ovqat**, **Taksi**, **Dostavka**.
- Aksiyalar/banner (promokod, yangi oshxona).
- Yaqin/mashhur oshxonalar lentasi.

### Ovqat oqimi
1. **Oshxonalar ro'yxati** — yaqinlik, reyting, ochiq/yopiq, yetkazish vaqti. Filtr (kategoriya, narx), qidiruv.
2. **Oshxona sahifasi** — menyu kategoriyalar bo'yicha, taom kartasi (rasm, narx, tavsif).
3. **Taom detali** — opsiyalar (masalan: porsiya, qo'shimcha), miqdor → savatga.
4. **Savat (Cart)** — taomlar, miqdor, promokod kiritish, yakuniy narx (yetkazish + komissiya ko'rinadi).
5. **Buyurtma tasdiqlash** — manzil, to'lov turi (naqd/Payme/Click/Uzum), izoh.
6. **Buyurtma kuzatuvi** — holat (qabul qilindi → tayyorlanmoqda → yo'lda) + **xaritada haydovchi** (live).

### Taksi oqimi
1. **Xarita** — joriy joy (A), manzil tanlash (B) — qidiruv yoki xaritadan.
2. **Narx oldindan** — masofa, taxminiy narx, ETA.
3. **Chaqirish** — haydovchi qidirilmoqda → topildi (mashina, raqam, haydovchi, reyting).
4. **Safar** — xaritada haydovchi harakati, qo'ng'iroq/chat tugmasi.
5. **Yakun** — narx, to'lov, reyting + izoh.

### Dostavka oqimi
1. **Manzillar** — olib ketish (A) + yetkazish (B).
2. **Paket ma'lumoti** — tavsif, taxminiy og'irlik, qabul qiluvchi telefoni.
3. **Narx + chaqirish** → kuzatuv (taksiga o'xshash).

### Buyurtmalar
- **Faol** (jonli kuzatuv) + **Tarix** (qayta buyurtma "Reorder", chek).

### Profil
- Shaxsiy ma'lumot, manzillarim, to'lov usullari.
- Til o'zgartirish.
- **Hamkorlik bo'limi** (pastda batafsil).
- Promokodlarim, yordam/qo'llab-quvvatlash, shartlar va maxfiylik.
- Chiqish (logout).

## 4. 🤝 Hamkorlik bo'limi (siz alohida so'ragan)
Profil ichida "Hamkorlik" bo'limi — uchta yo'nalish:
1. **Oshxona bo'lish** — "O'z oshxonangizni qo'shing" → ariza formasi (nom, manzil, telefon, hujjat) → admin'ga boradi.
2. **Haydovchi bo'lish** — "Haydovchi sifatida ishlang" → ariza (ism, mashina, prava, hujjatlar) → admin tekshiradi.
3. **Referal / taklif** — do'stni taklif qil, ikkalangiz ham bonus/promokod oling.

> Arizalar admin panelga tushadi (shartnoma/hamkor bo'limi). → [08-admin-workspace.md](08-admin-workspace.md).

## 5. Asosiy texnik talablar
- **3 til** — runtime'da almashish, butun UI tarjima. → [13-localization.md](13-localization.md).
- **Xarita** — MapLibre GL, Beshariq offline tile (kam internetda ham). → [09-maps-navigation.md](09-maps-navigation.md).
- **Real-time kuzatuv** — WebSocket orqali haydovchi joylashuvi.
- **Push** — FCM (buyurtma holati, aksiya).
- **Offline-tolerant** — kesh (menyu, oxirgi manzillar), tarmoq uzilganda xato ko'rsatish.
- **Tez** — skeleton loader, rasm lazy-load, kichraytirilgan rasm (webp).

## 6. UX tamoyillari
- Kam qadam (ovqat buyurtma: 3-4 tap).
- Narx **doim oldindan** ko'rinadi (yashirin to'lov yo'q).
- Yirik tugma, aniq holat, ovozli/vibratsiyali bildirishnoma.
- Xatolik aniq tilda: "Internet yo'q", "Oshxona yopiq", "Haydovchi topilmadi".

## 7. State va arxitektura (Flutter)
```
lib/
├── core/            # tarmoq (dio), xato, locale, theme, di
├── features/
│   ├── auth/        # data / domain / presentation
│   ├── food/
│   ├── taxi/
│   ├── delivery/
│   ├── orders/
│   ├── profile/
│   └── partnership/
├── shared/          # umumiy widget, xarita, push
└── l10n/            # arb fayllar (uz, uz_cyrl, ru)
```
- Pattern: **feature-first + Clean Architecture (data/domain/presentation)**.
- State: **Riverpod** (yoki Bloc).

## 8. Bog'liq fayllar
- Auth/ro'yxat/maxfiylik → [10-auth-security.md](10-auth-security.md)
- Xarita → [09-maps-navigation.md](09-maps-navigation.md)
- Til → [13-localization.md](13-localization.md)
- Narx/promo → [11-pricing-promo.md](11-pricing-promo.md)
