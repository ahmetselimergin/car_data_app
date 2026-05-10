import { unlink } from "node:fs/promises";
import { join } from "node:path";

import { Router } from "express";
import { asc, eq } from "drizzle-orm";
import { z } from "zod";

import { db } from "../db/client.js";
import { brands } from "../db/schema.js";
import { HttpError } from "../middleware/errorHandler.js";
import {
  UPLOAD_ROOT,
  brandLogoUpload,
  relativeUploadUrl,
} from "../middleware/upload.js";

const router = Router();

function normalizeSlug(raw: string): string {
  return raw
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "-")
    .replace(/[^a-z0-9-]/g, "");
}

const baseFields = z.object({
  slug: z.string().min(1),
  name: z.string().min(1),
  sortOrder: z.coerce.number().int().optional(),
  /** "1" gönderilirse mevcut logo silinsin */
  removeLogo: z.coerce.boolean().optional(),
});

async function deleteIfLocal(logoUrl: string | null) {
  if (!logoUrl || !logoUrl.startsWith("/uploads/")) return;
  try {
    const rel = logoUrl.replace(/^\/uploads\//, "");
    await unlink(join(UPLOAD_ROOT, rel));
  } catch {
    /* dosya yoksa sorun değil */
  }
}

router.get("/", async (_req, res) => {
  const rows = await db
    .select()
    .from(brands)
    .orderBy(asc(brands.sortOrder), asc(brands.name));
  res.json(rows);
});

router.post("/", brandLogoUpload.single("logo"), async (req, res) => {
  const parsed = baseFields.safeParse(req.body);
  if (!parsed.success) {
    if (req.file) {
      await deleteIfLocal(relativeUploadUrl(req.file));
    }
    throw parsed.error;
  }
  const data = parsed.data;
  const slug = normalizeSlug(data.slug);
  if (!slug) {
    if (req.file) await deleteIfLocal(relativeUploadUrl(req.file));
    throw new HttpError(400, "BAD_SLUG", "Slug boş olamaz");
  }
  try {
    const row = await db
      .insert(brands)
      .values({
        slug,
        name: data.name.trim(),
        logoUrl: req.file ? relativeUploadUrl(req.file) : null,
        sortOrder: data.sortOrder ?? 0,
      })
      .returning();
    res.status(201).json(row[0]);
  } catch (e) {
    if (req.file) await deleteIfLocal(relativeUploadUrl(req.file));
    throw e;
  }
});

router.get("/:id", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) throw new HttpError(400, "BAD_ID", "Geçersiz id");
  const row = await db.query.brands.findFirst({ where: eq(brands.id, id) });
  if (!row) throw new HttpError(404, "NOT_FOUND", "Marka bulunamadı");
  res.json(row);
});

router.patch("/:id", brandLogoUpload.single("logo"), async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) {
    if (req.file) await deleteIfLocal(relativeUploadUrl(req.file));
    throw new HttpError(400, "BAD_ID", "Geçersiz id");
  }
  const existing = await db.query.brands.findFirst({
    where: eq(brands.id, id),
  });
  if (!existing) {
    if (req.file) await deleteIfLocal(relativeUploadUrl(req.file));
    throw new HttpError(404, "NOT_FOUND", "Marka yok");
  }

  const partial = baseFields.partial().safeParse(req.body);
  if (!partial.success) {
    if (req.file) await deleteIfLocal(relativeUploadUrl(req.file));
    throw partial.error;
  }
  const data = partial.data;

  const update: Partial<typeof brands.$inferInsert> & { updatedAt: Date } = {
    updatedAt: new Date(),
  };
  if (data.slug !== undefined) {
    const s = normalizeSlug(data.slug);
    if (!s) {
      if (req.file) await deleteIfLocal(relativeUploadUrl(req.file));
      throw new HttpError(400, "BAD_SLUG", "Slug boş olamaz");
    }
    update.slug = s;
  }
  if (data.name !== undefined) update.name = data.name.trim();
  if (data.sortOrder !== undefined) update.sortOrder = data.sortOrder;

  if (req.file) {
    update.logoUrl = relativeUploadUrl(req.file);
    await deleteIfLocal(existing.logoUrl);
  } else if (data.removeLogo) {
    update.logoUrl = null;
    await deleteIfLocal(existing.logoUrl);
  }

  if (Object.keys(update).length === 1 /* updatedAt only */) {
    res.json(existing);
    return;
  }

  try {
    const row = await db
      .update(brands)
      .set(update)
      .where(eq(brands.id, id))
      .returning();
    res.json(row[0]);
  } catch (e) {
    if (req.file) await deleteIfLocal(relativeUploadUrl(req.file));
    throw e;
  }
});

router.delete("/:id", async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) throw new HttpError(400, "BAD_ID", "Geçersiz id");
  const row = await db
    .delete(brands)
    .where(eq(brands.id, id))
    .returning();
  if (row.length === 0) throw new HttpError(404, "NOT_FOUND", "Marka yok");
  await deleteIfLocal(row[0]?.logoUrl ?? null);
  res.status(204).send();
});

export { router as brandsRouter };
