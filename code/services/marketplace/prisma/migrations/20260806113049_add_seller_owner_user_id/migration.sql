-- AlterTable
ALTER TABLE "sellers" ADD COLUMN     "ownerUserId" TEXT;

-- CreateIndex
CREATE INDEX "sellers_ownerUserId_idx" ON "sellers"("ownerUserId");
