import { NextRequest, NextResponse } from "next/server";

import { SESSION_COOKIE, verifySessionToken } from "@/lib/auth";

// Bu path'ler giriş gerektirmez
const PUBLIC = ["/", "/login", "/api/auth/login"];

export async function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;

  // Statik dosyalar ve public route'lar geçsin
  if (PUBLIC.includes(pathname) || pathname.startsWith("/api/auth/")) {
    return NextResponse.next();
  }

  const token = req.cookies.get(SESSION_COOKIE)?.value;

  if (!token) {
    return NextResponse.redirect(new URL("/login", req.url));
  }

  try {
    await verifySessionToken(token);
    return NextResponse.next();
  } catch {
    const res = NextResponse.redirect(new URL("/login", req.url));
    res.cookies.delete(SESSION_COOKIE);
    return res;
  }
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|.*\\.png|.*\\.jpg|.*\\.jpeg|.*\\.svg|.*\\.webp|.*\\.ico).*)"],
};
