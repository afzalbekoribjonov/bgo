-- CreateEnum
CREATE TYPE "SellerType" AS ENUM ('SHOP', 'CONSTRUCTION');

-- CreateEnum
CREATE TYPE "ChatSenderRole" AS ENUM ('CUSTOMER', 'SELLER');

-- CreateTable
CREATE TABLE "categories" (
    "id" TEXT NOT NULL,
    "name" JSONB NOT NULL,
    "sellerType" "SellerType" NOT NULL,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sellers" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "contactPhone" TEXT NOT NULL,
    "telegram" TEXT,
    "sellerType" "SellerType" NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "sellers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "products" (
    "id" TEXT NOT NULL,
    "sellerId" TEXT NOT NULL,
    "categoryId" TEXT,
    "sellerType" "SellerType" NOT NULL,
    "name" JSONB NOT NULL,
    "description" JSONB,
    "price" INTEGER NOT NULL,
    "imageUrls" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "ratingAvg" DOUBLE PRECISION,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "products_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "chat_messages" (
    "id" TEXT NOT NULL,
    "sellerId" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,
    "senderRole" "ChatSenderRole" NOT NULL,
    "text" TEXT NOT NULL,
    "seenAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "chat_messages_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "categories_sellerType_idx" ON "categories"("sellerType");

-- CreateIndex
CREATE INDEX "sellers_sellerType_idx" ON "sellers"("sellerType");

-- CreateIndex
CREATE INDEX "products_sellerId_idx" ON "products"("sellerId");

-- CreateIndex
CREATE INDEX "products_sellerType_idx" ON "products"("sellerType");

-- CreateIndex
CREATE INDEX "products_categoryId_idx" ON "products"("categoryId");

-- CreateIndex
CREATE INDEX "chat_messages_sellerId_customerId_idx" ON "chat_messages"("sellerId", "customerId");

-- AddForeignKey
ALTER TABLE "products" ADD CONSTRAINT "products_sellerId_fkey" FOREIGN KEY ("sellerId") REFERENCES "sellers"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "products" ADD CONSTRAINT "products_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;
