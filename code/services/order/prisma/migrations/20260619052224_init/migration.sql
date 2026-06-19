-- CreateEnum
CREATE TYPE "OrderType" AS ENUM ('FOOD', 'TAXI', 'DELIVERY');

-- CreateEnum
CREATE TYPE "OrderStatus" AS ENUM ('PENDING', 'ACCEPTED', 'PREPARING', 'READY', 'ASSIGNED', 'IN_PROGRESS', 'PICKED_UP', 'DELIVERED', 'COMPLETED', 'CANCELLED', 'FAILED');

-- CreateEnum
CREATE TYPE "PaymentType" AS ENUM ('CASH', 'PAYME', 'CLICK', 'UZUM');

-- CreateTable
CREATE TABLE "orders" (
    "id" TEXT NOT NULL,
    "publicNo" SERIAL NOT NULL,
    "customerId" TEXT NOT NULL,
    "type" "OrderType" NOT NULL,
    "restaurantId" TEXT NOT NULL,
    "items" JSONB NOT NULL,
    "itemsTotal" INTEGER NOT NULL,
    "deliveryFee" INTEGER NOT NULL,
    "total" INTEGER NOT NULL,
    "paymentType" "PaymentType" NOT NULL,
    "address" JSONB NOT NULL,
    "status" "OrderStatus" NOT NULL DEFAULT 'PENDING',
    "statusHistory" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "orders_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "orders_publicNo_key" ON "orders"("publicNo");

-- CreateIndex
CREATE INDEX "orders_customerId_idx" ON "orders"("customerId");

-- CreateIndex
CREATE INDEX "orders_restaurantId_idx" ON "orders"("restaurantId");
