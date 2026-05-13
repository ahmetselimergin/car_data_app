import { SignJWT, jwtVerify } from "jose";

const secret = () =>
  new TextEncoder().encode(
    process.env.ADMIN_SECRET_KEY ?? "cardex-dev-secret-change-in-prod",
  );

export async function createSessionToken(): Promise<string> {
  return new SignJWT({ role: "admin" })
    .setProtectedHeader({ alg: "HS256" })
    .setIssuedAt()
    .setExpirationTime("7d")
    .sign(secret());
}

export async function verifySessionToken(token: string) {
  return jwtVerify(token, secret());
}

export const SESSION_COOKIE = "cardex-session";
