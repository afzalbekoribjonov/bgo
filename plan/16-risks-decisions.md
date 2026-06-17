# 16 — Xavflar va Arxitektura Qarorlari (ADR)

> Asosiy fayl: [README.md](README.md)

## A qism — Xavf-xatar registri (Risks)

| # | Xavf | Ehtimol | Ta'sir | Yumshatish (mitigation) |
|---|------|---------|--------|--------------------------|
| R1 | **Haydovchi yetishmasligi** (kichik tuman) | Yuqori | Yuqori | Bitta haydovchi 3 rolda; bonus/rag'bat; pilotda kam hudud |
| R2 | **Oshxona qiziqmasligi** | O'rta | Yuqori | Past komissiya boshida; panel juda sodda; ariza orqali jalb |
| R3 | **OSM'da Beshariq ko'chalari to'liq emas** | Yuqori | O'rta | OSM'ni o'zimiz to'ldiramiz; o'z POI/zona qatlamimiz |
| R4 | **Fon GPS Android'da o'chib qolishi** (Doze) | Yuqori | Yuqori | Foreground service + batareya optim. o'chirish + qayta ulanish |
| R5 | **Internet sifati past** (qishloq) | O'rta | O'rta | Offline kesh, kichik payload, qayta urinish, offline xarita |
| R6 | **To'lov integratsiyasi murakkab/kechikadi** | O'rta | O'rta | Naqd bilan boshlash; onlayn keyin |
| R7 | **Microservice murakkabligi kichik jamoaga og'ir** | Yuqori | O'rta | Modular monolith'dan boshlash (ADR-001) |
| R8 | **Bepul tier limiti tugashi** | O'rta | O'rta | Oracle Always Free + o'z hostingimiz; xarajat kuzatuvi |
| R9 | **Shaxsiy ma'lumot qonuni** | O'rta | Yuqori | Minimal ma'lumot, rozilik, UZ hosting, account o'chirish |
| R10 | **Soliq/fiskal chek talabi** | O'rta | O'rta | Ichki chek; qonun aniqlangach OFD integratsiya |
| R11 | **Suiiste'mol** (soxta buyurtma, promo abuse) | O'rta | O'rta | Rate-limit, per-user promo limit, verifikatsiya |
| R12 | **Bitta nuqta ishdan chiqishi** (single server) | O'rta | Yuqori | Backup, health-check, restart policy; keyin replikatsiya |

## B qism — Arxitektura Qarorlari (ADR)

### ADR-001 — Modular monolith → microservices
- **Kontekst:** to'liq microservice kichik jamoa va bitta tuman uchun boshida og'ir.
- **Qaror:** kodni servislarga ajratamiz (chegara aniq), lekin boshida kam konteynerda deploy. Yuk oshganda ajratamiz.
- **Sabab:** tezroq yetkazish, kam operatsion yuk, lekin kelajak ochiq.
- **Oqibat:** chegaralarni qattiq saqlash kerak (boshqa servis DB'siga tegmaslik).

### ADR-002 — Flutter (mobil)
- **Qaror:** Flutter, React Native emas.
- **Sabab:** fon GPS, MapLibre, WebView, unumdorlik, bitta kod baza.

### ADR-003 — NestJS + Go (location)
- **Qaror:** asosiy backend NestJS, real-time location Go'da.
- **Sabab:** TS bir butunlik + tartib; GPS yuki uchun Go tezligi.

### ADR-004 — PostgreSQL + PostGIS asosiy DB
- **Qaror:** relational + geo, NoSQL emas.
- **Sabab:** pul/buyurtma tranzaksion; PostGIS geo'ni qoplaydi.

### ADR-005 — OSM + OSRM + MapLibre (xarita)
- **Qaror:** Google/Yandex emas, o'z OSM stack.
- **Sabab:** to'liq bepul, offline, kichik hudud, cheksiz so'rov.

### ADR-006 — Telefon + OTP auth
- **Qaror:** email/parol emas, telefon + OTP.
- **Sabab:** O'zbekiston bozori standarti; soddaroq.

### ADR-007 — Naqd birinchi, onlayn to'lov keyin
- **Qaror:** MVP naqd; Payme/Click/Uzum keyingi fazada.
- **Sabab:** integratsiya vaqt oladi, naqd hudud uchun tabiiy.

### ADR-008 — Oshxona paneli Web (PWA) + WebView
- **Qaror:** native emas, Next.js PWA, ilova ichida WebView.
- **Sabab:** bitta kod, tez yangilanish, desktop+mobil.

## C qism — Ochiq savollar (sizdan tasdiq kerak)

> Bularni keyin birga hal qilamiz — reja shu javoblarga moslanadi.

1. **Platforma:** birinchi faqat **Android** APK'mi yoki iOS ham kerakmi? (Tavsiya: avval Android.)
2. **To'lov:** MVP'da naqd yetarlimi, yoki Payme/Click darhol kerakmi?
3. **Brending:** ilova nomi, logotip, rang sxemasi bormi? (UI dizayn uchun.)
4. **Soliq/yuridik:** firma ro'yxatdan o'tganmi (shartnoma, fiskal chek uchun)?
5. **Haqiqiy tariflar:** boshlang'ich taksi/dostavka narxi va komissiya % qancha? ([11-pricing-promo.md](11-pricing-promo.md) misol qiymatlari).
6. **Jamoa:** loyihada nechta dasturchi? (Bu fazalar tezligiga ta'sir qiladi.)
7. **Hosting hududi:** ma'lumot O'zbekistonda saqlanishi shartmi (qonun)?

## D qism — Bog'liq fayllar
- Qarorlar qo'llanishi → [02-tech-stack.md](02-tech-stack.md), [01-architecture.md](01-architecture.md)
- Yo'l xaritasi → [15-roadmap-mvp.md](15-roadmap-mvp.md)
- Maxfiylik/qonun → [10-auth-security.md](10-auth-security.md)
