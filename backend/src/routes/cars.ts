import { Router } from "express";
import { desc, eq } from "drizzle-orm";
import { z } from "zod";

import { db } from "../db/client.js";
import { brands, cars } from "../db/schema.js";
import { HttpError } from "../middleware/errorHandler.js";

const router = Router();

const createSchema = z.object({
  plaka: z.string().min(1),
  marka: z.string().min(1),
  model: z.string().min(1),
  yil: z.coerce.number().int().min(1900).max(2100),
  km: z.coerce.number().int().min(0).optional(),
  transmission: z.string().nullish(),
  fuelType: z.string().nullish(),
  color: z.string().nullish(),
  imageUrl: z.string().url().nullish(),
  notes: z.string().nullish(),
  brandId: z.coerce.number().int().nullish(),
  firebaseUid: z.string().nullish(),
});

const updateSchema = createSchema.partial();

async function ensureBrandExists(brandId: number | null | undefined) {
  if (brandId == null) return;
  const exists = await db.query.brands.findFirst({
    where: eq(brands.id, brandId),
  });
  if (!exists) throw new HttpError(400, "BRAND_NOT_FOUND", "Marka bulunamadı");
}

async function fetchCarWithBrand(id: number) {
  const row = await db.query.cars.findFirst({ where: eq(cars.id, id) });
  if (!row) return null;
  let brand: typeof brands.$inferSelect | null = null;
  if (row.brandId != null) {
    brand =
      (await db.query.brands.findFirst({ where: eq(brands.id, row.brandId) })) ??
      null;
  }
  return { ...row, brand };
}

router.get("/", async (req, res) => {
  const uid = (req.query.firebaseUid as string | undefined)?.trim();
  const rows = uid
    ? await db
        .select()
        .from(cars)
        .where(eq(cars.firebaseUid, uid))
        .orderBy(desc(cars.id))
    : await db.select().from(cars).orderBy(desc(cars.id));
  const brandList = await db.select().from(brands);
  const map = new Map(brandList.map((b) => [b.id, b]));
  res.json(
    rows.map((r) => ({
      ...r,
      brand: r.brandId != null ? (map.get(r.brandId) ?? null) : null,
    })),
  );
});

router.post("/", async (req, res) => {
  const data = createSchema.parse(req.body);
  await ensureBrandExists(data.brandId ?? null);
  const inserted = await db
    .insert(cars)
    .values({
      plaka: data.plaka.trim(),
      marka: data.marka.trim(),
      model: data.model.trim(),
      yil: data.yil,
      km: data.km ?? 0,
      transmission: data.transmission ?? null,
      fuelType: data.fuelType ?? null,
      color: data.color ?? null,
      imageUrl: data.imageUrl ?? null,
      notes: data.notes ?? null,
      brandId: data.brandId ?? null,
      firebaseUid: data.firebaseUid?.trim() || null,
    })
    .returning({ id: cars.id });
  const newId = inserted[0]?.id;
  if (newId == null) throw new HttpError(500, "INSERT_FAILED", "Eklenemedi");
  res.status(201).json(await fetchCarWithBrand(newId));
});

router.get("/:id", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) throw new HttpError(400, "BAD_ID", "Geçersiz id");
  const row = await fetchCarWithBrand(id);
  if (!row) throw new HttpError(404, "NOT_FOUND", "Araç yok");
  res.json(row);
});

router.patch("/:id", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) throw new HttpError(400, "BAD_ID", "Geçersiz id");
  const data = updateSchema.parse(req.body);
  if (Object.keys(data).length === 0) {
    throw new HttpError(400, "EMPTY", "Güncellenecek alan yok");
  }
  if ("brandId" in data) {
    await ensureBrandExists(data.brandId ?? null);
  }
  const patch: Partial<typeof cars.$inferInsert> & { updatedAt: Date } = {
    updatedAt: new Date(),
  };
  if (data.plaka !== undefined) patch.plaka = data.plaka.trim();
  if (data.marka !== undefined) patch.marka = data.marka.trim();
  if (data.model !== undefined) patch.model = data.model.trim();
  if (data.yil !== undefined) patch.yil = data.yil;
  if (data.km !== undefined) patch.km = data.km;
  if (data.transmission !== undefined)
    patch.transmission = data.transmission ?? null;
  if (data.fuelType !== undefined) patch.fuelType = data.fuelType ?? null;
  if (data.color !== undefined) patch.color = data.color ?? null;
  if (data.imageUrl !== undefined) patch.imageUrl = data.imageUrl ?? null;
  if (data.notes !== undefined) patch.notes = data.notes ?? null;
  if (data.brandId !== undefined) patch.brandId = data.brandId ?? null;
  if (data.firebaseUid !== undefined)
    patch.firebaseUid = data.firebaseUid?.trim() || null;

  const updated = await db
    .update(cars)
    .set(patch)
    .where(eq(cars.id, id))
    .returning({ id: cars.id });
  if (updated.length === 0) throw new HttpError(404, "NOT_FOUND", "Araç yok");
  res.json(await fetchCarWithBrand(id));
});

router.delete("/:id", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) throw new HttpError(400, "BAD_ID", "Geçersiz id");
  const out = await db
    .delete(cars)
    .where(eq(cars.id, id))
    .returning({ id: cars.id });
  if (out.length === 0) throw new HttpError(404, "NOT_FOUND", "Araç yok");
  res.status(204).send();
});

export { router as carsRouter };
