import { readFileSync } from "node:fs";
import { isAbsolute, resolve } from "node:path";

import { cert, getApps, initializeApp, type App } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";

import { HttpError } from "../middleware/errorHandler.js";

let app: App | null = null;
let initError: string | null = null;

function ensureApp(): App | null {
  if (app) return app;
  if (initError) return null;
  if (getApps().length > 0) {
    app = getApps()[0] ?? null;
    return app;
  }
  const path = process.env.FIREBASE_SERVICE_ACCOUNT_PATH?.trim();
  if (!path) {
    initError = "FIREBASE_SERVICE_ACCOUNT_PATH ayarlı değil";
    return null;
  }
  try {
    const abs = isAbsolute(path) ? path : resolve(process.cwd(), path);
    const content = readFileSync(abs, "utf8");
    const json = JSON.parse(content) as Record<string, string>;
    app = initializeApp({
      credential: cert({
        projectId: json.project_id,
        clientEmail: json.client_email,
        privateKey: json.private_key?.replace(/\\n/g, "\n"),
      }),
    });
    return app;
  } catch (e) {
    initError =
      e instanceof Error
        ? `Service account okunamadı: ${e.message}`
        : "Firebase init başarısız";
    console.error("[firebase]", initError);
    return null;
  }
}

export function isFirebaseEnabled(): boolean {
  return ensureApp() != null;
}

export function firebaseAuth() {
  const a = ensureApp();
  if (!a) {
    throw new HttpError(
      503,
      "FIREBASE_DISABLED",
      initError ?? "Firebase yapılandırılmadı",
    );
  }
  return getAuth(a);
}
