/**
 * Supabase'e marka/model kataloğu seed eder (idempotent).
 *
 * Kullanım (repo kökünden):
 *   SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... npx tsx supabase/scripts/seed-catalog.ts
 */
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { createClient } from "@supabase/supabase-js";

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

const url = process.env.SUPABASE_URL ?? process.env.NEXT_PUBLIC_SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!url || !key) {
  console.error(
    "SUPABASE_URL (veya NEXT_PUBLIC_SUPABASE_URL) ve SUPABASE_SERVICE_ROLE_KEY gerekli.",
  );
  process.exit(1);
}

const supabase = createClient(url, key, {
  auth: { persistSession: false, autoRefreshToken: false },
});

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
    const { data: existingRows, error: findErr } = await supabase
      .from("brands")
      .select("*")
      .eq("slug", b.slug)
      .maybeSingle();
    if (findErr) throw findErr;

    let brand = existingRows;
    if (!brand) {
      const { data: inserted, error } = await supabase
        .from("brands")
        .insert({
          slug: b.slug,
          name: b.name,
          sort_order: b.sortOrder ?? 0,
          logo_url: b.logoUrl ?? null,
        })
        .select("*")
        .single();
      if (error) throw error;
      brand = inserted;
      brandsCreated += 1;
      process.stdout.write(`+ ${b.name}`);
    } else {
      brandsExisting += 1;
      const desiredLogo = b.logoUrl ?? null;
      if ((brand.logo_url ?? null) !== desiredLogo) {
        const { data: updated, error } = await supabase
          .from("brands")
          .update({ logo_url: desiredLogo })
          .eq("id", brand.id)
          .select("*")
          .single();
        if (error) throw error;
        brand = updated;
        logosPatched += 1;
        process.stdout.write(`= ${b.name} (logo güncellendi)`);
      } else {
        process.stdout.write(`= ${b.name}`);
      }
    }

    if (!b.models?.length) {
      console.log("");
      continue;
    }

    let bAdded = 0;
    let bSkipped = 0;
    for (const m of b.models) {
      const { data: existingModel, error: modelFindErr } = await supabase
        .from("models")
        .select("id")
        .eq("brand_id", brand.id)
        .eq("name", m.name)
        .maybeSingle();
      if (modelFindErr) throw modelFindErr;
      if (existingModel) {
        bSkipped += 1;
        continue;
      }
      const { error } = await supabase.from("models").insert({
        brand_id: brand.id,
        name: m.name,
        body_type: m.bodyType ?? null,
        year_start: m.yearStart ?? null,
        year_end: m.yearEnd ?? null,
        notes: m.notes ?? null,
      });
      if (error) throw error;
      bAdded += 1;
    }
    modelsCreated += bAdded;
    modelsExisting += bSkipped;
    console.log(` — ${bAdded} eklendi, ${bSkipped} atlandı`);
  }

  console.log("");
  console.log(
    `Markalar: +${brandsCreated} eklendi, =${brandsExisting} mevcut, ${logosPatched} logo güncellendi`,
  );
  console.log(`Modeller: +${modelsCreated} eklendi, =${modelsExisting} mevcut`);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
