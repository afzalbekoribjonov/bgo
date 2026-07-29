-- CreateTable
CREATE TABLE "seller_credentials" (
    "id" TEXT NOT NULL,
    "sellerId" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "sellerType" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "seller_credentials_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "seller_credentials_sellerId_key" ON "seller_credentials"("sellerId");

-- CreateIndex
CREATE UNIQUE INDEX "seller_credentials_username_key" ON "seller_credentials"("username");
