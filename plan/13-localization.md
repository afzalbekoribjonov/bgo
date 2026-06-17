# 13 — Ko'p tillilik (Localization / i18n)

> Asosiy fayl: [README.md](README.md) · Talab: **O'zbek (lotin)**, **O'zbek (kiril)**, **Rus** — barcha ilovalarda.

## 1. Qo'llab-quvvatlanadigan tillar
| Kod | Til | Misol |
|-----|-----|-------|
| `uz` | O'zbek (lotin) | "Buyurtma berish" |
| `uz-Cyrl` | O'zbek (kiril) | "Буюртма бериш" |
| `ru` | Rus | "Оформить заказ" |

- Standart: `uz` (lotin).
- Foydalanuvchi birinchi ochilganda til tanlaydi → profilga saqlanadi (`profiles.locale`).
- Runtime'da almashtirish (ilovani qayta ochmasdan).

## 2. Ikki qatlamli tarjima

### A) Interfeys matnlari (statik)
Tugma, sarlavha, xato xabarlari — har ilovada resurs fayllar:
- **Flutter:** ARB fayllar — `app_uz.arb`, `app_uz_cyrl.arb`, `app_ru.arb` (`flutter_localizations` + `intl`).
- **Next.js (admin/oshxona):** `next-intl` yoki `i18next` — `uz.json`, `uz-cyrl.json`, `ru.json`.
- **Backend (xato/xabar):** `i18n` shablon (notif, validatsiya xabarlari).

> Umumiy kalitlarni `packages/i18n/` da saqlab, ilovalar orasida bo'lishish mumkin (monorepo). → [02-tech-stack.md](02-tech-stack.md).

### B) Kontent matnlari (dinamik, DB'dan)
Oshxona taom nomi, tavsif, kategoriya, aksiya banner — **JSONB i18n** ustun:
```json
{
  "uz": "Osh",
  "uz_cyrl": "Ош",
  "ru": "Плов"
}
```
- Oshxona menyu kiritganda 3 tilni to'ldiradi (yoki bittasini → qolgani bo'sh bo'lsa fallback).
- API `Accept-Language` header'ga qarab mos tilni qaytaradi (yo'q bo'lsa fallback `uz`).

## 3. Fallback qoidasi
```
so'ralgan til → bo'sh bo'lsa → uz (lotin) → bo'sh bo'lsa → mavjud birinchi til
```

## 4. Lotin ↔ Kiril (qulaylik)
- O'zbek lotin va kiril — **bir til, ikki yozuv**. Oshxona har ikkisini qo'lda yozmasligi uchun:
  - **Avtomatik transliteratsiya** (lotin → kiril va aksincha) yordamchi tugma berish mumkin (kontent kiritishda).
  - Lekin avtomatik o'girish 100% to'g'ri emas → oshxona tekshirib tasdiqlaydi.
- Interfeys matnlari uchun har uchala variant qo'lda professional tarjima qilinadi.

## 5. Formatlash (lokalga bog'liq)
- **Sana/vaqt:** lokalga mos format.
- **Pul:** so'm, butun son, mingliklar ajratkichi (`12 000 so'm`).
- **Raqam/telefon:** O'zbekiston formati (`+998 ...`).
- **Yo'nalish:** uchala til ham LTR (chapdan o'ngga) — RTL kerak emas.

## 6. Push/SMS tarjima
- Notification shablonlari 3 tilda (`notif_db.templates`).
- Foydalanuvchi `locale`'ga qarab mos tilda yuboriladi.
- Broadcast (admin): admin 3 tilni kiritadi → har kim o'z tilida oladi.

## 7. Jarayon (workflow)
1. Yangi matn → ingliz/uz kalit qo'shiladi.
2. Tarjima fayllariga 3 til qo'shiladi (bo'sh qolmasin — lint tekshiradi).
3. CI'da "yetishmayotgan tarjima" tekshiruvi.

## 8. Bog'liq fayllar
- Kontent modeli (JSONB i18n) → [03-databases.md](03-databases.md)
- Mijoz ilovasi til tanlash → [05-customer-app.md](05-customer-app.md)
- Oshxona menyu (3 til) → [07-restaurant-app.md](07-restaurant-app.md)
- Notification → [04-backend-services.md](04-backend-services.md)
