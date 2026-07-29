-- CreateIndex
CREATE INDEX "orders_status_idx" ON "orders"("status");

-- CreateIndex
CREATE INDEX "orders_createdAt_idx" ON "orders"("createdAt");

-- CreateIndex
CREATE INDEX "parcel_deliveries_createdAt_idx" ON "parcel_deliveries"("createdAt");

-- CreateIndex
CREATE INDEX "store_orders_createdAt_idx" ON "store_orders"("createdAt");

-- CreateIndex
CREATE INDEX "taxi_trips_createdAt_idx" ON "taxi_trips"("createdAt");
