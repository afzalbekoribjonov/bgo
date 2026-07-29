-- CreateIndex
CREATE INDEX "restaurants_status_idx" ON "restaurants"("status");

-- CreateIndex
CREATE INDEX "restaurants_ownerUserId_idx" ON "restaurants"("ownerUserId");

-- CreateIndex
CREATE INDEX "restaurants_createdAt_idx" ON "restaurants"("createdAt");
