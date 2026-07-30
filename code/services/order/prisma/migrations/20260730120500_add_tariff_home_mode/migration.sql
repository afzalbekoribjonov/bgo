-- AlterTable
ALTER TABLE "tariffs" ADD COLUMN     "homeModeTaxiCommissionPercent" INTEGER NOT NULL DEFAULT 20,
ADD COLUMN     "homeModeParcelCommissionPercent" INTEGER NOT NULL DEFAULT 20,
ADD COLUMN     "homeModeMaxDetourPercent" INTEGER NOT NULL DEFAULT 30;
