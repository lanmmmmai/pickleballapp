/*
  Warnings:

  - You are about to drop the column `location` on the `Court` table. All the data in the column will be lost.
  - You are about to drop the column `pricePerHour` on the `Court` table. All the data in the column will be lost.
  - You are about to drop the column `updatedAt` on the `Court` table. All the data in the column will be lost.
  - Added the required column `closeTime` to the `Court` table without a default value. This is not possible if the table is not empty.
  - Added the required column `openTime` to the `Court` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "Court" DROP COLUMN "location",
DROP COLUMN "pricePerHour",
DROP COLUMN "updatedAt",
ADD COLUMN     "closeTime" TEXT NOT NULL,
ADD COLUMN     "imageUrl" TEXT,
ADD COLUMN     "openTime" TEXT NOT NULL,
ALTER COLUMN "status" SET DEFAULT 'AVAILABLE',
ALTER COLUMN "status" SET DATA TYPE TEXT;

-- CreateTable
CREATE TABLE "CourtPriceSlot" (
    "id" SERIAL NOT NULL,
    "courtId" INTEGER NOT NULL,
    "startTime" TEXT NOT NULL,
    "endTime" TEXT NOT NULL,
    "price" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "CourtPriceSlot_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "CourtPriceSlot" ADD CONSTRAINT "CourtPriceSlot_courtId_fkey" FOREIGN KEY ("courtId") REFERENCES "Court"("id") ON DELETE CASCADE ON UPDATE CASCADE;
