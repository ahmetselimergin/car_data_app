"use client";

import { Monitor, Moon, Sun } from "lucide-react";
import { useTheme } from "next-themes";
import * as React from "react";

import { cn } from "@/lib/utils";

const OPTIONS = [
  { value: "light", icon: Sun, label: "Açık" },
  { value: "dark", icon: Moon, label: "Koyu" },
  { value: "system", icon: Monitor, label: "Sistem" },
] as const;

export function ThemeToggle({ compact = false }: { compact?: boolean }) {
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => {
    setMounted(true);
  }, []);

  // SSR ile uyumsuzluğu önlemek için mount edilmeden ikonsuz görünsün
  const active = mounted ? theme ?? "system" : "system";

  return (
    <div
      role="radiogroup"
      aria-label="Tema seçimi"
      className={cn(
        "border-border bg-muted/40 inline-flex items-center rounded-md border p-0.5",
      )}
    >
      {OPTIONS.map((opt) => {
        const Icon = opt.icon;
        const isActive = active === opt.value;
        return (
          <button
            key={opt.value}
            type="button"
            role="radio"
            aria-checked={isActive}
            aria-label={opt.label}
            title={opt.label}
            onClick={() => setTheme(opt.value)}
            className={cn(
              "flex items-center gap-1.5 rounded px-2 py-1 text-xs transition-colors",
              isActive
                ? "bg-card text-foreground shadow-sm"
                : "text-muted-foreground hover:text-foreground",
            )}
          >
            <Icon className="size-3.5" />
            {compact ? null : <span>{opt.label}</span>}
          </button>
        );
      })}
    </div>
  );
}
