import { Router } from "express";
import { asc, desc, eq } from "drizzle-orm";
import { z } from "zod";

import { db } from "../db/client.js";
import { insuranceCompanies, insuranceTypeList } from "../db/schema.js";
import { HttpError } from "../middleware/errorHandler.js";

const router = Router();

const createSchema = z.object({
  name: z.string().min(1),
  type: z.enum(insuranceTypeList).optional(),
  phone: z.string().nullish(),
  email: z
    .string()
    .email()
    .nullish()
    .or(z.literal("").transform(() => null)),
  website: z.string().nullish(),
  address: z.string().nullish(),
  notes: z.string().nullish(),
  active: z.boolean().optional(),
});

const updateSchema = createSchema.partial();

router.get("/", async (_req, res) => {
  const rows = await db
    .select()
    .from(insuranceCompanies)
    .orderBy(desc(insuranceCompanies.active), asc(insuranceCompanies.name));
  res.json(rows);
});

router.post("/", async (req, res) => {
  const data = createSchema.parse(req.body);
  const row = await db
    .insert(insuranceCompanies)
    .values({
      name: data.name.trim(),
      type: data.type ?? "both",
      phone: data.phone ?? null,
      email: data.email ?? null,
      website: data.website ?? null,
      address: data.address ?? null,
      notes: data.notes ?? null,
      active: data.active ?? true,
    })
    .returning();
  res.status(201).json(row[0]);
});

router.get("/:id", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) throw new HttpError(400, "BAD_ID", "Geçersiz id");
  const row = await db.query.insuranceCompanies.findFirst({
    where: eq(insuranceCompanies.id, id),
  });
  if (!row) throw new HttpError(404, "NOT_FOUND", "Bulunamadı");
  res.json(row);
});

router.patch("/:id", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) throw new HttpError(400, "BAD_ID", "Geçersiz id");
  const data = updateSchema.parse(req.body);
  if (Object.keys(data).length === 0) {
    throw new HttpError(400, "EMPTY", "Güncellenecek alan yok");
  }
  const row = await db
    .update(insuranceCompanies)
    .set({ ...data, updatedAt: new Date() })
    .where(eq(insuranceCompanies.id, id))
    .returning();
  if (row.length === 0) throw new HttpError(404, "NOT_FOUND", "Bulunamadı");
  res.json(row[0]);
});

router.delete("/:id", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) throw new HttpError(400, "BAD_ID", "Geçersiz id");
  const out = await db
    .delete(insuranceCompanies)
    .where(eq(insuranceCompanies.id, id))
    .returning({ id: insuranceCompanies.id });
  if (out.length === 0) throw new HttpError(404, "NOT_FOUND", "Bulunamadı");
  res.status(204).send();
});

export { router as insuranceRouter };
