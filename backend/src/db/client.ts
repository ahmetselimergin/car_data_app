import "dotenv/config";
import { drizzle } from "drizzle-orm/node-postgres";
import pg from "pg";

import * as schema from "./schema.js";

const url = process.env.DATABASE_URL;
if (!url) {
  throw new Error(
    "DATABASE_URL eksik. `cp .env.example .env` ve doldurun (Neon / Docker / Homebrew).",
  );
}

export const pool = new pg.Pool({ connectionString: url, max: 10 });
export const db = drizzle({ client: pool, schema, casing: "snake_case" });
export { schema };
