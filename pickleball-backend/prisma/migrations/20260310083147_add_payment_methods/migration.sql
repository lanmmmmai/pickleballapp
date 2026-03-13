/*
  Warnings:

  - You are about to drop the column `emailOtp` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `emailOtpExpiresAt` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `isVerified` on the `User` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "User" DROP COLUMN "emailOtp",
DROP COLUMN "emailOtpExpiresAt",
DROP COLUMN "isVerified",
ADD COLUMN     "emailVerified" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "emailVerifyCode" TEXT,
ADD COLUMN     "emailVerifyExpires" TIMESTAMP(3),
ADD COLUMN     "paymentMethods" TEXT[] DEFAULT ARRAY[]::TEXT[],
ALTER COLUMN "phone" DROP NOT NULL;
