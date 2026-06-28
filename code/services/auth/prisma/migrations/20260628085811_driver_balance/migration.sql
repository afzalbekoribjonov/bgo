-- AlterTable
ALTER TABLE "driver_profiles" ADD COLUMN     "balance" INTEGER NOT NULL DEFAULT 0;

-- CreateTable
CREATE TABLE "driver_topups" (
    "id" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "driver_topups_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "driver_topups_driverId_idx" ON "driver_topups"("driverId");
