-- CreateTable
CREATE TABLE "telegram_links" (
    "phone" TEXT NOT NULL,
    "chatId" TEXT NOT NULL,
    "username" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "telegram_links_pkey" PRIMARY KEY ("phone")
);
