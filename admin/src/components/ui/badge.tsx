import * as React from "react";

import { cn } from "@/lib/utils";

type Variant = "default" | "outline" | "muted" | "success" | "warning";

const STYLES: Record<Variant, string> = {
  default: "bg-primary text-primary-foreground",
  outline: "border border-border",
  muted: "bg-muted text-muted-foreground",
  success: "bg-emerald-100 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300",
  warning: "bg-amber-100 text-amber-700 dark:bg-amber-950 dark:text-amber-300",
};

export function Badge({
  className,
  variant = "default",
  ...props
}: React.HTMLAttributes<HTMLSpanElement> & { variant?: Variant }) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium",
        STYLES[variant],
        className,
      )}
      {...props}
    />
  );
}
