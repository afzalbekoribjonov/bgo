-- Sotuvchi joylashuvi: manzil (matn) + lat/lng — "eng yaqin do'kon birinchi"
-- saralash uchun. Uchalasi ham ixtiyoriy — eski sotuvchilar buzilmaydi.
ALTER TABLE "sellers" ADD COLUMN "address" TEXT;
ALTER TABLE "sellers" ADD COLUMN "lat" DOUBLE PRECISION;
ALTER TABLE "sellers" ADD COLUMN "lng" DOUBLE PRECISION;
