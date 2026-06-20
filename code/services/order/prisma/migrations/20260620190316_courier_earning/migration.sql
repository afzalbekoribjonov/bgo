-- AlterTable
ALTER TABLE "orders" ADD COLUMN     "courierEarning" INTEGER NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE "tariffs" ADD COLUMN     "courierSharePercent" INTEGER NOT NULL DEFAULT 80;
