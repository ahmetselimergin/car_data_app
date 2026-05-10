import "dotenv/config";
import pg from "pg";

const url = process.env.DATABASE_URL;
if (!url) {
  console.error("DATABASE_URL eksik (.env)");
  process.exit(1);
}

const STATEMENTS = [
  // FK constraint adını dinamik bul ve düşür (varsa)
  `DO $$
   DECLARE c text;
   BEGIN
     SELECT conname INTO c
     FROM pg_constraint
     WHERE conrelid = 'cars'::regclass
       AND contype = 'f'
       AND conname LIKE '%user_id%';
     IF c IS NOT NULL THEN
       EXECUTE 'ALTER TABLE cars DROP CONSTRAINT ' || quote_ident(c);
     END IF;
   END $$`,
  `DROP INDEX IF EXISTS idx_cars_user`,
  `ALTER TABLE cars DROP COLUMN IF EXISTS user_id`,
  `ALTER TABLE cars ADD COLUMN IF NOT EXISTS firebase_uid text`,
  `CREATE INDEX IF NOT EXISTS idx_cars_firebase ON cars (firebase_uid)`,
  `DROP TABLE IF EXISTS users CASCADE`,
];

const pool = new pg.Pool({ connectionString: url });

try {
  for (const sql of STATEMENTS) {
    console.log("→", sql.split("\n")[0]?.slice(0, 80) + "…");
    await pool.query(sql);
  }
  console.log("✓ Manuel düzeltme tamam.");
} catch (e) {
  console.error("Hata:", e);
  process.exit(1);
} finally {
  await pool.end();
}
