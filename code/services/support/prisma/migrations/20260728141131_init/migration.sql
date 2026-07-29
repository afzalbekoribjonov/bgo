-- CreateEnum
CREATE TYPE "SupportRole" AS ENUM ('CUSTOMER', 'DRIVER');

-- CreateEnum
CREATE TYPE "ConversationStatus" AS ENUM ('OPEN', 'ESCALATED', 'RESOLVED');

-- CreateEnum
CREATE TYPE "SupportSenderRole" AS ENUM ('USER', 'BOT', 'AI', 'ADMIN', 'SYSTEM');

-- CreateTable
CREATE TABLE "faq_items" (
    "id" TEXT NOT NULL,
    "roles" "SupportRole"[] DEFAULT ARRAY[]::"SupportRole"[],
    "label" JSONB NOT NULL,
    "answer" JSONB NOT NULL,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "faq_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "support_conversations" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "userRole" "SupportRole" NOT NULL,
    "topic" TEXT NOT NULL,
    "topicLabel" TEXT,
    "status" "ConversationStatus" NOT NULL DEFAULT 'OPEN',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "support_conversations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "support_chat_messages" (
    "id" TEXT NOT NULL,
    "conversationId" TEXT NOT NULL,
    "senderRole" "SupportSenderRole" NOT NULL,
    "text" TEXT NOT NULL,
    "internalNote" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "support_chat_messages_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "faq_items_isActive_sortOrder_idx" ON "faq_items"("isActive", "sortOrder");

-- CreateIndex
CREATE INDEX "support_conversations_userId_createdAt_idx" ON "support_conversations"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "support_conversations_status_idx" ON "support_conversations"("status");

-- CreateIndex
CREATE INDEX "support_chat_messages_conversationId_createdAt_idx" ON "support_chat_messages"("conversationId", "createdAt");

-- AddForeignKey
ALTER TABLE "support_chat_messages" ADD CONSTRAINT "support_chat_messages_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "support_conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;
