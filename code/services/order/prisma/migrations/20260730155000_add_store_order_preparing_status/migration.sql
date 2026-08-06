-- AlterEnum
ALTER TYPE "StoreOrderStatus" ADD VALUE 'PREPARING';

-- AlterTable
ALTER TABLE "store_orders" ADD COLUMN     "readyAt" TIMESTAMP(3);
