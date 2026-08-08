-- AlterTable
ALTER TABLE "users" ADD COLUMN     "isBlocked" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "blockedReason" TEXT,
ADD COLUMN     "blockedAt" TIMESTAMP(3),
ADD COLUMN     "messagesReadAt" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "driver_profiles" ADD COLUMN     "blockedUntil" TIMESTAMP(3),
ADD COLUMN     "blockReason" TEXT,
ADD COLUMN     "consecutiveCancellations" INTEGER NOT NULL DEFAULT 0;

-- CreateTable
CREATE TABLE "customer_messages" (
    "id" TEXT NOT NULL,
    "customerId" TEXT,
    "title" TEXT,
    "body" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "customer_messages_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "customer_messages_customerId_createdAt_idx" ON "customer_messages"("customerId", "createdAt");
