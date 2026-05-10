"use client";

import { ImagePlus, Pencil, Plus, RefreshCcw, Trash2, X } from "lucide-react";
import { useEffect, useRef, useState } from "react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ConfirmDialog, Modal } from "@/components/ui/modal";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { assetUrl, type Brand } from "@/lib/api";
import { sendForm, sendJson, useList } from "@/lib/use-list";
import { cn } from "@/lib/utils";

type FormState = {
  slug: string;
  name: string;
  sortOrder: string;
};

const EMPTY: FormState = { slug: "", name: "", sortOrder: "0" };

export default function BrandsPage() {
  const { data, loading, error, refresh, setError } = useList<Brand>(
    "/api/v1/brands",
  );

  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<Brand | null>(null);
  const [form, setForm] = useState<FormState>(EMPTY);

  const [logoFile, setLogoFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [removeLogo, setRemoveLogo] = useState(false);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  const [deleteTarget, setDeleteTarget] = useState<Brand | null>(null);
  const [busy, setBusy] = useState(false);

  // Seçilen dosya için önizleme URL'i (object URL)
  useEffect(() => {
    if (!logoFile) {
      setPreviewUrl(null);
      return;
    }
    const url = URL.createObjectURL(logoFile);
    setPreviewUrl(url);
    return () => URL.revokeObjectURL(url);
  }, [logoFile]);

  function resetFile() {
    setLogoFile(null);
    setRemoveLogo(false);
    if (fileInputRef.current) fileInputRef.current.value = "";
  }

  function startAdd() {
    setEditing(null);
    setForm(EMPTY);
    resetFile();
    setOpen(true);
  }

  function startEdit(b: Brand) {
    setEditing(b);
    setForm({
      slug: b.slug,
      name: b.name,
      sortOrder: String(b.sortOrder ?? 0),
    });
    resetFile();
    setOpen(true);
  }

  async function submit() {
    setBusy(true);
    setError(null);
    try {
      const fd = new FormData();
      fd.append("slug", form.slug.trim());
      fd.append("name", form.name.trim());
      fd.append("sortOrder", String(Number(form.sortOrder) || 0));
      if (logoFile) fd.append("logo", logoFile);
      if (!logoFile && removeLogo) fd.append("removeLogo", "1");
      if (editing) {
        await sendForm<Brand>(`/api/v1/brands/${editing.id}`, "PATCH", fd);
      } else {
        await sendForm<Brand>("/api/v1/brands", "POST", fd);
      }
      setOpen(false);
      await refresh();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Kayıt başarısız");
    } finally {
      setBusy(false);
    }
  }

  async function confirmDelete() {
    if (!deleteTarget) return;
    setBusy(true);
    try {
      await sendJson(`/api/v1/brands/${deleteTarget.id}`, "DELETE");
      setDeleteTarget(null);
      await refresh();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Silinemedi");
    } finally {
      setBusy(false);
    }
  }

  // Modal'da gösterilecek logo: yeni dosya seçildi mi → preview; yoksa mevcut + "kaldır" değil → mevcut
  const modalLogo = previewUrl
    ? previewUrl
    : editing && !removeLogo
      ? assetUrl(editing.logoUrl)
      : null;

  return (
    <div className="mx-auto max-w-5xl space-y-6 p-6">
      <header className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Markalar</h1>
          <p className="text-muted-foreground text-sm">
            Slug, görünen ad ve logo dosyası.
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => void refresh()}>
            <RefreshCcw className="size-4" /> Yenile
          </Button>
          <Button onClick={startAdd}>
            <Plus className="size-4" /> Marka ekle
          </Button>
        </div>
      </header>

      {error ? (
        <div className="border-destructive/30 bg-destructive/5 text-destructive rounded-lg border p-4 text-sm">
          {error}
        </div>
      ) : null}

      <div className="border-border rounded-xl border">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead className="w-16">Logo</TableHead>
              <TableHead>Slug</TableHead>
              <TableHead>Ad</TableHead>
              <TableHead className="w-24">Sıra</TableHead>
              <TableHead className="w-40 text-right">İşlem</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell
                  colSpan={5}
                  className="text-muted-foreground h-24 text-center"
                >
                  Yükleniyor…
                </TableCell>
              </TableRow>
            ) : data.length === 0 ? (
              <TableRow>
                <TableCell
                  colSpan={5}
                  className="text-muted-foreground h-24 text-center"
                >
                  Marka yok. Logo dosyası ile ekleyebilirsiniz.
                </TableCell>
              </TableRow>
            ) : (
              data.map((b) => {
                const url = assetUrl(b.logoUrl);
                return (
                  <TableRow key={b.id}>
                    <TableCell>
                      {url ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img
                          src={url}
                          alt=""
                          className="bg-muted border-border size-10 rounded-md border object-contain"
                        />
                      ) : (
                        <span className="text-muted-foreground text-xs">—</span>
                      )}
                    </TableCell>
                    <TableCell className="font-mono text-sm">
                      {b.slug}
                    </TableCell>
                    <TableCell className="font-medium">{b.name}</TableCell>
                    <TableCell>{b.sortOrder}</TableCell>
                    <TableCell className="text-right">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => startEdit(b)}
                        aria-label="Düzenle"
                      >
                        <Pencil className="size-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="text-destructive hover:text-destructive"
                        onClick={() => setDeleteTarget(b)}
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
        title={editing ? "Markayı düzenle" : "Yeni marka"}
        description="Logo PNG/JPG/WEBP/SVG, en fazla 5 MB."
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
            <Label>Logo</Label>
            <div className="flex items-start gap-4">
              <div className="bg-muted border-border flex size-20 shrink-0 items-center justify-center overflow-hidden rounded-md border">
                {modalLogo ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={modalLogo}
                    alt=""
                    className="max-h-full max-w-full object-contain"
                  />
                ) : (
                  <ImagePlus className="text-muted-foreground size-7" />
                )}
              </div>
              <div className="flex flex-1 flex-col gap-2">
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/png,image/jpeg,image/webp,image/svg+xml"
                  onChange={(e) => {
                    const f = e.target.files?.[0] ?? null;
                    setLogoFile(f);
                    if (f) setRemoveLogo(false);
                  }}
                  className="text-sm file:mr-3 file:rounded-md file:border-0 file:bg-primary file:px-3 file:py-1.5 file:text-xs file:font-medium file:text-primary-foreground hover:file:opacity-90"
                />
                <div className="flex flex-wrap gap-2">
                  {logoFile ? (
                    <button
                      type="button"
                      onClick={() => {
                        setLogoFile(null);
                        if (fileInputRef.current)
                          fileInputRef.current.value = "";
                      }}
                      className={cn(
                        "border-border hover:bg-accent inline-flex h-7 items-center gap-1 rounded-md border px-2 text-xs",
                      )}
                    >
                      <X className="size-3" /> Seçimi temizle
                    </button>
                  ) : null}
                  {editing && editing.logoUrl && !logoFile ? (
                    <label className="text-muted-foreground inline-flex cursor-pointer items-center gap-1.5 text-xs">
                      <input
                        type="checkbox"
                        checked={removeLogo}
                        onChange={(e) => setRemoveLogo(e.target.checked)}
                      />
                      Mevcut logoyu kaldır
                    </label>
                  ) : null}
                </div>
              </div>
            </div>
          </div>
          <div className="grid gap-2">
            <Label htmlFor="slug">Slug</Label>
            <Input
              id="slug"
              value={form.slug}
              onChange={(e) =>
                setForm((f) => ({ ...f, slug: e.target.value }))
              }
              placeholder="bmw"
            />
            <p className="text-muted-foreground text-xs">
              Otomatik normalize edilir (küçük harf + tire).
            </p>
          </div>
          <div className="grid gap-2">
            <Label htmlFor="name">Görünen ad</Label>
            <Input
              id="name"
              value={form.name}
              onChange={(e) =>
                setForm((f) => ({ ...f, name: e.target.value }))
              }
              placeholder="BMW"
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="sortOrder">Liste sırası</Label>
            <Input
              id="sortOrder"
              type="number"
              value={form.sortOrder}
              onChange={(e) =>
                setForm((f) => ({ ...f, sortOrder: e.target.value }))
              }
            />
          </div>
        </div>
      </Modal>

      <ConfirmDialog
        open={deleteTarget != null}
        onClose={() => setDeleteTarget(null)}
        onConfirm={() => void confirmDelete()}
        title="Markayı sil"
        description={
          deleteTarget
            ? `"${deleteTarget.name}" silinsin mi? Bu markaya bağlı araçlardaki logo bağlantısı kalkar.`
            : ""
        }
        confirmLabel="Sil"
        busy={busy}
      />
    </div>
  );
}
