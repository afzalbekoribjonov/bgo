# 08 — Admin Workspace (Boshqaruv paneli)

> Asosiy fayl: [README.md](README.md) · Texnologiya: **Next.js + TypeScript** · Bog'liq: [11-pricing-promo.md](11-pricing-promo.md), [04-backend-services.md](04-backend-services.md)

## 1. Maqsad
Butun tizimni **bitta veb-paneldan** boshqarish: hisobotlar, buyurtmalar, shartnomalar, hamkorlar, haydovchilar, promokod, tarif, foiz/ulush, foyda/zarar. Sizning so'zingiz bilan — "analog va barcha qulayliklari mavjud, ideal workspace".

## 2. Rollar (panel ichida)
- **Super-admin** — hammasi (pul, sozlama, foiz).
- **Admin** — kunlik boshqaruv (buyurtma, hamkor, haydovchi).
- **Operator** — call-markaz: buyurtma kuzatish, qo'lda biriktirish, bekor qilish.
- **Accountant** (ixtiyoriy) — faqat moliya/hisobot.
> RBAC → [10-auth-security.md](10-auth-security.md).

## 3. Bo'limlar (Sidebar)

```
📊 Dashboard
📦 Buyurtmalar
   ├─ Barchasi (filter/sort/search)
   ├─ Ovqat
   ├─ Taksi
   └─ Dostavka
🍽 Oshxonalar (hamkorlar)
🚕 Haydovchilar
📝 Shartnomalar
🎟 Promokodlar / Aksiyalar
💰 Moliya
   ├─ Foyda/Zarar
   ├─ Tariflar va ulushlar
   ├─ To'lovlar / Payout
   └─ Hisob-kitob
📈 Hisobotlar (kun/hafta/oy)
👥 Foydalanuvchilar
🔔 Bildirishnomalar (broadcast)
🗺 Xarita (jonli haydovchilar)
⚙️ Sozlamalar
```

