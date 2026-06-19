-- AlterTable
ALTER TABLE "orders" ADD COLUMN     "driverId" TEXT;

-- CreateIndex
CREATE INDEX "orders_driverId_idx" ON "orders"("driverId");
