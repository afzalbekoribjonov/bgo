-- AlterTable
ALTER TABLE "driver_profiles" ADD COLUMN     "homeLat" DOUBLE PRECISION,
ADD COLUMN     "homeLng" DOUBLE PRECISION,
ADD COLUMN     "homeAddress" TEXT,
ADD COLUMN     "isHomeModeActive" BOOLEAN NOT NULL DEFAULT false;
