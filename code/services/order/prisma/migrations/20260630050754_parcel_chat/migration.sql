-- CreateTable
CREATE TABLE "parcel_messages" (
    "id" TEXT NOT NULL,
    "parcelId" TEXT NOT NULL,
    "senderId" TEXT NOT NULL,
    "senderRole" TEXT NOT NULL,
    "text" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "parcel_messages_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "parcel_messages_parcelId_idx" ON "parcel_messages"("parcelId");

-- AddForeignKey
ALTER TABLE "parcel_messages" ADD CONSTRAINT "parcel_messages_parcelId_fkey" FOREIGN KEY ("parcelId") REFERENCES "parcel_deliveries"("id") ON DELETE CASCADE ON UPDATE CASCADE;
