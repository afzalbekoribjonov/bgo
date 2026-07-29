ALTER TABLE "taxi_trips" ADD COLUMN "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT now();
UPDATE "taxi_trips" SET "updatedAt" = "createdAt";

ALTER TABLE "parcel_deliveries" ADD COLUMN "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT now();
UPDATE "parcel_deliveries" SET "updatedAt" = "createdAt";
