# Beshariq Super-App

Beshariq tumani (Farg'ona viloyati) uchun yagona mobil super-ilova: **Taksi + Dostavka + Ovqat yetkazib berish**.

Bu repozitoriya ikki qismga ajratilgan — reja va kod aralashmasligi uchun:

```
beshariq_food/
├── plan/     📋 Loyiha rejasi (texnik hujjatlar, arxitektura, yo'l xaritasi)
└── code/     💻 Kod (monorepo: apps, services, packages, infra)
```

## Tez havolalar

- **Reja (bosh indeks):** [`plan/README.md`](plan/README.md)
- **Kod (boshlash qo'llanmasi):** [`code/README.md`](code/README.md)
- **Yo'l xaritasi:** [`plan/15-roadmap-mvp.md`](plan/15-roadmap-mvp.md)

## Holat

**Faza 0 — Monorepo skeleti** bajarildi (API Gateway ishlaydi, Flutter ilovalar tayyor, 3 til).
Keyingi: **Faza 1 — Auth + Kirish**.

## Boshlash

```bash
cd code
pnpm install
pnpm gateway:dev   # http://localhost:3000/api/v1/health
```

Batafsil: [`code/README.md`](code/README.md).
