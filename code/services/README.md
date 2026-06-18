# Services — Backend microservislar

Har servis mustaqil: o'z DB'si, o'z API'si. Aloqa — REST/gRPC (sinxron) yoki NATS event (asinxron).
Batafsil: [`../../plan/04-backend-services.md`](../../plan/04-backend-services.md).

## Holat

| Servis | Til | Holat | Faza |
|--------|-----|-------|------|
| **gateway** | NestJS | ✅ skelet + routing | 0 |
| **auth** | NestJS | ✅ OTP+JWT (in-memory) | 1 |
| user | NestJS | ⬜ rejada | 1 |
| **restaurant** | NestJS | ✅ katalog+menyu (in-memory) | 2 |
| pricing | NestJS | ⬜ rejada | 2 |
| promo | NestJS | ⬜ rejada | 2 |
| **order** | NestJS | ✅ buyurtma (in-memory, narx katalogdan) | 2 |
| media | NestJS | ⬜ rejada | 2 |
| notification | NestJS | ⬜ rejada | 2 |
| location | **Go** | ⬜ rejada | 3 |
| routing | Go/NestJS | ⬜ rejada | 3 |
| delivery | NestJS | ⬜ rejada | 3 |
| taxi | NestJS | ⬜ rejada | 4 |
| payment | NestJS | ⬜ rejada | 7 |
| reporting | NestJS | ⬜ rejada | 6 |

> Har servis o'z fazasida yaratiladi (yo'l xaritasi: [`../../plan/15-roadmap-mvp.md`](../../plan/15-roadmap-mvp.md)).
> Yangi NestJS servis qo'shish: `gateway`ni namuna sifatida ko'chiring (package.json nomini `@beshariq/<servis>` qiling).
