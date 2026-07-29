-- AlterEnum
ALTER TYPE "TaxiStatus" ADD VALUE 'ARRIVED';

-- AlterTable
ALTER TABLE "tariffs" ADD COLUMN     "taxiPickupSurchargePerKm" INTEGER NOT NULL DEFAULT 500,
ADD COLUMN     "taxiPickupSurchargeThresholdKm" DOUBLE PRECISION NOT NULL DEFAULT 1.6,
ADD COLUMN     "taxiWaitFreeMin" INTEGER NOT NULL DEFAULT 2;

-- AlterTable
ALTER TABLE "taxi_trips" ADD COLUMN     "pickupDistanceKm" DOUBLE PRECISION NOT NULL DEFAULT 0,
ADD COLUMN     "pickupSurcharge" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "waitStartedAt" TIMESTAMP(3);
