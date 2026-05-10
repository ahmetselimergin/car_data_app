import { Router } from "express";
import { z } from "zod";

import { firebaseRoleList } from "../db/schema.js";
import { firebaseAuth, isFirebaseEnabled } from "../lib/firebase.js";
import { HttpError } from "../middleware/errorHandler.js";

const router = Router();

function userToDto(u: import("firebase-admin/auth").UserRecord) {
  return {
    uid: u.uid,
    email: u.email ?? null,
    emailVerified: u.emailVerified,
    displayName: u.displayName ?? null,
    photoURL: u.photoURL ?? null,
    phoneNumber: u.phoneNumber ?? null,
    disabled: u.disabled,
    providers: u.providerData.map((p) => ({
      providerId: p.providerId,
      uid: p.uid,
      email: p.email ?? null,
      displayName: p.displayName ?? null,
    })),
    metadata: {
      createdAt: u.metadata.creationTime,
      lastSignInAt: u.metadata.lastSignInTime,
      lastRefreshAt: u.metadata.lastRefreshTime ?? null,
    },
    customClaims: u.customClaims ?? null,
  };
}

router.get("/status", (_req, res) => {
  res.json({ enabled: isFirebaseEnabled() });
});

router.get("/", async (req, res) => {
  const limitRaw = (req.query.limit as string | undefined)?.trim();
  const pageToken = (req.query.pageToken as string | undefined)?.trim() || undefined;
  const limit = Math.min(Math.max(Number(limitRaw) || 100, 1), 1000);
  const auth = firebaseAuth();
  const result = await auth.listUsers(limit, pageToken);
  res.json({
    users: result.users.map(userToDto),
    pageToken: result.pageToken ?? null,
  });
});

router.get("/:uid", async (req, res) => {
  const auth = firebaseAuth();
  try {
    const u = await auth.getUser(req.params.uid);
    res.json(userToDto(u));
  } catch (e) {
    const err = e as { code?: string };
    if (err.code === "auth/user-not-found") {
      throw new HttpError(404, "NOT_FOUND", "Kullanıcı yok");
    }
    throw e;
  }
});

const updateSchema = z.object({
  email: z.string().email().optional(),
  emailVerified: z.boolean().optional(),
  displayName: z.string().nullish(),
  phoneNumber: z.string().nullish(),
  photoURL: z.string().url().nullish(),
  disabled: z.boolean().optional(),
  password: z.string().min(6).optional(),
});

router.patch("/:uid", async (req, res) => {
  const data = updateSchema.parse(req.body);
  if (Object.keys(data).length === 0) {
    throw new HttpError(400, "EMPTY", "Güncellenecek alan yok");
  }
  const auth = firebaseAuth();
  try {
    const updated = await auth.updateUser(req.params.uid, data);
    res.json(userToDto(updated));
  } catch (e) {
    const err = e as { code?: string };
    if (err.code === "auth/user-not-found") {
      throw new HttpError(404, "NOT_FOUND", "Kullanıcı yok");
    }
    if (err.code === "auth/email-already-exists") {
      throw new HttpError(409, "EMAIL_TAKEN", "Bu e-posta başka bir kullanıcıda");
    }
    throw e;
  }
});

router.post("/:uid/disable", async (req, res) => {
  const auth = firebaseAuth();
  const u = await auth.updateUser(req.params.uid, { disabled: true });
  res.json(userToDto(u));
});

router.post("/:uid/enable", async (req, res) => {
  const auth = firebaseAuth();
  const u = await auth.updateUser(req.params.uid, { disabled: false });
  res.json(userToDto(u));
});

router.post("/:uid/reset-password", async (req, res) => {
  const auth = firebaseAuth();
  const u = await auth.getUser(req.params.uid);
  if (!u.email) {
    throw new HttpError(400, "NO_EMAIL", "Kullanıcının e-postası yok");
  }
  const link = await auth.generatePasswordResetLink(u.email);
  res.json({ link, email: u.email });
});

router.post("/:uid/verify-email", async (req, res) => {
  const auth = firebaseAuth();
  const u = await auth.getUser(req.params.uid);
  if (!u.email) {
    throw new HttpError(400, "NO_EMAIL", "Kullanıcının e-postası yok");
  }
  const link = await auth.generateEmailVerificationLink(u.email);
  res.json({ link, email: u.email });
});

router.post("/:uid/revoke-tokens", async (req, res) => {
  const auth = firebaseAuth();
  await auth.revokeRefreshTokens(req.params.uid);
  res.status(204).send();
});

/**
 * Custom claims yönetimi (panel rolü).
 * Body: `{ role: 'admin' | 'operator' | 'viewer' | null }` — null gönderilirse rol kaldırılır.
 */
const claimsSchema = z.object({
  role: z.enum([...firebaseRoleList, "none"] as const).nullable(),
});

router.post("/:uid/claims", async (req, res) => {
  const data = claimsSchema.parse(req.body);
  const auth = firebaseAuth();
  const u = await auth.getUser(req.params.uid);
  const current = (u.customClaims ?? {}) as Record<string, unknown>;
  const next = { ...current };
  if (data.role == null || data.role === "none") {
    delete next.role;
  } else {
    next.role = data.role;
  }
  await auth.setCustomUserClaims(req.params.uid, next);
  // Token'ları iptal et ki kullanıcı yeni claim'lerle yeniden giriş yapsın
  await auth.revokeRefreshTokens(req.params.uid);
  const updated = await auth.getUser(req.params.uid);
  res.json(userToDto(updated));
});

router.delete("/:uid", async (req, res) => {
  const auth = firebaseAuth();
  try {
    await auth.deleteUser(req.params.uid);
    res.status(204).send();
  } catch (e) {
    const err = e as { code?: string };
    if (err.code === "auth/user-not-found") {
      throw new HttpError(404, "NOT_FOUND", "Kullanıcı yok");
    }
    throw e;
  }
});

export { router as firebaseUsersRouter };
