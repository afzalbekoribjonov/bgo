-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "fullName" TEXT,
    "locale" TEXT NOT NULL DEFAULT 'uz',
    "roles" TEXT[] DEFAULT ARRAY['customer']::TEXT[],
    "consentPrivacy" BOOLEAN NOT NULL DEFAULT false,
    "consentVersion" TEXT,
    "consentAcceptedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_phone_key" ON "users"("phone");
