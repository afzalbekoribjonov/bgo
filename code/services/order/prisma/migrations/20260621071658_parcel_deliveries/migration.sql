-- CreateEnum
CREATE TYPE "ParcelStatus" AS ENUM ('PENDING', 'ACCEPTED', 'PICKED_UP', 'DELIVERED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "ParcelSize" AS ENUM ('SMALL', 'MEDIUM', 'LARGE');

-- AlterTable
ALTER TABLE "tariffs" ADD COLUMN     "parcelBaseFare" INTEGER NOT NULL DEFAULT 4000,
ADD COLUMN     "parcelCommissionPercent" INTEGER NOT NULL DEFAULT 15,
ADD COLUMN     "parcelMinFare" INTEGER NOT NULL DEFAULT 6000,
ADD COLUMN     "parcelPerKm" INTEGER NOT NULL DEFAULT 1500;

-- CreateTable
CREATE TABLE "parcel_deliveries" (
    "id" TEXT NOT NULL,
    "publicNo" SERIAL NOT NULL,
    "customerId" TEXT NOT NULL,
    "driverId" TEXT,
    "pickup" JSONB NOT NULL,
    "destination" JSONB NOT NULL,
    "distanceKm" DOUBLE PRECISION NOT NULL,
    "size" "ParcelSize" NOT NULL DEFAULT 'SMALL',
    "recipientName" TEXT NOT NULL,
    "recipientPhone" TEXT NOT NULL,
    "note" TEXT,
    "fare" INTEGER NOT NULL,
    "commission" INTEGER NOT NULL DEFAULT 0,
    "driverEarning" INTEGER NOT NULL DEFAULT 0,
    "status" "ParcelStatus" NOT NULL DEFAULT 'PENDING',
    "paymentType" "PaymentType" NOT NULL DEFAULT 'CASH',
    "statusHistory" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "parcel_deliveries_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "parcel_deliveries_publicNo_key" ON "parcel_deliveries"("publicNo");

-- CreateIndex
CREATE INDEX "parcel_deliveries_customerId_idx" ON "parcel_deliveries"("customerId");

-- CreateIndex
CREATE INDEX "parcel_deliveries_driverId_idx" ON "parcel_deliveries"("driverId");

-- CreateIndex
CREATE INDEX "parcel_deliveries_status_idx" ON "parcel_deliveries"("status");
