-- CreateEnum
CREATE TYPE "ComplaintStatus" AS ENUM ('OPEN', 'RESOLVED', 'DISMISSED');

-- CreateTable
CREATE TABLE "customer_complaints" (
    "id" TEXT NOT NULL,
    "driverUserId" TEXT NOT NULL,
    "conversationId" TEXT NOT NULL,
    "orderPublicNo" INTEGER,
    "orderType" TEXT,
    "customerId" TEXT,
    "summary" TEXT NOT NULL,
    "status" "ComplaintStatus" NOT NULL DEFAULT 'OPEN',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "customer_complaints_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "customer_complaints_status_createdAt_idx" ON "customer_complaints"("status", "createdAt");

-- CreateIndex
CREATE INDEX "customer_complaints_customerId_idx" ON "customer_complaints"("customerId");
