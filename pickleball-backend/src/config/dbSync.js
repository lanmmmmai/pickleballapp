const path = require("path");
const { execSync } = require("child_process");
const prisma = require("./prisma");

const hasColumn = async (tableName, columnName) => {
  const rows = await prisma.$queryRawUnsafe(
    `SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = '${tableName}' AND column_name = '${columnName}' LIMIT 1`
  );
  return rows.length > 0;
};

const syncLegacyUserColumns = async () => {
  try {
    const hasEmailVerified = await hasColumn('User', 'emailVerified');
    const hasIsVerified = await hasColumn('User', 'isVerified');
    if (hasEmailVerified && hasIsVerified) {
      await prisma.$executeRawUnsafe(`
        UPDATE "User"
        SET "emailVerified" = CASE
          WHEN COALESCE("emailVerified", false) = false THEN COALESCE("isVerified", false)
          ELSE "emailVerified"
        END
      `);
    }

    const hasEmailVerifyCode = await hasColumn('User', 'emailVerifyCode');
    const hasEmailOtp = await hasColumn('User', 'emailOtp');
    if (hasEmailVerifyCode && hasEmailOtp) {
      await prisma.$executeRawUnsafe(`
        UPDATE "User"
        SET "emailVerifyCode" = COALESCE("emailVerifyCode", "emailOtp")
      `);
    }

    const hasEmailVerifyExpires = await hasColumn('User', 'emailVerifyExpires');
    const hasEmailOtpExpiresAt = await hasColumn('User', 'emailOtpExpiresAt');
    if (hasEmailVerifyExpires && hasEmailOtpExpiresAt) {
      await prisma.$executeRawUnsafe(`
        UPDATE "User"
        SET "emailVerifyExpires" = COALESCE("emailVerifyExpires", "emailOtpExpiresAt")
      `);
    }
  } catch (error) {
    console.warn('[db-sync] legacy user backfill skipped:', error.message);
  }
};

const syncDatabaseSchema = async () => {
  if (process.env.SKIP_DB_PUSH === 'true') return;
  try {
    const projectRoot = path.join(__dirname, '..', '..');
    execSync('npx prisma db push', {
      cwd: projectRoot,
      stdio: 'inherit',
      env: process.env,
    });
  } catch (error) {
    console.warn('[db-sync] prisma db push failed:', error.message);
  }

  await syncLegacyUserColumns();
};

module.exports = { syncDatabaseSchema };
