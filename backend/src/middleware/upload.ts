import { mkdirSync } from "node:fs";
import { dirname, extname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import multer from "multer";

const __dirname = dirname(fileURLToPath(import.meta.url));

/** backend kök dizinindeki uploads/ klasörü (TS run hem dev hem build için aynı kök) */
export const UPLOAD_ROOT = resolve(__dirname, "../../uploads");

mkdirSync(UPLOAD_ROOT, { recursive: true });

const ALLOWED = new Set([".png", ".jpg", ".jpeg", ".webp", ".svg"]);

function makeStorage(subdir: string) {
  const dest = join(UPLOAD_ROOT, subdir);
  mkdirSync(dest, { recursive: true });
  return multer.diskStorage({
    destination(_req, _file, cb) {
      cb(null, dest);
    },
    filename(_req, file, cb) {
      const ext = extname(file.originalname).toLowerCase();
      const base = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
      cb(null, `${base}${ext}`);
    },
  });
}

function fileFilter(
  _req: Express.Request,
  file: Express.Multer.File,
  cb: multer.FileFilterCallback,
) {
  const ext = extname(file.originalname).toLowerCase();
  if (!ALLOWED.has(ext)) {
    cb(new Error(`Desteklenmeyen dosya türü: ${ext}`));
    return;
  }
  cb(null, true);
}

export const brandLogoUpload = multer({
  storage: makeStorage("brands"),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter,
});

export function relativeUploadUrl(file: Express.Multer.File): string {
  // diskStorage destination tam path; sadece son iki segmenti tutuyoruz
  const idx = file.path.indexOf("/uploads/");
  if (idx >= 0) return file.path.slice(idx);
  return `/uploads/${file.filename}`;
}
