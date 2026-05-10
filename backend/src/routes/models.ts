import { Router } from "express";
import { asc, eq } from "drizzle-orm";
import { z } from "zod";

import { db } from "../db/client.js";
import { brands, models } from "../db/schema.js";
import { HttpError } from "../middleware/errorHandler.js";

const router = Router();

const createSchema = z.object({
  brandId: z.coerce.number().int(),
  name: z.string().min(1),
  bodyType: z.string().nullish(),
  yearStart: z.coerce.number().int().min(1900).max(2100).nullish(),
  yearEnd: z.coerce.number().int().min(1900).max(2100).nullish(),
  notes: z.string().nullish(),
});

const updateSchema = createSchema.partial();

async function ensureBrand(id: number) {
  const exists = await db.query.brands.findFirst({ where: eq(brands.id, id) });
  if (!exists) throw new HttpError(400, "BRAND_NOT_FOUND", "Marka yok");
}

router.get("/", async (req, res) => {
  const widRaw = (req.query.brandId as string | undefined)?.trim();
  const wid = widRaw ? Number(widRaw) : undefined;
  const rows = wid
    ? await db
        .select()
        .from(models)
        .where(eq(models.brandId, wid))
        .orderBy(asc(models.name))
    : await db.select().from(models).orderBy(asc(models.name));
  res.json(rows);
});

router.post("/", async (req, res) => {
  const data = createSchema.parse(req.body);
  await ensureBrand(data.brandId);
  const row = await db
    .insert(models)
    .values({
      brandId: data.brandId,
      name: data.name.trim(),
      bodyType: data.bodyType ?? null,
      yearStart: data.yearStart ?? null,
      yearEnd: data.yearEnd ?? null,
      notes: data.notes ?? null,
    })
    .returning();
  res.status(201).json(row[0]);
});

router.get("/:id", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) throw new HttpError(400, "BAD_ID", "Geçersiz id");
  const row = await db.query.models.findFirst({ where: eq(models.id, id) });
  if (!row) throw new HttpError(404, "NOT_FOUND", "Model yok");
  res.json(row);
});

router.patch("/:id", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) throw new HttpError(400, "BAD_ID", "Geçersiz id");
  const data = updateSchema.parse(req.body);
  if (Object.keys(data).length === 0) {
    throw new HttpError(400, "EMPTY", "Güncellenecek alan yok");
  }
  if (data.brandId != null) await ensureBrand(data.brandId);
  const row = await db
    .update(models)
    .set({ ...data, updatedAt: new Date() })
    .where(eq(models.id, id))
    .returning();
  if (row.length === 0) throw new HttpError(404, "NOT_FOUND", "Model yok");
  res.json(row[0]);
});

router.delete("/:id", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) throw new HttpError(400, "BAD_ID", "Geçersiz id");
  const out = await db
    .delete(models)
    .where(eq(models.id, id))
    .returning({ id: models.id });
  if (out.length === 0) throw new HttpError(404, "NOT_FOUND", "Model yok");
  res.status(204).send();
});

export { router as modelsRouter };
