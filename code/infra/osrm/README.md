# OSRM — Marshrut serveri

Bepul marshrut/ETA tizimi (OpenStreetMap asosida). Batafsil: [`../../../plan/09-maps-navigation.md`](../../../plan/09-maps-navigation.md).

## Tayyorlash
```bash
bash infra/osrm/build-osrm.sh
```
Bu O'zbekiston OSM ma'lumotini yuklab, marshrut grafini tayyorlaydi (`data/` papkada).

## Ishga tushirish
```bash
docker run --rm -t -p 5000:5000 -v "$PWD/infra/osrm/data:/data" \
  osrm/osrm-backend osrm-routed --algorithm mld /data/uzbekistan-latest.osrm
```

## API namuna
```
GET http://localhost:5000/route/v1/driving/{lon1},{lat1};{lon2},{lat2}
GET http://localhost:5000/table/v1/driving/...   # masofa matritsasi (dispatch)
```

> `data/` papka `.gitignore`'da (fayllar katta, generatsiya qilinadi).
> Faza 3 (haydovchi/dostavka) da Routing servisi shu serverdan foydalanadi.

---

## Production joylashtirish (Fly.io)

OSRM — xotira-rezident C++ jarayon (1.1GB tayyorlangan xarita ma'lumoti bilan), stateless/serverless muhitda (Cloudflare Workers, Vercel va h.k.) ishlay OLMAYDI. U doimiy, real hostda ishlashi shart. Shuning uchun production'da HAM Docker orqali qoladi — faqat lokal Docker Desktop'dan chiqib, [Fly.io](https://fly.io) Machines'ga ko'chadi (Docker image'larni to'g'ridan-to'g'ri, doimiy volume bilan ishga tushiradigan xizmat, bepul tarifida ham kichik VM'lar mavjud).

### 1-qadam: Fly CLI o'rnatish va hisob
```powershell
# PowerShell (Windows)
iwr https://fly.io/install.ps1 -useb | iex
fly auth signup   # yoki fly auth login, agar hisob bor bo'lsa
```

### 2-qadam: Loyihani yaratish
`infra/osrm/` papkasida (bu yerda `data/uzbekistan-latest.osrm*` fayllari bor):
```bash
cd infra/osrm
fly launch --name beshariq-osrm --no-deploy
```
`fly launch` `fly.toml` so'raydi — Dockerfile yo'qligi uchun tayyor `osrm/osrm-backend` image'ini ishlatish kerak, shuning uchun avtomatik generatsiyani rad etib, quyidagi minimal `fly.toml`ni qo'lda yozing:
```toml
app = "beshariq-osrm"
primary_region = "fra"   # Yevropa — Fly.io'da Markaziy Osiyoga eng yaqin region

[build]
  image = "osrm/osrm-backend"

[processes]
  app = "osrm-routed --algorithm mld /data/uzbekistan-latest.osrm"

[[mounts]]
  source = "osrm_data"
  destination = "/data"

[[services]]
  internal_port = 5000
  protocol = "tcp"
  [[services.ports]]
    port = 80
    handlers = ["http"]
```

### 3-qadam: Doimiy volume yaratish va ma'lumotni yuklash
```bash
fly volumes create osrm_data --region fra --size 3   # 3GB (1.1GB dataset + zaxira joy)
fly deploy
# Volume bo'sh boshlanadi — data/ papkadagi *.osrm* fayllarni Machine'ga nusxalash kerak:
fly ssh sftp shell
> put data/uzbekistan-latest.osrm* /data/
```

### 4-qadam: `services/order`ning `OSRM_URL`ini yangilash
Production `.env`da (`code/services/order/.env`):
```
OSRM_URL=https://beshariq-osrm.fly.dev
```
(Lokal dev `.env`da `OSRM_URL=http://localhost:5000` o'zgarishsiz qoladi — ikkita muhit parallel yashaydi, xuddi Postgres/Neon naqshida.)

### Tekshirish
```bash
curl https://beshariq-osrm.fly.dev/nearest/v1/driving/70.6,40.4
```
200 va marshrut JSON'i qaytishi kerak — lokaldagi bilan bir xil javob shakli (kod tomonida hech narsa o'zgarmaydi, faqat URL).
