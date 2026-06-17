# 14 — API Dizayni va Konvensiyalar

> Asosiy fayl: [README.md](README.md) · Bog'liq: [04-backend-services.md](04-backend-services.md)

## 1. Umumiy tamoyillar
- **REST + JSON** asosiy (so'rov-javob), **WebSocket** real-time (tracking) uchun.
- Versiyalash: `/api/v1/...`.
- Hammasi **API Gateway** orqali kiradi (auth, rate-limit, routing).
- Hujjat: **OpenAPI/Swagger** (NestJS avtomatik generatsiya).

## 2. So'rov / javob formati

### Muvaffaqiyatli javob
```json
{
  "success": true,
  "data": { ... },
  "meta": { "page": 1, "limit": 20, "total": 134 }
}
```

### Xato javob
```json
{
  "success": false,
  "error": {
    "code": "ORDER_NOT_FOUND",
    "message": "Buyurtma topilmadi",
    "details": {}
  }
}
```
- Xato `code` — barqaror (client shunga qarab ish ko'radi), `message` — lokalga mos (`Accept-Language`).

## 3. Standart header'lar
| Header | Maqsad |
|--------|--------|
| `Authorization: Bearer <jwt>` | Auth |
| `Accept-Language: uz \| uz-Cyrl \| ru` | Til |
| `Idempotency-Key: <uuid>` | Takrorlanmaslik (POST: order, payment) |
| `X-Request-Id` | Kuzatuv (tracing) |
| `X-Device-Id` | Qurilma (push, sessiya) |

## 4. Konvensiyalar
- Resurs nomlari **ko'plik**: `/orders`, `/restaurants`.
- Filter: query — `?status=PENDING&type=FOOD&from=2026-06-01&to=2026-06-17`.
- Sort: `?sort=-created_at` (`-` kamayish).
- Pagination: `?page=1&limit=20` (yoki cursor: `?cursor=...`).
- Search: `?q=...`.
- HTTP holatlar: 200, 201, 204, 400, 401, 403, 404, 409 (konflikt), 422 (validatsiya), 429 (rate-limit), 5xx.

## 5. Asosiy endpoint'lar (xulosa)

### Auth
```
POST /api/v1/auth/otp/request
POST /api/v1/auth/otp/verify
POST /api/v1/auth/refresh
GET  /api/v1/auth/me
POST /api/v1/auth/consent
```

### Mijoz — ovqat
```
GET  /api/v1/restaurants?lat&lng&q&category
GET  /api/v1/restaurants/:id/menu
POST /api/v1/orders            # type=FOOD, items, address, promo
GET  /api/v1/orders/:id
POST /api/v1/orders/:id/cancel
```

### Mijoz — taksi / dostavka
```
POST /api/v1/taxi/estimate     { from, to }
POST /api/v1/delivery/estimate
POST /api/v1/orders            # type=TAXI | DELIVERY
```

### Haydovchi
```
POST /api/v1/driver/online     { lat, lng }
POST /api/v1/driver/offline
POST /api/v1/driver/offers/:id/accept
POST /api/v1/driver/offers/:id/reject
POST /api/v1/driver/jobs/:id/arrived | picked | delivered | finished
GET  /api/v1/driver/earnings?period=day
```

### Oshxona
```
GET  /api/v1/restaurant/me/orders
POST /api/v1/restaurant/me/orders/:id/accept | reject | ready
CRUD /api/v1/restaurant/me/categories
CRUD /api/v1/restaurant/me/menu-items
```

### Admin
```
GET  /api/v1/admin/reports/summary?period=month
GET  /api/v1/admin/orders?filters&sort&page
CRUD /api/v1/admin/promo
GET/PUT /api/v1/admin/pricing/tariffs
GET/PUT /api/v1/admin/pricing/commissions
GET  /api/v1/admin/drivers, /restaurants, /contracts
GET  /api/v1/admin/reports/profit-loss?from&to
GET  /api/v1/admin/reports/export?format=xlsx
```

## 6. Real-time (WebSocket)

### Haydovchi → server (GPS)
```
WS /ws/driver
→ { "type": "location", "lat": 40.42, "lng": 70.61, "heading": 90, "ts": ... }
```

### Mijoz/Admin ← server (kuzatuv)
```
WS /ws/track/:orderId
← { "type": "driver_location", "lat":..., "lng":..., "eta": 240 }
← { "type": "status", "status": "PICKED_UP" }
```

### Haydovchi ← server (taklif)
```
WS /ws/driver
← { "type": "offer", "orderId":..., "service":"FOOD", "pickup":..., "amount":..., "expiresIn": 15 }
```

## 7. Idempotency va xavfsizlik
- `POST /orders`, `POST /payments` → `Idempotency-Key` majburiy (server kalitni keshlab, takror so'rovga bir xil javob).
- Narx, chegirma, komissiya **server hisoblaydi** — client raqamiga ishonilmaydi.
- Rate-limit: OTP, login, qidiruv.
> Batafsil → [10-auth-security.md](10-auth-security.md).

## 8. Eventlar (Event Bus — NATS subject nomlari)
```
order.created          taxi.trip.started     payment.confirmed
order.cancelled        delivery.driver.assigned   payment.failed
order.completed        delivery.picked       restaurant.accepted
location.update        delivery.delivered    promo.used
```
- `nomlash`: `<domen>.<hodisa>` (o'tgan zamon — bo'lib o'tgan fakt).
- Versiyalash: payload sxemasi ortga mos (backward compatible).

## 9. Servislararo (internal) API
- Order → Pricing: `POST /internal/pricing/quote` (gRPC yoki REST).
- Dispatch → Location: `POST /internal/location/nearby`.
- Internal endpoint'lar tashqaridan yopiq (faqat ichki tarmoq / mTLS).

## 10. Bog'liq fayllar
- Servislar tafsiloti → [04-backend-services.md](04-backend-services.md)
- Auth/xavfsizlik → [10-auth-security.md](10-auth-security.md)
- Real-time/tracking → [09-maps-navigation.md](09-maps-navigation.md)
