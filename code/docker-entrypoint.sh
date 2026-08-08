#!/bin/sh
set -e

# Firebase xizmat-hisobi JSON (faqat auth) — image'ga yozilmaydi/commit
# qilinmaydi. FIREBASE_SERVICE_ACCOUNT_B64 `fly secrets set` orqali
# beriladi (JSON faylning base64'i); ishga tushishdan oldin
# FCM_SERVICE_ACCOUNT ko'rsatgan yo'lga dekodlanadi. Boshqa xizmatlarda
# bu o'zgaruvchi shunchaki o'rnatilmagan — no-op.
if [ -n "$FIREBASE_SERVICE_ACCOUNT_B64" ]; then
  echo "$FIREBASE_SERVICE_ACCOUNT_B64" | base64 -d > ./firebase-service-account.json
fi

# Kutilayotgan migratsiyalarni qo'llash — faqat Prisma'ga ega xizmatlarda
# (gateway'da baza yo'q).
if [ -f ./prisma/schema.prisma ]; then
  ./node_modules/.bin/prisma migrate deploy
fi

exec node dist/main.js
