# To'lov — zahira (reserve) kod ⚠️

Bu papka **kelajak uchun yashirin zahira** — hozir **ishlatilmaydi** va **foydalanuvchiga ko'rinmaydi**.

## Hozirgi holat
- To'lov **faqat NAQD (CASH)**. Buyurtmada `paymentType` faqat `CASH` qabul qilinadi (`create-order.dto.ts`).
- Bu yerdagi fayllar **hech qaysi NestJS modulga ulanmagan** — DI grafiga kirmaydi, endpoint ochmaydi, faqat kompilyatsiya bo'ladi (tip xavfsizligi saqlanadi).

## Nima bor
- `payment.types.ts` — `PaymentProvider` (charge + webhook) va `PayoutProvider` (yechib olish) interfeyslari.
- `providers.ts` — `Click`, `Payme`, `Paynet` stublari (hammasi "not implemented").
- `payment.service.ts` — provayder registri, `PAYMENTS_ONLINE_ENABLED` bayrog'i (default `false`).

## Onlayn to'lovni yoqish (kelajakda)
1. Provayder Merchant API'larini implementatsiya qilish:
   - Click — https://docs.click.uz
   - Payme — https://developer.help.paycom.uz
   - Paynet — https://paynet.uz
2. `create-order.dto.ts` da `paymentType` ga `CLICK|PAYME|PAYNET` qo'shish.
3. OrdersModule'ga `PaymentService` + webhook controller (`POST /payments/webhook/:provider`) qo'shish.
4. `PAYMENTS_ONLINE_ENABLED=true` + provayder kalitlari (.env).
5. **Yechib olish (payout):** haydovchi/oshxona balansidan Click/Payme/Paynet orqali pul o'tkazish (`PayoutProvider`).
6. Yetuk bo'lganda — alohida **Payment servisiga** ko'chirish (plan/04-backend-services.md).

> Eslatma: O'zbekistonda onlayn kassa/fiskal chek talablari bo'lishi mumkin (plan/11-pricing-promo.md, soliq bo'limi).
