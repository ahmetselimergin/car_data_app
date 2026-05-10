"use client";

import {
  BookOpen,
  Building2,
  Car,
  ChevronDown,
  FileSignature,
  Gauge,
  Handshake,
  Layers,
  ShieldCheck,
  Tag,
  Users,
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import * as React from "react";

import { ThemeToggle } from "@/components/theme-toggle";
import { cn } from "@/lib/utils";

type LeafItem = {
  href: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
};

type GroupItem = {
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  // Tıklanabilir grup sayfası (opsiyonel)
  href?: string;
  children: LeafItem[];
};

const NAV: (LeafItem | GroupItem)[] = [
  {
    href: "/",
    label: "Dashboard",
    icon: Gauge,
  },
  {
    label: "Araç",
    icon: Car,
    children: [
      { href: "/brands", label: "Markalar", icon: Tag },
      { href: "/models", label: "Modeller", icon: Layers },
    ],
  },
  {
    label: "Anlaşmalı Kurumlar",
    icon: Handshake,
    children: [
      { href: "/workshops", label: "Tamirhaneler", icon: Building2 },
      { href: "/insurance", label: "Sigorta & Kasko", icon: ShieldCheck },
    ],
  },
  {
    href: "/firebase-users",
    label: "Kullanıcılar",
    icon: Users,
  },
  {
    href: "/api-docs",
    label: "API Dökümanı",
    icon: BookOpen,
  },
];

function isActive(href: string, pathname: string): boolean {
  if (href === "/") return pathname === "/";
  return pathname === href || pathname.startsWith(`${href}/`);
}

function isGroupActive(group: GroupItem, pathname: string): boolean {
  if (group.href && isActive(group.href, pathname)) return true;
  return group.children.some((c) => isActive(c.href, pathname));
}

function NavLeaf({
  item,
  pathname,
  nested = false,
}: {
  item: LeafItem;
  pathname: string;
  nested?: boolean;
}) {
  const active = isActive(item.href, pathname);
  return (
    <Link
      href={item.href}
      className={cn(
        "flex items-center gap-2.5 rounded-md px-3 py-2 text-sm font-medium transition-colors",
        nested ? "ml-6 pl-3 border-l border-border" : "",
        active
          ? "bg-primary text-primary-foreground"
          : "text-foreground/80 hover:bg-accent hover:text-foreground",
      )}
    >
      <item.icon className="size-4 shrink-0" />
      <span className="truncate">{item.label}</span>
    </Link>
  );
}

function NavGroup({
  group,
  pathname,
}: {
  group: GroupItem;
  pathname: string;
}) {
  const groupActive = isGroupActive(group, pathname);
  const [open, setOpen] = React.useState<boolean>(groupActive);

  React.useEffect(() => {
    if (groupActive) setOpen(true);
  }, [groupActive]);

  const headerHref = group.href;
  const headerActive = headerHref
    ? isActive(headerHref, pathname) &&
      !group.children.some((c) => c.href === pathname)
    : false;

  return (
    <div>
      <div
        className={cn(
          "flex items-center rounded-md transition-colors",
          headerActive
            ? "bg-primary text-primary-foreground"
            : groupActive
              ? "bg-accent/40 text-foreground"
              : "text-foreground/80 hover:bg-accent",
        )}
      >
        {headerHref ? (
          <Link
            href={headerHref}
            className="flex flex-1 items-center gap-2.5 px-3 py-2 text-sm font-medium"
          >
            <group.icon className="size-4 shrink-0" />
            <span className="truncate">{group.label}</span>
          </Link>
        ) : (
          <button
            type="button"
            onClick={() => setOpen((o) => !o)}
            className="flex flex-1 items-center gap-2.5 px-3 py-2 text-sm font-medium"
          >
            <group.icon className="size-4 shrink-0" />
            <span className="truncate">{group.label}</span>
          </button>
        )}
        <button
          type="button"
          aria-label={open ? "Kapat" : "Aç"}
          onClick={() => setOpen((o) => !o)}
          className="text-muted-foreground hover:text-foreground mr-1 rounded-md p-1.5 transition-colors"
        >
          <ChevronDown
            className={cn(
              "size-4 transition-transform",
              open ? "rotate-0" : "-rotate-90",
            )}
          />
        </button>
      </div>
      {open ? (
        <div className="mt-1 grid gap-1">
          {group.children.map((child) => (
            <NavLeaf
              key={child.href}
              item={child}
              pathname={pathname}
              nested
            />
          ))}
        </div>
      ) : null}
    </div>
  );
}

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="bg-card border-border sticky top-0 flex h-screen w-64 shrink-0 flex-col border-r">
      <div className="border-border flex items-center gap-2 border-b px-5 py-4">
        <span className="bg-primary text-primary-foreground inline-flex size-8 items-center justify-center rounded-md font-bold">
          C
        </span>
        <div className="flex flex-col leading-tight">
          <span className="text-base font-semibold tracking-tight">
            CarDEX
          </span>
          <span className="text-muted-foreground text-xs">Yönetim paneli</span>
        </div>
      </div>
      <nav className="flex-1 space-y-1 overflow-y-auto p-3">
        {NAV.map((item) =>
          "children" in item ? (
            <NavGroup key={item.label} group={item} pathname={pathname} />
          ) : (
            <NavLeaf key={item.href} item={item} pathname={pathname} />
          ),
        )}
      </nav>
      <div className="border-border bg-muted/30 space-y-2 border-t px-4 py-3">
        <ThemeToggle />
        <a
          href={process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:4000"}
          target="_blank"
          rel="noreferrer"
          className="text-muted-foreground hover:text-foreground inline-flex items-center gap-2 text-xs"
        >
          <FileSignature className="size-3.5" /> API durumu
        </a>
      </div>
    </aside>
  );
}

export function MobileBar() {
  return null;
}
