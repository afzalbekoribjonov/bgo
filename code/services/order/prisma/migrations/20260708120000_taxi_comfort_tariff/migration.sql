-- Comfort tarifi: tarif ustamalari + safar tarif klassi
ALTER TABLE "tariffs" ADD COLUMN "taxiComfortPerKmExtra" INTEGER NOT NULL DEFAULT 500;
ALTER TABLE "tariffs" ADD COLUMN "taxiComfortBaseExtra" INTEGER NOT NULL DEFAULT 500;
ALTER TABLE "taxi_trips" ADD COLUMN "tariffClass" TEXT NOT NULL DEFAULT 'start';
