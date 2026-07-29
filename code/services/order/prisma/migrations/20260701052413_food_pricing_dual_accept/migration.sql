-- AlterTable
ALTER TABLE "orders" ADD COLUMN     "driverAcceptedAt" TIMESTAMP(3),
ADD COLUMN     "kitchenAcceptedAt" TIMESTAMP(3),
ADD COLUMN     "serviceFee" INTEGER NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE "tariffs" ADD COLUMN     "foodServiceFeeOver" INTEGER NOT NULL DEFAULT 1500,
ADD COLUMN     "foodServiceFeeUnder" INTEGER NOT NULL DEFAULT 1000,
ADD COLUMN     "foodServiceThreshold" INTEGER NOT NULL DEFAULT 19000;

-- CreateTable
CREATE TABLE "order_messages" (
    "id" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "senderId" TEXT NOT NULL,
    "senderRole" TEXT NOT NULL,
    "text" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "order_messages_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "order_messages_orderId_idx" ON "order_messages"("orderId");

-- AddForeignKey
ALTER TABLE "order_messages" ADD CONSTRAINT "order_messages_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;
