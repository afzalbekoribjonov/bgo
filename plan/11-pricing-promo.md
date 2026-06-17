# 11 — Narx, Tariflar, Ulush, Promokod, Foyda/Zarar

> Asosiy fayl: [README.md](README.md) · Bog'liq: [04-backend-services.md](04-backend-services.md) (Pricing, Promo), [08-admin-workspace.md](08-admin-workspace.md)

Bu fayl loyihaning **moliyaviy yuragi**. Barcha narx server tomonda (Pricing servisi) hisoblanadi.

## 1. Taksi narxi
```
fare = base_fare
     + (distance_km × per_km)
     + (duration_min × per_min)
     + (waiting_min × waiting_per_min)
fare = max(fare, min_fare)          # minimal yonish narxi (siz so'ragan)
fare = fare × surge_multiplier      # talab yuqori bo'lsa (ixtiyoriy)
fare = apply_zone_rules(fare)       # zona bo'yicha (Beshariq mahallalar)
```
Admin sozlaydi: `base_fare`, `per_km`, `per_min`, `min_fare`, `waiting_per_min`, zona narxlari.

## 2. Dostavka narxi
```
fee = base_delivery
    + (distance_km × per_km_delivery)
    + size/weight qo'shimcha (ixtiyoriy)
fee = max(fee, min_delivery_fee)
```

## 3. Ovqat yetkazish narxi va komissiya (ulush)
Mijoz to'laydi:
```
total = taomlar_summasi + delivery_fee − chegirma(promo)
```
Bizning daromad:
```
bizning_foyda = oshxona_komissiyasi + delivery_marjasi
oshxona_komissiyasi = taomlar_summasi × commission_percent   # masalan 12%
delivery_marjasi   = delivery_fee − haydovchiga_to'lov
```
Haydovchiga to'lov:
```
haydovchi_ulushi = delivery_fee × driver_share_percent (yoki fiks)
```

> **Siz so'ragan barcha sozlamalar** shu yerda admin tomonidan boshqariladi:
> - taksi **minimal yonish narxi** → `min_fare`
> - **kuryer foydasi** → `driver_share_percent` / fiks
> - **ovqatdan olinadigan ulush %** → `commission_percent`

## 4. Sozlanadigan parametrlar (admin panel)

| Parametr | Tavsif | Misol |
|----------|--------|-------|
| `base_fare` | Taksi boshlang'ich | 5 000 so'm |
| `per_km` | Har km | 1 500 so'm |
| `per_min` | Har daqiqa | 200 so'm |
| `min_fare` | Minimal yonish narxi | 8 000 so'm |
| `waiting_per_min` | Kutish | 300 so'm |
| `base_delivery` | Dostavka boshlang'ich | 5 000 so'm |
| `per_km_delivery` | Dostavka har km | 1 200 so'm |
| `commission_percent` | Oshxona ulushi | 12% |
| `driver_share_percent` | Kuryer foydasi | 80% |
| `surge_multiplier` | Talab koeffitsienti | 1.0–2.0 |

> Bu raqamlar **misol** — siz haqiqiy qiymatni admin paneldan kiritasiz. Har o'zgarish tarixi saqlanadi.

## 5. Promokodlar (siz alohida so'ragan)

### Turlari
- **Foiz chegirma** — masalan −20% (max chegirma limiti bilan).
- **Fiks chegirma** — masalan −10 000 so'm.
- **Bepul yetkazish** — `delivery_fee = 0`.

### Qoidalar
```
promo_code(
  code, type, value,
  min_order,            # minimal buyurtma summasi
  max_discount,         # maksimal chegirma (% uchun)
  max_uses,             # umumiy limit
  per_user_limit,       # bir foydalanuvchi necha marta
  valid_from, valid_to, # amal muddati
  service_scope,        # FOOD | TAXI | DELIVERY | ALL
  active
)
```
### Tekshirish (Promo servisi)
1. Kod mavjud va faol?
2. Muddat ichida?
3. Limit (umumiy + foydalanuvchi) oshmaganmi?
4. `min_order` shartiga mosmi?
5. Xizmat ko'lamiga mosmi?
→ Chegirma summasi qaytariladi, buyurtma yopilganda `promo_usages` yoziladi.

### Aksiya (campaign)
- Banner + promokod + davr + maqsadli segment.
- Statistika: ishlatilish, jami chegirma, yangi mijoz keltirgani.

## 6. Foyda / Zarar hisoblagich (siz alohida so'ragan)

### Hisob mantiqi
```
DAROMAD (davr bo'yicha)
  + ovqat komissiyasi
  + dostavka marjasi
  + taksi komissiyasi/marjasi
XARAJAT
  − promokod/aksiya chegirmalari
  − haydovchi payout (foyda bersak)
  − bonus/jarima korrektirovkasi
  − operatsion (SMS, hosting, to'lov provayder %)
= SOF FOYDA / ZARAR
```
- Admin panelda: davr tanlash, xizmat bo'yicha breakdown, grafik trend.
- Har buyurtma uchun ham mikro-foyda saqlanadi (Reporting servisi) → tez agregatsiya.

## 7. Hisob-kitob (settlement / payout)
- **Oshxona:** davr (hafta/oy) bo'yicha tushum − komissiya = oshxonaga to'lov.
- **Haydovchi:** bajarilgan buyurtmalardan ulush − (naqd olgan bo'lsa, naqd korrektirovka) = balans → payout.
- Naqd to'lovda: haydovchi naqd oladi → bizning komissiya uning balansidan ushlanadi.
- Onlayn to'lovda: pul bizga keladi → haydovchi/oshxonaga payout qilamiz.

## 8. Soliq / qonun (eslatma)
- Cheklar (fiskal) — O'zbekistonda onlayn kassa/soliq talablari bo'lishi mumkin → keyingi fazada integratsiya (soliq qo'mitasi/OFD).
- Hozircha: ichki chek + hisobot, qonuniy talab aniqlangach moslaymiz.

## 9. Bog'liq fayllar
- Pricing/Promo servislari → [04-backend-services.md](04-backend-services.md)
- Admin moliya bo'limi → [08-admin-workspace.md](08-admin-workspace.md)
- Ma'lumot modeli → [03-databases.md](03-databases.md)
- To'lov xavfsizligi → [10-auth-security.md](10-auth-security.md)
