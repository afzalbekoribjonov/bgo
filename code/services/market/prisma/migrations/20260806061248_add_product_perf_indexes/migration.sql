-- CreateIndex
CREATE INDEX "products_isActive_createdAt_idx" ON "products"("isActive", "createdAt");

-- CreateIndex
CREATE INDEX "products_categoryId_isActive_createdAt_idx" ON "products"("categoryId", "isActive", "createdAt");
