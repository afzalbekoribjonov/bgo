-- Comfort tarifi bayrog'i (faqat admin yoqadi)
ALTER TABLE "driver_profiles" ADD COLUMN "isComfort" BOOLEAN NOT NULL DEFAULT false;
