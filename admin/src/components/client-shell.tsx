"use client";

import { usePathname } from "next/navigation";

import { MobileBar, Sidebar } from "@/components/sidebar";

export function ClientShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const isPublic = pathname === "/" || pathname === "/admin" || pathname === "/login";

  if (isPublic) return <>{children}</>;

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <div className="flex min-w-0 flex-1 flex-col">
        <MobileBar />
        <main className="min-w-0 flex-1">{children}</main>
      </div>
    </div>
  );
}
