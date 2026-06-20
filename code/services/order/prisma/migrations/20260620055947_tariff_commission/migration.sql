-- AlterTable
ALTER TABLE "orders" ADD COLUMN     "commission" INTEGER NOT NULL DEFAULT 0;

-- CreateTable
CREATE TABLE "tariffs" (
    "id" TEXT NOT NULL DEFAULT 'default',
    "deliveryFee" INTEGER NOT NULL DEFAULT 5000,
    "foodCommissionPercent" INTEGER NOT NULL DEFAULT 12,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "tariffs_pkey" PRIMARY KEY ("id")
);
