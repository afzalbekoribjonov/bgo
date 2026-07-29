-- CreateTable
CREATE TABLE "kitchen_credentials" (
    "id" TEXT NOT NULL,
    "restaurantId" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "kitchen_credentials_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "kitchen_credentials_restaurantId_key" ON "kitchen_credentials"("restaurantId");

-- CreateIndex
CREATE UNIQUE INDEX "kitchen_credentials_username_key" ON "kitchen_credentials"("username");
