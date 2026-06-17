# 06 — Haydovchi ilovasi (Driver App)

> Asosiy fayl: [README.md](README.md) · Texnologiya: **Flutter** · Bog'liq: [09-maps-navigation.md](09-maps-navigation.md), [04-backend-services.md](04-backend-services.md)

## 1. Maqsad
Bitta haydovchi **uchala rolda** ishlaydi — taksichi, kuryer (ovqat), dostavkachi. Tizim buyurtma turiga qarab haydovchiga mos rolni biriktiradi. Ilova **fonda ishlashi** va qurilma ruxsatlarini to'g'ri olishi shart.

## 2. Asosiy g'oya: yagona "Online" holat
- Haydovchi **Online** bo'ladi → tizim unga **har qanday** mos buyurtmani (taksi/ovqat/dostavka) yuboradi.
- Ixtiyoriy sozlama: faqat ma'lum xizmatlarni qabul qilish (masalan "faqat taksi"). MVP: hammasi yoqilgan.
- Buyurtma turini taklif ekrani ko'rsatadi (🚕 / 🍽 / 📦 belgisi bilan).

## 3. Ekranlar

### Kirish va tekshiruv
1. **Kirish** — telefon + OTP (mijoz bilan bir xil auth, lekin `driver` roli).
2. **Hujjat tekshiruvi (verification)** — prava, mashina, hujjat rasmlari → admin tasdiqlaydi. Tasdiqlanmaguncha "kutilmoqda".
3. **Ruxsatlar ekrani** — joylashuv (doimiy/fonda), bildirishnoma, batareya optimizatsiyasini o'chirish.

### Asosiy
4. **Bosh ekran (xarita)** — joriy joy, **Online/Offline** kaliti, bugungi daromad va statistika.
5. **Yangi buyurtma taklifi** — to'liq ekran + ovoz/vibratsiya: tur, manzil, masofa, taxminiy daromad, **Qabul / Rad** (taymer bilan, masalan 15 s).
6. **Faol buyurtma (navigatsiya)**:
   - **Taksi:** A'ga bor → mijozni ol → B'ga → yakunla.
   - **Ovqat (kuryer):** Oshxonaga bor → taomni ol (tasdiqlash) → mijozga yetkaz → yakunla.
   - **Dostavka:** olib ketish → topshirish.
   - Har bosqichda: xaritada marshrut, "Yetib keldim", "Oldim", "Topshirdim" tugmalari, qo'ng'iroq/chat.
7. **Buyurtma yakuni** — summa, mijoz reytingi, keyingi buyurtmaga tayyor.
8. **Daromad / Hisobot** — kun/hafta, buyurtmalar soni, masofa, balans, payout (yechib olish).
9. **Profil** — hujjatlar, mashina, sozlamalar, til.

## 4. ⚙️ Qurilma ruxsatlari va fon rejimi (eng muhim qism)

### Kerakli ruxsatlar (Android)
| Ruxsat | Maqsad |
|--------|--------|
| `ACCESS_FINE_LOCATION` | Aniq GPS |
| `ACCESS_BACKGROUND_LOCATION` | Ilova fonda/yopiqligida joylashuv |
| `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_LOCATION` | Doimiy fon xizmati |
| `POST_NOTIFICATIONS` | Buyurtma bildirishnomalari |
| `WAKE_LOCK` | Tizim uxlamasligi |
| Battery optimization ignore | Tizim ilovani o'chirmasligi |
| `CALL_PHONE` (ixtiyoriy) | Mijozga qo'ng'iroq |

### Fon rejimi yechimi
- **`flutter_background_geolocation`** (eng ishonchli) yoki `geolocator` + **foreground service**.
- **Doimiy notifikatsiya** ("Siz Onlinesiz — buyurtma kutilmoqda") — Android talab qiladi.
- GPS yuborish: harakatda **3–5 s**, turganda kamroq (batareya tejash, masofa filtri).
- WebSocket bilan Location servisiga uzatish. Tarmoq uzilsa — navbatga olib, qayta ulanish.
- **Doze/App Standby** ga qarshi: foreground service + batareya optimizatsiyasini o'chirishni so'rash.

### iOS (kelajak)
- `Always` location, Background Modes (location updates), push.

## 5. Dispatch (haydovchiga buyurtma berish) — haydovchi tomoni
1. Online haydovchi joylashuvi Redis Geo'da.
2. Yangi buyurtma → Delivery/Taxi servisi yaqin haydovchilarni topadi.
3. Push + WebSocket orqali **taklif** keladi → taymer.
4. Qabul qilsa → buyurtma biriktiriladi, boshqalardan olib tashlanadi.
5. Rad/taymer tugasa → keyingi haydovchiga.

> Algoritm tafsiloti → [04-backend-services.md](04-backend-services.md) (Delivery, Dispatch).

## 6. Ovqat kuryer oqimi (siz alohida ta'kidlagan)
1. Buyurtma qabul qilindi → ilova **oshxona manziliga** marshrut chizadi.
2. Haydovchi "Oshxonaga yetib keldim" → oshxona panelida ko'rinadi.
3. Taomni oladi → "Taomni oldim" (ixtiyoriy: tasdiq kodi/rasm).
4. Endi **mijoz manziliga** marshrut → "Yetkazib berdim" → yakun.
> Muhim: ovqatda dispatch **oshxonaga eng yaqin** haydovchini tanlaydi (taom issiq qolsin).

## 7. Texnik talablar
- Real-time GPS (WebSocket) — kam batareya, ishonchli qayta ulanish.
- Navigatsiya: MapLibre + OSRM marshrut (turn-by-turn keyingi fazada; MVP: marshrut chizig'i + masofa/ETA).
- Offline-tolerant: tarmoq uzilsa buyurtma holatini saqlab, qayta ulanganda sinxron.
- Push: yuqori muhimlik (full-screen intent — uyquda ham ko'rinadi).
- Xavfsizlik: faqat tasdiqlangan haydovchi ishlaydi.

## 8. Arxitektura (Flutter)
```
lib/
├── core/            # location service, ws, foreground service, di
├── features/
│   ├── auth/
│   ├── verification/
│   ├── home/        # online toggle, xarita
│   ├── offer/       # buyurtma taklifi
│   ├── active_job/  # faol buyurtma (taksi/ovqat/dostavka)
│   ├── earnings/
│   └── profile/
└── l10n/
```

## 9. Bog'liq fayllar
- Xarita/marshrut/real-time → [09-maps-navigation.md](09-maps-navigation.md)
- Dispatch va servislar → [04-backend-services.md](04-backend-services.md)
- Daromad/foiz → [11-pricing-promo.md](11-pricing-promo.md)
- Auth → [10-auth-security.md](10-auth-security.md)
