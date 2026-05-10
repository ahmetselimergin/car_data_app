import type { ErrorRequestHandler, Request, Response } from "express";
import { ZodError } from "zod";

const PG_FRIENDLY: Record<string, string> = {
  "23505": "Bu kayıt zaten mevcut (benzersizlik ihlali).",
  "23503": "İlişkili kayıt bulunamadı.",
  "42P01": "PostgreSQL tablosu yok. `npm run migrate` çalıştırın.",
  "42703": "Şema güncel değil. `npm run migrate` çalıştırın.",
  "ECONNREFUSED": "PostgreSQL'e bağlanılamıyor. Servisi kontrol edin.",
  "ENOTFOUND": "PostgreSQL host adresi çözümlenemedi.",
  "3D000": "Veritabanı bulunamadı (DATABASE_URL adı).",
  "28P01": "PostgreSQL kimlik doğrulaması başarısız.",
};

export class HttpError extends Error {
  constructor(public status: number, public code: string, message: string) {
    super(message);
  }
}

export const errorHandler: ErrorRequestHandler = (
  err: unknown,
  _req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars -- Express dört arg ister
  _next,
) => {
  if (err instanceof ZodError) {
    res.status(400).json({
      error: "Geçersiz gövde",
      detail: err.issues.map((i) => `${i.path.join(".") || "_"}: ${i.message}`),
    });
    return;
  }
  if (err instanceof HttpError) {
    res.status(err.status).json({ error: err.message, code: err.code });
    return;
  }
  const e = err as { code?: string; message?: string };
  const friendly = e.code ? PG_FRIENDLY[e.code] : undefined;
  const isDev = process.env.NODE_ENV !== "production";
  console.error(err);
  res.status(500).json({
    error: friendly ?? "Sunucu hatası",
    ...(isDev && e.message ? { debug: e.message } : {}),
  });
};
