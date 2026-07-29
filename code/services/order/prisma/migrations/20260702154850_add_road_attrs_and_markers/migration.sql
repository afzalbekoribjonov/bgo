-- AlterTable
ALTER TABLE "map_roads" ADD COLUMN     "hasTrafficLight" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "isOneWay" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "isRestricted" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "isUnderConstruction" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "speedLimit" INTEGER;

-- CreateTable
CREATE TABLE "map_markers" (
    "id" TEXT NOT NULL,
    "areaId" TEXT NOT NULL,
    "lat" DOUBLE PRECISION NOT NULL,
    "lng" DOUBLE PRECISION NOT NULL,
    "kind" TEXT NOT NULL DEFAULT 'sticker',
    "label" TEXT,
    "color" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "map_markers_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "map_markers_areaId_idx" ON "map_markers"("areaId");

-- AddForeignKey
ALTER TABLE "map_markers" ADD CONSTRAINT "map_markers_areaId_fkey" FOREIGN KEY ("areaId") REFERENCES "service_areas"("id") ON DELETE CASCADE ON UPDATE CASCADE;
