-- add updatedAt to orders (backfill existing rows with createdAt)
ALTER TABLE "orders" ADD COLUMN "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT now();
UPDATE "orders" SET "updatedAt" = "createdAt";
