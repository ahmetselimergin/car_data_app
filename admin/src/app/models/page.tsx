"use client";

import { Pencil, Plus, RefreshCcw, Trash2 } from "lucide-react";
import { useMemo, useState } from "react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ConfirmDialog, Modal } from "@/components/ui/modal";
import { Select } from "@/components/ui/select-native";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Textarea } from "@/components/ui/textarea";
import { assetUrl, type Brand, type Model } from "@/lib/api";
import { sendJson, useList } from "@/lib/use-list";

type FormState = {
  brandId: string;
  name: string;
  bodyType: string;
  yearStart: string;
  yearEnd: string;
  notes: string;
};

const EMPTY: FormState = {
  brandId: "",
  name: "",
  bodyType: "",
  yearStart: "",
  yearEnd: "",
  notes: "",
};

const BODY_TYPES = [
  "Sedan",
  "Hatchback",
  "SUV",
  "Crossover",
  "Coupe",
  "Cabrio",
  "Pickup",
  "Van",
  "Station Wagon",
];

export default function ModelsPage() {
  const list = useList<Model>("/api/v1/models");
  const brands = useList<Brand>("/api/v1/brands");

  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<Model | null>(null);
  const [form, setForm] = useState<FormState>(EMPTY);
  const [deleteTarget, setDeleteTarget] = useState<Model | null>(null);
  const [busy, setBusy] = useState(false);
  const [filterBrandId, setFilterBrandId] = useState<string>("");

  const brandMap = useMemo(() => {
    const m = new Map<number, Brand>();
    for (const b of brands.data) m.set(b.id, b);
    return m;
  }, [brands.data]);

  const visible = useMemo(() => {
    if (!filterBrandId) return list.data;
    const id = Number(filterBrandId);
    return list.data.filter((m) => m.brandId === id);
  }, [list.data, filterBrandId]);

  function startAdd() {
    setEditing(null);
    setForm({
      ...EMPTY,
      brandId: filterBrandId || (brands.data[0] ? String(brands.data[0].id) : ""),
    });
    setOpen(true);
  }

  function startEdit(m: Model) {
    setEditing(m);
    setForm({
      brandId: String(m.brandId),
      name: m.name,
      bodyType: m.bodyType ?? "",
      yearStart: m.yearStart != null ? String(m.yearStart) : "",
      yearEnd: m.yearEnd != null ? String(m.yearEnd) : "",
      notes: m.notes ?? "",
    });
    setOpen(true);
  }

  async function submit() {
    setBusy(true);
    list.setError(null);
    try {
      const wid = Number(form.brandId);
      if (!Number.isFinite(wid)) {
        list.setError("Marka seçin.");
        setBusy(false);
        return;
      }
      const body = {
        brandId: wid,
        name: form.name.trim(),
        bodyType: form.bodyType.trim() || null,
        yearStart: form.yearStart ? Number(form.yearStart) : null,
        yearEnd: form.yearEnd ? Number(form.yearEnd) : null,
        notes: form.notes.trim() || null,
      };
      if (editing) {
        await sendJson<Model>(`/api/v1/models/${editing.id}`, "PATCH", body);
      } else {
        await sendJson<Model>("/api/v1/models", "POST", body);
      }
      setOpen(false);
      await list.refresh();
    } catch (e) {
      list.setError(e instanceof Error ? e.message : "Kayıt başarısız");
    } finally {
      setBusy(false);
    }
  }

  async function confirmDelete() {
    if (!deleteTarget) return;
    setBusy(true);
    try {
      await sendJson(`/api/v1/models/${deleteTarget.id}`, "DELETE");
      setDeleteTarget(null);
      await list.refresh();
    } catch (e) {
      list.setError(e instanceof Error ? e.message : "Silinemedi");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="mx-auto max-w-6xl space-y-6 p-6">
      <header className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Modeller</h1>
          <p className="text-muted-foreground text-sm">
            Markaya bağlı model kataloğu.
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => void list.refresh()}>
            <RefreshCcw className="size-4" /> Yenile
          </Button>
          <Button
            onClick={startAdd}
            disabled={brands.data.length === 0 && !brands.loading}
          >
            <Plus className="size-4" /> Model ekle
          </Button>
        </div>
      </header>

      {brands.data.length === 0 && !brands.loading ? (
        <p className="text-muted-foreground border-border rounded-lg border border-dashed p-4 text-sm">
          Önce en az bir marka ekleyin; modeller markaya bağlıdır.
        </p>
      ) : null}

      <div className="flex flex-wrap items-center gap-3">
        <Label htmlFor="filterBrand" className="text-xs uppercase tracking-wide text-muted-foreground">
          Marka filtresi
        </Label>
        <Select
          id="filterBrand"
          value={filterBrandId}
          onChange={(e) => setFilterBrandId(e.target.value)}
          className="max-w-xs"
        >
          <option value="">Tümü</option>
          {brands.data.map((b) => (
            <option key={b.id} value={b.id}>
              {b.name}
            </option>
          ))}
        </Select>
      </div>

      {list.error ? (
        <div className="border-destructive/30 bg-destructive/5 text-destructive rounded-lg border p-4 text-sm">
          {list.error}
        </div>
      ) : null}

      <div className="border-border rounded-xl border">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead className="w-14">ID</TableHead>
              <TableHead className="w-12">Logo</TableHead>
              <TableHead>Marka</TableHead>
              <TableHead>Model</TableHead>
              <TableHead>Gövde</TableHead>
              <TableHead>Yıl aralığı</TableHead>
              <TableHead className="w-32 text-right">İşlem</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {list.loading ? (
              <TableRow>
                <TableCell colSpan={7} className="text-muted-foreground h-24 text-center">
                  Yükleniyor…
                </TableCell>
              </TableRow>
            ) : visible.length === 0 ? (
              <TableRow>
                <TableCell colSpan={7} className="text-muted-foreground h-24 text-center">
                  Model yok.
                </TableCell>
              </TableRow>
            ) : (
              visible.map((m) => {
                const b = brandMap.get(m.brandId);
                return (
                  <TableRow key={m.id}>
                    <TableCell className="font-mono text-xs">{m.id}</TableCell>
                    <TableCell>
                      {b?.logoUrl ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img
                          src={assetUrl(b.logoUrl) ?? undefined}
                          alt=""
                          className="bg-muted size-8 rounded-md border border-border object-contain"
                        />
                      ) : (
                        <span className="bg-muted text-muted-foreground flex size-8 items-center justify-center rounded-md text-[10px]">—</span>
                      )}
                    </TableCell>
                    <TableCell className="text-sm">{b?.name ?? `#${m.brandId}`}</TableCell>
                    <TableCell className="font-medium">{m.name}</TableCell>
                    <TableCell className="text-sm text-muted-foreground">
                      {m.bodyType ?? "—"}
                    </TableCell>
                    <TableCell className="text-xs text-muted-foreground">
                      {(m.yearStart ?? "—") + " → " + (m.yearEnd ?? "—")}
                    </TableCell>
                    <TableCell className="text-right">
                      <Button variant="ghost" size="sm" onClick={() => startEdit(m)} aria-label="Düzenle">
                        <Pencil className="size-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="text-destructive hover:text-destructive"
                        onClick={() => setDeleteTarget(m)}
                        aria-label="Sil"
                      >
                        <Trash2 className="size-4" />
                      </Button>
                    </TableCell>
                  </TableRow>
                );
              })
            )}
          </TableBody>
        </Table>
      </div>

      <Modal
        open={open}
        onClose={() => setOpen(false)}
        title={editing ? "Modeli düzenle" : "Yeni model"}
        size="lg"
        footer={
          <>
            <Button variant="outline" onClick={() => setOpen(false)}>İptal</Button>
            <Button onClick={() => void submit()} disabled={busy}>
              {busy ? "Kaydediliyor…" : "Kaydet"}
            </Button>
          </>
        }
      >
        <div className="grid gap-4">
          <div className="grid gap-2">
            <Label htmlFor="brandId">Marka</Label>
            <Select
              id="brandId"
              value={form.brandId}
              onChange={(e) => setForm((f) => ({ ...f, brandId: e.target.value }))}
            >
              <option value="">— Seçin —</option>
              {brands.data.map((b) => (
                <option key={b.id} value={b.id}>{b.name}</option>
              ))}
            </Select>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-2">
              <Label htmlFor="name">Model adı</Label>
              <Input
                id="name"
                value={form.name}
                onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
                placeholder="320i, Polo, Civic..."
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="bodyType">Gövde</Label>
              <Select
                id="bodyType"
                value={form.bodyType}
                onChange={(e) => setForm((f) => ({ ...f, bodyType: e.target.value }))}
              >
                <option value="">—</option>
                {BODY_TYPES.map((b) => (
                  <option key={b} value={b}>{b}</option>
                ))}
              </Select>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-2">
              <Label htmlFor="yearStart">Üretim başı</Label>
              <Input
                id="yearStart"
                type="number"
                value={form.yearStart}
                onChange={(e) => setForm((f) => ({ ...f, yearStart: e.target.value }))}
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="yearEnd">Üretim sonu (boş = üretimde)</Label>
              <Input
                id="yearEnd"
                type="number"
                value={form.yearEnd}
                onChange={(e) => setForm((f) => ({ ...f, yearEnd: e.target.value }))}
              />
            </div>
          </div>
          <div className="grid gap-2">
            <Label htmlFor="notes">Notlar</Label>
            <Textarea
              id="notes"
              rows={3}
              value={form.notes}
              onChange={(e) => setForm((f) => ({ ...f, notes: e.target.value }))}
            />
          </div>
        </div>
      </Modal>

      <ConfirmDialog
        open={deleteTarget != null}
        onClose={() => setDeleteTarget(null)}
        onConfirm={() => void confirmDelete()}
        title="Modeli sil"
        description={deleteTarget ? `"${deleteTarget.name}" silinsin mi?` : ""}
        confirmLabel="Sil"
        busy={busy}
      />
    </div>
  );
}
