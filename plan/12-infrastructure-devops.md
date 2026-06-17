# 12 — Infratuzilma va DevOps

> Asosiy fayl: [README.md](README.md) · Maqsad: **bepul trial** bilan boshlash, keyin arzon masshtablash.

## 1. Tamoyil: bepul boshla, kerak bo'lganda to'la
Boshida hamma narsa bepul/trial resurslarda. Daromad kelgach arzon to'lovli planga o'tamiz. Kod bir xil qoladi (Docker), faqat hosting o'zgaradi.

## 2. Bepul resurslar (tavsiya)

| Maqsad | Xizmat | Bepul nimasi |
|--------|--------|--------------|
| Server (backend, OSRM) | **Oracle Cloud Always Free** | 4 ARM core + 24GB RAM **doimiy bepul** (juda saxiy) |
| Postgres (tez start) | **Supabase** / **Neon** | Bepul Postgres + auth + storage |
| Object storage (media) | **Cloudflare R2** | 10GB + bepul egress |
| Push | **Firebase (FCM)** | Bepul |
| SMS (OTP) | **Eskiz.uz** | Test/trial paket |
| CDN / himoya | **Cloudflare** | Bepul CDN + DDoS + SSL |
| CI/CD | **GitHub Actions** | Bepul daqiqalar |
| Domен | (arzon `.uz`/`.com`) | — |
| Monitoring | **Grafana Cloud / Uptime Kuma** | Bepul tier / self-host |
| Xato kuzatuv | **Sentry** | Bepul tier |

> **Asosiy tavsiya:** og'ir narsalarni (OSRM, Postgres, Redis, backend) **Oracle Always Free** ARM serverida Docker bilan o'zimiz yuritamiz — doimiy bepul va kuchli. Tez start uchun DB'ni Supabase'da boshlash ham mumkin.

## 3. Konteynerlash (Docker)
- Har servis o'z `Dockerfile`'i.
- **dev:** `docker-compose.yml` — bitta buyruq bilan butun tizim (Postgres, Redis, NATS, OSRM, servislar).
- **prod (MVP):** Docker Compose Oracle serverida (oddiy, arzon).
- **o'sish:** Kubernetes (k3s — yengil) yoki managed (keyin).

```
infra/
├── docker/
│   ├── docker-compose.yml          # dev: hamma narsa
│   ├── docker-compose.prod.yml
│   └── <service>/Dockerfile
├── osrm/
│   └── build-osrm.sh               # UZ extract → OSRM tayyorlash
└── db/
    ├── migrations/
    └── seed/
```

## 4. Muhitlar (environments)
| Muhit | Maqsad |
|-------|--------|
| **local** | Dasturchi kompyuteri (compose) |
| **staging** | Test/sinov (real'ga yaqin) |
| **production** | Jonli (pilot Beshariq) |

- Konfiguratsiya: `.env` (sirlardan tashqari) + secret manager.
- Sirlar kodga **hech qachon** yozilmaydi (`.gitignore`).

## 5. CI/CD (GitHub Actions)
```
PR ochilganda:  lint + type-check + test (backend, web)
                flutter analyze + test
main'ga merge:  build Docker image → registry
                deploy staging (avtomatik)
tag/release:    deploy production (qo'lda tasdiq bilan)
```
- Flutter APK: `flutter build apk` → artifact / (keyin Play Store / ichki tarqatish).

## 6. OSRM tayyorlash (bir martalik + yangilash)
```bash
# Geofabrik'dan UZ ma'lumoti
wget https://download.geofabrik.de/asia/uzbekistan-latest.osm.pbf
# (ixtiyoriy) faqat Farg'ona/Beshariq bbox — osmium extract
osrm-extract -p car.lua uzbekistan-latest.osm.pbf
osrm-partition uzbekistan-latest.osrm
osrm-customize uzbekistan-latest.osrm
osrm-routed --algorithm mld uzbekistan-latest.osrm
```
- Oyiga bir marta OSM ma'lumotini yangilash (cron). → [09-maps-navigation.md](09-maps-navigation.md).

## 7. Backup va ishonchlilik
- Kunlik avtomatik DB backup (saqlash R2'da).
- Redis: muhim emas (kesh) — lekin refresh token uchun persistence yoqilgan.
- Sog'liq tekshiruvi (health check) har servisda → monitoring.
- Avtomatik qayta ishga tushirish (Docker restart policy).

## 8. Monitoring va loglar
- Strukturali JSON log (har servis).
- Markazlashtirilgan: Grafana Loki / yoki oddiy fayl + rotation (MVP).
- Metrika: so'rov soni, kechikish, xato % (Prometheus/Grafana).
- Alert: server o'lsa, xato % oshsa → Telegram/email.
- Xato: Sentry (mobil + backend).

## 9. Domen va tarmoq
- Cloudflare oldida (DNS, SSL, CDN, DDoS himoya).
- API: `api.beshariq-app.uz`, admin: `admin.beshariq-app.uz`, oshxona: `kitchen.beshariq-app.uz` (misol).
- WebSocket uchun WSS.

## 10. Xarajat bashorati (taxminiy)
| Bosqich | Oylik xarajat |
|---------|---------------|
| MVP/pilot | ~0 (bepul tier) + domen (~yiliga $10) + SMS (foydalanishga qarab) |
| O'sish | $20–50 (server upgrade, SMS, storage) |

## 11. Bog'liq fayllar
- Tech stack → [02-tech-stack.md](02-tech-stack.md)
- Xarita/OSRM → [09-maps-navigation.md](09-maps-navigation.md)
- Yo'l xaritasi → [15-roadmap-mvp.md](15-roadmap-mvp.md)
