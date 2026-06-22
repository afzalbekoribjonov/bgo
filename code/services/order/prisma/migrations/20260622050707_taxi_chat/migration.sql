-- CreateTable
CREATE TABLE "taxi_messages" (
    "id" TEXT NOT NULL,
    "tripId" TEXT NOT NULL,
    "senderId" TEXT NOT NULL,
    "senderRole" TEXT NOT NULL,
    "text" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "taxi_messages_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "taxi_messages_tripId_idx" ON "taxi_messages"("tripId");

-- AddForeignKey
ALTER TABLE "taxi_messages" ADD CONSTRAINT "taxi_messages_tripId_fkey" FOREIGN KEY ("tripId") REFERENCES "taxi_trips"("id") ON DELETE CASCADE ON UPDATE CASCADE;
