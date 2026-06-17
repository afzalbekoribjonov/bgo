# 03 — Ma'lumot bazalari va model

> Asosiy fayl: [README.md](README.md) · Bog'liq: [04-backend-services.md](04-backend-services.md)

## 1. Strategiya: Polyglot Persistence + Database-per-Service

Har bir servis o'z ma'lumotiga egalik qiladi. Boshqa servis unga **faqat API yoki event** orqali murojaat qiladi — to'g'ridan-to'g'ri DB'ga emas. Bu bog'liqlikni kamaytiradi va kelajakda ajratishni osonlashtiradi.

### Fizik tashkil etish (bosqichma-bosqich)
- **MVP:** bitta PostgreSQL serveri, ichida bir nechta **logik database** (`auth_db`, `user_db`, `order_db`, `taxi_db`, `restaurant_db`, ...). Arzon va boshqarish oson.
- **O'sish:** yuk ko'p bo'lgan DB'larni (masalan `taxi_db`, `restaurant_db`) alohida fizik serverga ko'chiramiz — kod o'zgarmaydi, faqat connection string.

### Texnologiyalar bo'yicha taqsimot

| Maqsad | Texnologiya | Sabab |
|--------|-------------|-------|
| Tranzaksion (buyurtma, to'lov, profil) | **PostgreSQL** | ACID, ishonchli, bepul |
| Geo (POI, hudud, masofa) | **PostGIS** (PG kengaytmasi) | SQL ichida geo so'rov |
| Real-time joylashuv | **Redis Geo** | `GEOADD`/`GEOSEARCH`, tezkor |
| Kesh, sessiya, navbat | **Redis** | tez, TTL, pub/sub |
| Marshrut grafi | **OSRM** (fayl-asosida) | DB emas, oldindan tayyorlangan graf |
| Hisobot (analitika) | **PostgreSQL read-replica** (keyin ClickHouse) | og'ir SELECT'lar asosiy DB'ni bosmaydi |

> **Eslatma:** siz so'ragan "taksi alohida, oshxona alohida, navigator alohida tezkor baza" — ana shu `taxi_db`, `restaurant_db` va PostGIS+Redis+OSRM kombinatsiyasi orqali amalga oshadi.

## 2. Servis bo'yicha bazalar

```
auth_db        → users_auth, otp_codes, sessions, roles, permissions
user_db        → profiles, addresses, favorites, devices
order_db       → orders, order_items, order_status_history
taxi_db        → trips, trip_points, trip_status_history
delivery_db    → deliveries, parcels, dispatch_attempts
restaurant_db  → restaurants, categories, menu_items, options, work_hours
pricing_db     → tariffs, commission_rules, surge_rules
promo_db       → promo_codes, campaigns, promo_usages
payment_db     → payments, transactions, payouts, wallets
notif_db       → notifications, templates, delivery_log
report_db      → (read-replica / materialized views)
geo            → (PostGIS) pois, zones, road_cache
redis          → driver_locations, sessions, cache, queues
```

## 3. Asosiy entitilar (soddalashtirilgan model)

### Auth / User
```
users_auth(id, phone, password_hash?, status, created_at)
roles(id, name)                       -- customer, driver, restaurant, admin...
user_roles(user_id, role_id)
otp_codes(id, phone, code_hash, expires_at, attempts)
sessions(id, user_id, refresh_token_hash, device_id, expires_at)

profiles(id, user_id, full_name, avatar_url, locale, gender, birth_date)
addresses(id, user_id, label, lat, lng, address_text, is_default)
devices(id, user_id, fcm_token, platform, last_seen)
```

### Order (umumiy buyurtma)
```
orders(
  id, public_no, customer_id, type,          -- type: FOOD | TAXI | DELIVERY
  status, total_amount, discount_amount, final_amount,
  payment_type, payment_status, promo_id?,
  created_at, updated_at
)
order_status_history(id, order_id, status, actor, note, created_at)
```
> `orders` — barcha 3 xizmat uchun umumiy "soyabon". Detallar tegishli servis jadvalida (`trips`, `deliveries`, `order_items`).

### Ovqat (Restaurant + Order Items)
```
restaurants(id, owner_user_id, name, lat, lng, address, phone, status,
            commission_percent, is_open, rating, logo_url)
work_hours(id, restaurant_id, weekday, open_time, close_time)
categories(id, restaurant_id, name_i18n, sort_order)
menu_items(id, restaurant_id, category_id, name_i18n, description_i18n,
           price, image_url, is_available, options_json)
order_items(id, order_id, menu_item_id, name_snapshot, price_snapshot, qty, options_json)
```
> `name_i18n` — JSONB: `{"uz":"Osh","uz_cyrl":"Ош","ru":"Плов"}`. Til → [13-localization.md](13-localization.md).
> `*_snapshot` — buyurtma paytidagi narx/nom saqlanadi (keyin o'zgarsa ham hisobot to'g'ri qoladi).

### Taksi
```
trips(id, order_id, driver_id?, from_lat, from_lng, to_lat, to_lng,
      distance_m, duration_s, base_fare, total_fare, status,
      requested_at, accepted_at, started_at, finished_at)
trip_points(id, trip_id, lat, lng, recorded_at)   -- yo'l izi (track)
```

### Dostavka
```
deliveries(id, order_id, driver_id?, pickup_lat, pickup_lng,
           dropoff_lat, dropoff_lng, parcel_desc, weight_kg?,
           distance_m, fee, status, ...)
dispatch_attempts(id, order_id, driver_id, offered_at, response, responded_at)
```

### Narx / Promo
```
tariffs(id, service_type, zone_id?, base_fare, per_km, per_min,
        min_fare, waiting_per_min, active_from, active_to)
commission_rules(id, target, percent, fixed, active)   -- target: FOOD|TAXI|DELIVERY
promo_codes(id, code, type, value, max_uses, used_count,
            min_order, valid_from, valid_to, service_scope, active)
promo_usages(id, promo_id, user_id, order_id, applied_amount, used_at)
```
> Batafsil mantiq → [11-pricing-promo.md](11-pricing-promo.md).

### To'lov
```
payments(id, order_id, provider, amount, status, external_id, created_at)
transactions(id, wallet_id?, type, amount, balance_after, ref_order_id)
payouts(id, payee_type, payee_id, amount, period, status)  -- haydovchi/oshxonaga to'lov
wallets(id, owner_type, owner_id, balance)
```

### Geo (PostGIS)
```
pois(id, name, category, geom GEOGRAPHY(Point))           -- muhim joylar
zones(id, name, geom GEOGRAPHY(Polygon))                  -- tarif zonalari (Beshariq mahallalar)
```

### Redis (real-time)
```
driver_locations         -> GEO set: member=driver_id, (lng,lat)
driver_status:<id>       -> ONLINE|BUSY|OFFLINE + current_role
order_tracking:<order>   -> pub/sub kanal (live update)
session:<token>          -> user_id, roles (TTL)
queue:dispatch           -> BullMQ navbat
```

## 4. Geo-qidiruv namunalari

**Yaqin bo'sh haydovchi (Redis):**
```
GEOSEARCH driver_locations FROMLONLAT 70.61 40.42 BYRADIUS 3 km ASC COUNT 10
```

**Berilgan nuqta qaysi zonada (PostGIS):**
```sql
SELECT id, name FROM zones
WHERE ST_Contains(geom::geometry, ST_SetSRID(ST_MakePoint(:lng,:lat),4326));
```

## 5. Migratsiya va seed

- Migratsiya: **Prisma Migrate** (yoki har servisda alohida).
- Seed: test oshxonalar, kategoriyalar, tarif, Beshariq zonalari (mahallalar geometriyasi).
- Har servis o'z migratsiyasini boshqaradi (mustaqillik).

## 6. Zaxira (backup) va saqlash muddati

- Kunlik avtomatik DB backup (Supabase/Oracle).
- `trip_points` (yo'l izlari) — 30–90 kundan keyin arxivga/o'chirish (joy tejash).
- Shaxsiy ma'lumot — qonun talabiga muvofiq saqlash. Maxfiylik → [10-auth-security.md](10-auth-security.md).

## 7. Bog'liq fayllar
- Backend servislari → [04-backend-services.md](04-backend-services.md)
- Narx/promo modeli → [11-pricing-promo.md](11-pricing-promo.md)
- Xarita/geo → [09-maps-navigation.md](09-maps-navigation.md)
