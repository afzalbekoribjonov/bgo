-- CreateTable
CREATE TABLE "driver_locations" (
    "driverId" TEXT NOT NULL,
    "lat" DOUBLE PRECISION NOT NULL,
    "lng" DOUBLE PRECISION NOT NULL,
    "heading" DOUBLE PRECISION,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "driver_locations_pkey" PRIMARY KEY ("driverId")
);

-- CreateIndex
CREATE INDEX "driver_locations_updatedAt_idx" ON "driver_locations"("updatedAt");