## 4. Dashboard
- Bugungi: buyurtma soni (tur bo'yicha), umumiy aylanma, **bizning foyda (komissiya)**, faol haydovchi, faol oshxona.
- Grafiklar: kun davomida buyurtma egri chizig'i, xizmat ulushi (pie), top oshxonalar.
- Tezkor ogohlantirish: kutilayotgan buyurtma, topilmagan haydovchi, rad etilgan.
- Jonli xarita: haydovchilar nuqtalari (online/busy).

## 5. Buyurtmalar (filter/sort/search — siz alohida so'ragan)
- **Jadval** ustunlar: №, tur, mijoz, oshxona/manzil, haydovchi, summa, komissiya, to'lov, holat, sana.
- **Filter:** tur, holat, sana oralig'i, oshxona, haydovchi, to'lov turi, promokod ishlatilgan/yo'q.
- **Sort:** har ustun bo'yicha (sana, summa, ...).
- **Search:** buyurtma №, telefon, mijoz/haydovchi/oshxona nomi.
- **Detal:** to'liq oqim, status tarixi, xaritada yo'l izi, narx tafsiloti.
- **Amallar:** qo'lda haydovchi biriktirish, bekor qilish, qaytarish (refund).
- **Export:** Excel/CSV.

## 6. Oshxonalar (hamkorlar)
- Ro'yxat: nom, holat (faol/kutilmoqda/bloklangan), reyting, buyurtma soni, **komissiya %**.
- Profil: hujjatlar, ish vaqti, menyu ko'rinishi, statistika.
- Tasdiqlash: **hamkorlik bo'limidan kelgan arizalar** (mijoz ilovasidan) shu yerga tushadi → tekshirish → tasdiqlash/rad.
- Har oshxona uchun individual komissiya % belgilash.

## 7. Haydovchilar
- Ro'yxat: ism, telefon, holat, online/offline, reyting, bajarilgan buyurtma, balans.
- **Verifikatsiya:** hujjat (prava, mashina) tekshirish → tasdiqlash/rad.
- Profil: statistika, daromad, payout tarixi, jarima/bonus.
- Bloklash/faollashtirish.
- Haydovchi foydasi/ulushi sozlamasi (umumiy yoki individual).

## 8. Shartnomalar
- Hamkor (oshxona) va haydovchi bilan shartnomalar.
- Shartnoma yaratish/saqlash (PDF generatsiya/yuklash), amal muddati, holat (faol/tugagan).
- Shartlar: komissiya %, to'lov sharti, imzo sanasi.
- Eslatma: muddati tugashga yaqin shartnomalar bo'yicha ogohlantirish.

## 9. Promokodlar / Aksiyalar
- Promokod yaratish: kod, tur (% / fiks summa / bepul yetkazish), qiymat, limit, min buyurtma, amal muddati, xizmat ko'lami (ovqat/taksi/hammasi).
- Aksiya: banner, davr, maqsadli auditoriya.
- Statistika: nechta ishlatildi, qancha chegirma berildi, ROI.
> Batafsil model va mantiq → [11-pricing-promo.md](11-pricing-promo.md).

## 10. Moliya
### Foyda / Zarar hisoblagich (siz alohida so'ragan)
- Davr tanlash → **Daromad** (komissiya + yetkazish foydasi) vs **Xarajat** (chegirma, payout, bonus, operatsion) → **Sof foyda/zarar**.
- Xizmat bo'yicha breakdown (ovqat / taksi / dostavka).
- Grafik trend (kun/hafta/oy).

### Tariflar va ulushlar
- **Taksi:** minimal (boshlang'ich) narx, har km, har daqiqa, kutish narxi, zona bo'yicha.
- **Kuryer/dostavka foydasi:** yetkazish narxidan haydovchi/biz ulushi.
- **Ovqat komissiyasi:** oshxonadan olinadigan % (umumiy + individual).
- O'zgartirish → darhol kuchga kiradi, tarix saqlanadi.

### To'lovlar / Payout
- Provayder bo'yicha (Payme/Click/Uzum/naqd) tushum.
- Haydovchi va oshxonaga payout (davr, summa, holat, hisob).

## 11. Hisobotlar (kun/hafta/oy — siz alohida so'ragan)
- Tayyor hisobotlar: kunlik, haftalik, oylik, buyurtma bo'yicha.
- Har biri filter/sort/search bilan.
- Ko'rsatkichlar: aylanma, komissiya, buyurtma soni, o'rtacha chek, bekor qilish %, yangi mijoz, faol haydovchi.
- Export Excel/CSV/PDF, taqqoslash (o'tgan davrga nisbatan).

## 12. Foydalanuvchilar, Bildirishnoma, Xarita, Sozlamalar
- **Foydalanuvchilar:** ro'yxat, qidiruv, bloklash, buyurtma tarixi.
- **Bildirishnoma (broadcast):** hammaga/segmentga push/SMS yuborish (aksiya), 3 tilda.
- **Jonli xarita:** barcha online haydovchi, faol buyurtmalar.
- **Sozlamalar:** xizmat zonalari (Beshariq chegarasi), ish vaqti, kontaktlar, til, integratsiyalar.

## 13. Texnik
- Next.js (App Router) + TypeScript.
- UI: **Ant Design Pro** yoki **shadcn/ui + TanStack Table** (kuchli jadval: filter/sort/pagination).
- Grafik: Recharts / ECharts.
- Ma'lumot: Reporting servisi API (read-replica) → og'ir so'rovlar asosiy DB'ni bosmaydi.
- Server-side pagination/filter (katta hajm uchun).
- Eksport: server tomonda Excel generatsiya.

## 14. Bog'liq fayllar
- Narx/promo/foyda mantiq → [11-pricing-promo.md](11-pricing-promo.md)
- Reporting servisi → [04-backend-services.md](04-backend-services.md)
- Auth/RBAC → [10-auth-security.md](10-auth-security.md)
