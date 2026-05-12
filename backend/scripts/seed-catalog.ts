import "dotenv/config";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { eq } from "drizzle-orm";

import { db, pool, schema } from "../src/db/client.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

interface SeedModel {
  name: string;
  bodyType?: string | null;
  yearStart?: number | null;
  yearEnd?: number | null;
  notes?: string | null;
}

interface SeedBrand {
  slug: string;
  name: string;
  sortOrder?: number;
  logoUrl?: string | null;
  models?: SeedModel[];
}

interface SeedFile {
  brands: SeedBrand[];
}

async function main() {
  const path = join(__dirname, "..", "data", "catalog-seed.json");
  const raw = readFileSync(path, "utf8");
  const data = JSON.parse(raw) as SeedFile;

  let brandsCreated = 0;
  let brandsExisting = 0;
  let logosPatched = 0;
  let modelsCreated = 0;
  let modelsExisting = 0;

  for (const b of data.brands) {
    let brand = await db.query.brands.findFirst({
      where: eq(schema.brands.slug, b.slug),
    });
    if (!brand) {
      const inserted = await db
        .insert(schema.brands)
        .values({
          slug: b.slug,
          name: b.name,
          sortOrder: b.sortOrder ?? 0,
          logoUrl: b.logoUrl ?? null,
        })
        .returning();
      brand = inserted[0]!;
      brandsCreated += 1;
      process.stdout.write(`+ ${b.name}`);
    } else {
      brandsExisting += 1;
      // Seed ile mevcut marka logosunu senkron tut (güncel URL veya null)
      const desiredLogo = b.logoUrl ?? null;
      if ((brand.logoUrl ?? null) !== desiredLogo) {
        const updated = await db
          .update(schema.brands)
          .set({ logoUrl: desiredLogo, updatedAt: new Date() })
          .where(eq(schema.brands.id, brand.id))
          .returning();
        brand = updated[0]!;
        logosPatched += 1;
        process.stdout.write(`= ${b.name} (logo güncellendi)`);
      } else {
        process.stdout.write(`= ${b.name}`);
      }
    }

    if (!b.models || b.models.length === 0) {
      console.log("");
      continue;
    }

    let bAdded = 0;
    let bSkipped = 0;
    for (const m of b.models) {
      const existing = await db.query.models.findFirst({
        where: (mt, { and, eq: eqOp }) =>
          and(eqOp(mt.brandId, brand!.id), eqOp(mt.name, m.name)),
      });
      if (existing) {
        bSkipped += 1;
        continue;
      }
      await db.insert(schema.models).values({
        brandId: brand.id,
        name: m.name,
        bodyType: m.bodyType ?? null,
        yearStart: m.yearStart ?? null,
        yearEnd: m.yearEnd ?? null,
        notes: m.notes ?? null,
      });
      bAdded += 1;
    }
    modelsCreated += bAdded;
    modelsExisting += bSkipped;
    console.log(` — ${bAdded} eklendi, ${bSkipped} atlandı`);
  }

  console.log("");
  console.log(
    `Markalar: +${brandsCreated} eklendi, =${brandsExisting} mevcut, ${logosPatched} logo eklendi`,
  );
  console.log(`Modeller: +${modelsCreated} eklendi, =${modelsExisting} mevcut`);
}

main()
  .catch((err) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(async () => {
    await pool.end();
  });
