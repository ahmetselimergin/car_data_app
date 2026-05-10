"use client";

import { MoreHorizontal } from "lucide-react";
import * as React from "react";
import { createPortal } from "react-dom";

import { cn } from "@/lib/utils";

export type ActionMenuItem = {
  label: string;
  icon?: React.ComponentType<{ className?: string }>;
  onClick: () => void;
  destructive?: boolean;
  separator?: never;
};

export type ActionMenuSeparator = { separator: true };

export type ActionMenuEntry = ActionMenuItem | ActionMenuSeparator;

interface ActionMenuProps {
  items: ActionMenuEntry[];
  disabled?: boolean;
  label?: string;
}

export function ActionMenu({ items, disabled, label = "Aksiyonlar" }: ActionMenuProps) {
  const [open, setOpen] = React.useState(false);
  const [coords, setCoords] = React.useState<{ top: number; left: number } | null>(
    null,
  );
  const [mounted, setMounted] = React.useState(false);
  const triggerRef = React.useRef<HTMLButtonElement | null>(null);
  const menuRef = React.useRef<HTMLDivElement | null>(null);

  React.useEffect(() => setMounted(true), []);

  function position() {
    const t = triggerRef.current;
    if (!t) return;
    const rect = t.getBoundingClientRect();
    const menuWidth = 224; // w-56
    const top = rect.bottom + 4;
    let left = rect.right - menuWidth;
    if (left < 8) left = 8;
    if (left + menuWidth > window.innerWidth - 8)
      left = window.innerWidth - menuWidth - 8;
    setCoords({ top, left });
  }

  React.useEffect(() => {
    if (!open) return;
    position();
    function onWin() {
      setOpen(false);
    }
    window.addEventListener("scroll", onWin, true);
    window.addEventListener("resize", onWin);
    function onDown(e: MouseEvent) {
      if (
        menuRef.current?.contains(e.target as Node) ||
        triggerRef.current?.contains(e.target as Node)
      )
        return;
      setOpen(false);
    }
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape") setOpen(false);
    }
    document.addEventListener("mousedown", onDown);
    document.addEventListener("keydown", onKey);
    return () => {
      window.removeEventListener("scroll", onWin, true);
      window.removeEventListener("resize", onWin);
      document.removeEventListener("mousedown", onDown);
      document.removeEventListener("keydown", onKey);
    };
  }, [open]);

  return (
    <>
      <button
        ref={triggerRef}
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="hover:bg-accent inline-flex h-8 items-center justify-center rounded-md px-2"
        aria-label={label}
        aria-haspopup="menu"
        aria-expanded={open}
        disabled={disabled}
      >
        <MoreHorizontal className="size-4" />
      </button>

      {mounted && open && coords
        ? createPortal(
            <div
              ref={menuRef}
              role="menu"
              style={{
                position: "fixed",
                top: coords.top,
                left: coords.left,
                width: 224,
              }}
              className="bg-card border-border z-[100] grid gap-0.5 rounded-md border p-1 shadow-lg"
            >
              {items.map((item, idx) => {
                if ("separator" in item) {
                  // eslint-disable-next-line react/no-array-index-key -- separator için stabil id yok
                  return <div key={`sep-${idx}`} className="bg-border my-1 h-px" />;
                }
                const Icon = item.icon;
                return (
                  <button
                    key={item.label}
                    type="button"
                    role="menuitem"
                    onClick={() => {
                      setOpen(false);
                      item.onClick();
                    }}
                    className={cn(
                      "hover:bg-accent flex w-full items-center gap-2 rounded px-2 py-1.5 text-left text-sm transition-colors",
                      item.destructive
                        ? "text-destructive hover:text-destructive"
                        : "",
                    )}
                  >
                    {Icon ? <Icon className="size-4" /> : null}
                    {item.label}
                  </button>
                );
              })}
            </div>,
            document.body,
          )
        : null}
    </>
  );
}
