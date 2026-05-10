"use client";

import { Pencil, Plus, RefreshCcw, Trash2 } from "lucide-react";
import { useEffect, useState } from "react";

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
import {
  apiUrl,
  assetUrl,
  readError,
  type Brand,
  type Car,
  type FirebaseListResponse,
  type FirebaseUser,
} from "@/lib/api";
import { sendJson, useList } from "@/lib/use-list";

type FormState = {
  plaka: string;
  brandId: string;
  firebaseUid: string;
  marka: string;
  model: string;
  yil: string;
  km: string;
  transmission: string;
  fuelType: string;
  color: string;
  imageUrl: string;
  notes: string;
};

const EMPTY: FormState = {
  plaka: "",
  brandId: "",
  firebaseUid: "",
  marka: "",
  model: "",
  yil: String(new Date().getFullYear()),
  km: "0",
  transmission: "",
  fuelType: "",
  color: "",
  imageUrl: "",
  notes: "",
};

export default function CarsPage() {
  const cars = useList<Car>("/api/v1/cars");
  const brands = useList<Brand>("/api/v1/brands");
  const [fbUsers, setFbUsers] = useState<FirebaseUser[]>([]);

  useEffect(() => {
    void (async () => {
      try {
        const res = await fetch(apiUrl("/api/v1/firebase-users?limit=1000"), {
          cache: "no-store",
        });
        if (!res.ok) {
          if (res.status !== 503) {
            cars.setError(await readError(res));
          }
          return;
        }
        const j = (await res.json()) as FirebaseListResponse;
        setFbUsers(j.users);
      } catch {
        /* sessizce */
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps -- yalnızca mount'ta çek
  }, []);

  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<Car | null>(null);
  const [form, setForm] = useState<FormState>(EMPTY);
  const [deleteTarget, setDeleteTarget] = useState<Car | null>(null);
  const [busy, setBusy] = useState(false);

  function startAdd() {
    setEditing(null);
    setForm(EMPTY);
    setOpen(true);
  }

  function startEdit(c: Car) {
    setEditing(c);
    setForm({
      plaka: c.plaka,
      brandId: c.brandId != null ? String(c.brandId) : "",
      firebaseUid: c.firebaseUid ?? "",
      marka: c.marka,
      model: c.model,
      yil: String(c.yil),
      km: String(c.km),
      transmission: c.transmission ?? "",
      fuelType: c.fuelType ?? "",
      color: c.color ?? "",
      imageUrl: c.imageUrl ?? "",
      notes: c.notes ?? "",
    });
    setOpen(true);
  }

  async function submit() {
    setBusy(true);
    cars.setError(null);
    try {
      const body: Record<string, unknown> = {
        plaka: form.plaka.trim(),
        marka: form.marka.trim(),
        model: form.model.trim(),
        yil: Number(form.yil),
        km: Math.max(0, Number(form.km) || 0),
        transmission: form.transmission.trim() || null,
        fuelType: form.fuelType.trim() || null,
        color: form.color.trim() || null,
        imageUrl: form.imageUrl.trim() || null,
        notes: form.notes.trim() || null,
        brandId: form.brandId ? Number(form.brandId) : null,
        firebaseUid: form.firebaseUid || null,
      };
      if (editing) {
        await sendJson<Car>(`/api/v1/cars/${editing.id}`, "PATCH", body);
      } else {
        await sendJson<Car>("/api/v1/cars", "POST", body);
      }
      setOpen(false);
      await cars.refresh();
    } catch (e) {
      cars.setError(e instanceof Error ? e.message : "Kayıt başarısız");
    } finally {
      setBusy(false);
    }
  }

  async function confirmDelete() {
    if (!deleteTarget) return;
    setBusy(true);
    try {
      await sendJson(`/api/v1/cars/${deleteTarget.id}`, "DELETE");
      setDeleteTarget(null);
      await cars.refresh();
    } catch (e) {
      cars.setError(e instanceof Error ? e.message : "Silinemedi");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="mx-auto max-w-6xl space-y-6 p-6">
      <header className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Araçlar</h1>
          <p className="text-muted-foreground text-sm">
            Plaka, marka/model, kilometre ve görsel.
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => void cars.refresh()}>
            <RefreshCcw className="size-4" /> Yenile
          </Button>
          <Button onClick={startAdd}>
            <Plus className="size-4" /> Araç ekle
          </Button>
        </div>
      </header>

      {cars.error ? (
        <div className="border-destructive/30 bg-destructive/5 text-destructive rounded-lg border p-4 text-sm">
          {cars.error}
        </div>
      ) : null}

      <div className="border-border rounded-xl border">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead className="w-12" />
              <TableHead className="w-14">ID</TableHead>
              <TableHead>Plaka</TableHead>
              <TableHead>Marka / Model</TableHead>
              <TableHead className="w-16">Yıl</TableHead>
              <TableHead className="text-right">Km</TableHead>
              <TableHead>Yakıt</TableHead>
              <TableHead className="w-40 text-right">İşlem</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {cars.loading ? (
              <TableRow>
                <TableCell colSpan={8} className="text-muted-foreground h-24 text-center">
                  Yükleniyor…
                </TableCell>
              </TableRow>
            ) : cars.data.length === 0 ? (
              <TableRow>
                <TableCell colSpan={8} className="text-muted-foreground h-24 text-center">
                  Kayıt yok. «Araç ekle» ile başlayın.
                </TableCell>
              </TableRow>
            ) : (
              cars.data.map((c) => (
                <TableRow key={c.id}>
                  <TableCell>
                    {c.brand?.logoUrl ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img
                        src={assetUrl(c.brand.logoUrl) ?? undefined}
                        alt=""
                        className="bg-muted size-8 rounded-md border border-border object-contain"
                      />
                    ) : (
                      <span className="bg-muted text-muted-foreground flex size-8 items-center justify-center rounded-md text-[10px]">
                        —
                      </span>
                    )}
                  </TableCell>
                  <TableCell className="font-mono text-xs">{c.id}</TableCell>
                  <TableCell className="font-medium">{c.plaka}</TableCell>
                  <TableCell>
                    {c.marka} {c.model}
                  </TableCell>
                  <TableCell>{c.yil}</TableCell>
                  <TableCell className="text-right tabular-nums">
                    {c.km.toLocaleString("tr-TR")}
                  </TableCell>
                  <TableCell className="text-muted-foreground text-sm">
                    {c.fuelType ?? "—"}
                  </TableCell>
                  <TableCell className="text-right">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => startEdit(c)}
                      aria-label="Düzenle"
                    >
                      <Pencil className="size-4" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      className="text-destructive hover:text-destructive"
                      onClick={() => setDeleteTarget(c)}
                      aria-label="Sil"
                    >
                      <Trash2 className="size-4" />
                    </Button>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      <Modal
        open={open}
        onClose={() => setOpen(false)}
        title={editing ? "Aracı düzenle" : "Yeni araç"}
        description="Marka kaydı seçilirse satırda logo gösterilir; metin marka/model serbesttir."
        size="lg"
        footer={
          <>
            <Button variant="outline" onClick={() => setOpen(false)}>
              İptal
            </Button>
            <Button onClick={() => void submit()} disabled={busy}>
              {busy ? "Kaydediliyor…" : "Kaydet"}
            </Button>
          </>
        }
      >
        <div className="grid gap-4">
          <div className="grid gap-2">
            <Label htmlFor="firebaseUid">Kullanıcı (sahibi)</Label>
            <Select
              id="firebaseUid"
              value={form.firebaseUid}
              onChange={(e) =>
                setForm((f) => ({ ...f, firebaseUid: e.target.value }))
              }
            >
              <option value="">— Atanmamış —</option>
              {fbUsers.map((u) => (
                <option key={u.uid} value={u.uid}>
                  {(u.displayName ?? u.email ?? u.uid) +
                    (u.email && u.displayName ? ` (${u.email})` : "")}
                </option>
              ))}
            </Select>
            <p className="text-muted-foreground text-xs">
              Firebase Auth'taki kullanıcılar listelenir.
            </p>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-2">
              <Label htmlFor="plaka">Plaka</Label>
              <Input
                id="plaka"
                value={form.plaka}
                onChange={(e) =>
                  setForm((f) => ({ ...f, plaka: e.target.value }))
                }
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="brandId">Marka kaydı (logo)</Label>
              <Select
                id="brandId"
                value={form.brandId}
                onChange={(e) =>
                  setForm((f) => ({ ...f, brandId: e.target.value }))
                }
              >
                <option value="">— Yok —</option>
                {brands.data.map((b) => (
                  <option key={b.id} value={b.id}>
                    {b.name}
                  </option>
                ))}
              </Select>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-2">
              <Label htmlFor="marka">Marka (metin)</Label>
              <Input
                id="marka"
                value={form.marka}
                onChange={(e) =>
                  setForm((f) => ({ ...f, marka: e.target.value }))
                }
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="model">Model</Label>
              <Input
                id="model"
                value={form.model}
                onChange={(e) =>
                  setForm((f) => ({ ...f, model: e.target.value }))
                }
              />
            </div>
          </div>
          <div className="grid grid-cols-3 gap-3">
            <div className="grid gap-2">
              <Label htmlFor="yil">Yıl</Label>
              <Input
                id="yil"
                type="number"
                value={form.yil}
                onChange={(e) =>
                  setForm((f) => ({ ...f, yil: e.target.value }))
                }
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="km">Km</Label>
              <Input
                id="km"
                type="number"
                value={form.km}
                onChange={(e) =>
                  setForm((f) => ({ ...f, km: e.target.value }))
                }
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="color">Renk</Label>
              <Input
                id="color"
                value={form.color}
                onChange={(e) =>
                  setForm((f) => ({ ...f, color: e.target.value }))
                }
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-2">
              <Label htmlFor="transmission">Vites</Label>
              <Input
                id="transmission"
                value={form.transmission}
                onChange={(e) =>
                  setForm((f) => ({ ...f, transmission: e.target.value }))
                }
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="fuelType">Yakıt</Label>
              <Input
                id="fuelType"
                value={form.fuelType}
                onChange={(e) =>
                  setForm((f) => ({ ...f, fuelType: e.target.value }))
                }
              />
            </div>
          </div>
          <div className="grid gap-2">
            <Label htmlFor="imageUrl">Görsel URL</Label>
            <Input
              id="imageUrl"
              value={form.imageUrl}
              onChange={(e) =>
                setForm((f) => ({ ...f, imageUrl: e.target.value }))
              }
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="notes">Notlar</Label>
            <Textarea
              id="notes"
              rows={3}
              value={form.notes}
              onChange={(e) =>
                setForm((f) => ({ ...f, notes: e.target.value }))
              }
            />
          </div>
        </div>
      </Modal>

      <ConfirmDialog
        open={deleteTarget != null}
        onClose={() => setDeleteTarget(null)}
        onConfirm={() => void confirmDelete()}
        title="Aracı sil"
        description={
          deleteTarget ? `${deleteTarget.plaka} kalıcı olarak silinsin mi?` : ""
        }
        confirmLabel="Sil"
        busy={busy}
      />
    </div>
  );
}
