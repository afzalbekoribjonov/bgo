-- CreateEnum
CREATE TYPE "TaxiStatus" AS ENUM ('PENDING', 'ACCEPTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');

-- AlterTable
ALTER TABLE "tariffs" ADD COLUMN     "taxiBaseFare" INTEGER NOT NULL DEFAULT 5000,
ADD COLUMN     "taxiCommissionPercent" INTEGER NOT NULL DEFAULT 15,
ADD COLUMN     "taxiMinFare" INTEGER NOT NULL DEFAULT 8000,
ADD COLUMN     "taxiPerKm" INTEGER NOT NULL DEFAULT 2000;

-- CreateTable
CREATE TABLE "taxi_trips" (
    "id" TEXT NOT NULL,
    "publicNo" SERIAL NOT NULL,
    "customerId" TEXT NOT NULL,
    "driverId" TEXT,
    "pickup" JSONB NOT NULL,
    "destination" JSONB NOT NULL,
    "distanceKm" DOUBLE PRECISION NOT NULL,
    "fare" INTEGER NOT NULL,
    "commission" INTEGER NOT NULL DEFAULT 0,
    "driverEarning" INTEGER NOT NULL DEFAULT 0,
    "status" "TaxiStatus" NOT NULL DEFAULT 'PENDING',
    "paymentType" "PaymentType" NOT NULL DEFAULT 'CASH',
    "statusHistory" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "taxi_trips_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "taxi_trips_publicNo_key" ON "taxi_trips"("publicNo");

-- CreateIndex
CREATE INDEX "taxi_trips_customerId_idx" ON "taxi_trips"("customerId");

-- CreateIndex
CREATE INDEX "taxi_trips_driverId_idx" ON "taxi_trips"("driverId");

-- CreateIndex
CREATE INDEX "taxi_trips_status_idx" ON "taxi_trips"("status");
