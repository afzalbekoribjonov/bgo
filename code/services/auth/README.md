# Auth servisi

Telefon + OTP autentifikatsiya, JWT (access/refresh), maxfiylik roziligi.
Reja: [`../../../plan/10-auth-security.md`](../../../plan/10-auth-security.md)

## Ishga tushirish (dev)
```bash
cd code/services/auth
cp .env.example .env      # birinchi marta
# repo ildizidan:  pnpm auth:dev
pnpm start:dev            # http://localhost:4001/api/v1
```
> **Muhim:** servisni o'z papkasidan ishga tushiring (`.env` cwd'ga nisbatan yuklanadi).

## Endpointlar (barchasi `/api/v1` ostida)

| Metod | Yo'l | Tavsif | Auth |
|-------|------|--------|------|
| GET | `/health` | Sog'liq tekshiruvi | — |
| POST | `/auth/otp/request` | OTP so'rash `{ phone }` | — |
| POST | `/auth/otp/verify` | Tasdiqlash `{ phone, code }` → tokenlar | — |
| POST | `/auth/refresh` | `{ refreshToken }` → yangi tokenlar | — |
| GET | `/auth/me` | Joriy foydalanuvchi | Bearer |
| POST | `/auth/consent` | Rozilik `{ privacy, version }` | Bearer |

- Telefon formati: `+998XXXXXXXXX`.
- **Dev rejim** (`SMS_DEV_MODE=true`): OTP haqiqiy SMS o'rniga logga chiqadi va `otp/request` javobida `devCode` sifatida qaytadi.

## Hozirgi cheklovlar (TODO)
- **Saqlash:** PostgreSQL (Prisma) — foydalanuvchi/haydovchi profillari va boshqa modellar. OTP kodlari xotirada (TTL bilan) saqlanadi.
- **SMS:** Eskiz.uz hali ulanmagan; hozircha Telegram bot orqali yoki dev rejimda (`SMS_DEV_MODE=true`) logga/javobga chiqadi.
- **Refresh token:** JWT verify (rotation/revocation yo'q).
