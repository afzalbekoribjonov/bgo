-- CreateTable
CREATE TABLE "market_settings" (
    "id" TEXT NOT NULL DEFAULT 'default',
    "minOrderAmount" INTEGER NOT NULL DEFAULT 0,
    "isAcceptingOrders" BOOLEAN NOT NULL DEFAULT true,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "market_settings_pkey" PRIMARY KEY ("id")
);
