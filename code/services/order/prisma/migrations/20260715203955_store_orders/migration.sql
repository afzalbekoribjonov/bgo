-- CreateEnum
CREATE TYPE "StoreOrderStatus" AS ENUM ('PENDING', 'ACCEPTED', 'ARRIVED', 'PICKED_UP', 'IN_TRANSIT', 'DELIVERED', 'READY_FOR_PICKUP', 'COMPLETED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "StoreDeliveryMethod" AS ENUM ('DELIVERY', 'PICKUP');

-- AlterTable
ALTER TABLE "orders" ALTER COLUMN "updatedAt" DROP DEFAULT;

-- AlterTable
ALTER TABLE "parcel_deliveries" ALTER COLUMN "updatedAt" DROP DEFAULT;

-- AlterTable
ALTER TABLE "taxi_trips" ALTER COLUMN "updatedAt" DROP DEFAULT;

-- CreateTable
CREATE TABLE "store_orders" (
    "id" TEXT NOT NULL,
    "publicNo" SERIAL NOT NULL,
    "customerId" TEXT NOT NULL,
    "driverId" TEXT,
    "pickupLocationId" TEXT NOT NULL,
    "deliveryMethod" "StoreDeliveryMethod" NOT NULL,
    "address" JSONB,
    "items" JSONB NOT NULL,
    "itemsTotal" INTEGER NOT NULL,
    "deliveryFee" INTEGER NOT NULL DEFAULT 0,
    "courierEarning" INTEGER NOT NULL DEFAULT 0,
    "total" INTEGER NOT NULL,
    "status" "StoreOrderStatus" NOT NULL DEFAULT 'PENDING',
    "paymentType" "PaymentType" NOT NULL DEFAULT 'CASH',
    "statusHistory" JSONB NOT NULL,
    "rating" INTEGER,
    "ratingComment" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "store_orders_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "store_orders_publicNo_key" ON "store_orders"("publicNo");

-- CreateIndex
CREATE INDEX "store_orders_customerId_idx" ON "store_orders"("customerId");

-- CreateIndex
CREATE INDEX "store_orders_driverId_idx" ON "store_orders"("driverId");

-- CreateIndex
CREATE INDEX "store_orders_status_idx" ON "store_orders"("status");
