-- CreateTable
CREATE TABLE "map_roads" (
    "id" TEXT NOT NULL,
    "areaId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "kind" TEXT NOT NULL DEFAULT 'street',
    "points" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "map_roads_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "map_roads_areaId_idx" ON "map_roads"("areaId");

-- AddForeignKey
ALTER TABLE "map_roads" ADD CONSTRAINT "map_roads_areaId_fkey" FOREIGN KEY ("areaId") REFERENCES "service_areas"("id") ON DELETE CASCADE ON UPDATE CASCADE;
