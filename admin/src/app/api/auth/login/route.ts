import { NextResponse } from "next/server";

import { createSessionToken, SESSION_COOKIE } from "@/lib/auth";

export async function POST(req: Request) {
  const { email, password } = (await req.json()) as { email?: string; password?: string };

  const adminEmail    = process.env.ADMIN_EMAIL;
  const adminPassword = process.env.ADMIN_PASSWORD;

  if (
    !adminEmail || !adminPassword ||
    email !== adminEmail || password !== adminPassword
  ) {
    return NextResponse.json({ error: "E-posta veya şifre hatalı" }, { status: 401 });
  }

  const token = await createSessionToken();
  const res = NextResponse.json({ ok: true });

  res.cookies.set(SESSION_COOKIE, token, {
    httpOnly: true,
    secure:   process.env.NODE_ENV === "production",
    sameSite: "lax",
    maxAge:   60 * 60 * 24 * 7, // 7 gün
    path:     "/",
  });

  return res;
}
