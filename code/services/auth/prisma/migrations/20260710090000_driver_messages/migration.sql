-- Haydovchi xabarlari: admin → haydovchi (driverUserId NULL = hammaga)
ALTER TABLE "driver_profiles" ADD COLUMN "messagesReadAt" TIMESTAMP(3);

CREATE TABLE "driver_messages" (
    "id" TEXT NOT NULL,
    "driverUserId" TEXT,
    "title" TEXT,
    "body" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "driver_messages_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "driver_messages_driverUserId_createdAt_idx" ON "driver_messages"("driverUserId", "createdAt");
