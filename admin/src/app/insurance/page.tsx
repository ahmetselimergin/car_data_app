"use client";

import { Pencil, Plus, RefreshCcw, Trash2 } from "lucide-react";
import { useState } from "react";

import { Badge } from "@/components/ui/badge";
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
import { INSURANCE_TYPES, type InsuranceCompany } from "@/lib/api";
import { sendJson, useList } from "@/lib/use-list";

type FormState = {
  name: string;
  type: InsuranceCompany["type"];
  phone: string;
  email: string;
  website: string;
  address: string;
  notes: string;
  active: boolean;
};

const EMPTY: FormState = {
  name: "",
  type: "both",
  phone: "",
  email: "",
  website: "",
  address: "",
  notes: "",
  active: true,
};

export default function InsurancePage() {
  const { data, loading, error, refresh, setError } =
    useList<InsuranceCompany>("/api/v1/insurance");

  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<InsuranceCompany | null>(null);
  const [form, setForm] = useState<FormState>(EMPTY);
  const [deleteTarget, setDeleteTarget] = useState<InsuranceCompany | null>(null);
  const [busy, setBusy] = useState(false);

  function startAdd() {
    setEditing(null);
    setForm(EMPTY);
    setOpen(true);
  }

  function startEdit(c: InsuranceCompany) {
    setEditing(c);
    setForm({
      name: c.name,
      type: c.type,
      phone: c.phone ?? "",
      email: c.email ?? "",
      website: c.website ?? "",
      address: c.address ?? "",
      notes: c.notes ?? "",
      active: c.active,
    });
    setOpen(true);
  }

  async function submit() {
    setBusy(true);
    setError(null);
    try {
      const body = {
        name: form.name.trim(),
        type: form.type,
        phone: form.phone.trim() || null,
        email: form.email.trim() || null,
        website: form.website.trim() || null,
        address: form.address.trim() || null,
        notes: form.notes.trim() || null,
        active: form.active,
      };
      if (editing) {
        await sendJson<InsuranceCompany>(`/api/v1/insurance/${editing.id}`, "PATCH", body);
      } else {
        await sendJson<InsuranceCompany>("/api/v1/insurance", "POST", body);
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
      await sendJson(`/api/v1/insurance/${deleteTarget.id}`, "DELETE");
      setDeleteTarget(null);
      await refresh();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Silinemedi");
    } finally {
      setBusy(false);
    }
  }

  function typeLabel(t: InsuranceCompany["type"]) {
    return INSURANCE_TYPES.find((x) => x.value === t)?.label ?? t;
  }

  return (
    <div className="mx-auto max-w-6xl space-y-6 p-6">
      <header className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Sigorta & Kasko</h1>
          <p className="text-muted-foreground text-sm">
            Anlaşmalı sigorta şirketleri ve iletişim bilgileri.
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => void refresh()}>
            <RefreshCcw className="size-4" /> Yenile
          </Button>
          <Button onClick={startAdd}>
            <Plus className="size-4" /> Şirket ekle
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
              <TableHead className="w-14">ID</TableHead>
              <TableHead>Ad</TableHead>
              <TableHead>Tür</TableHead>
              <TableHead>Telefon</TableHead>
              <TableHead>E-posta</TableHead>
              <TableHead>Durum</TableHead>
              <TableHead className="w-32 text-right">İşlem</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={7} className="text-muted-foreground h-24 text-center">Yükleniyor…</TableCell>
              </TableRow>
            ) : data.length === 0 ? (
              <TableRow>
                <TableCell colSpan={7} className="text-muted-foreground h-24 text-center">Kayıt yok.</TableCell>
              </TableRow>
            ) : (
              data.map((c) => (
                <TableRow key={c.id}>
                  <TableCell className="font-mono text-xs">{c.id}</TableCell>
                  <TableCell className="font-medium">{c.name}</TableCell>
                  <TableCell>
                    <Badge variant="outline">{typeLabel(c.type)}</Badge>
                  </TableCell>
                  <TableCell className="text-muted-foreground text-sm">{c.phone ?? "—"}</TableCell>
                  <TableCell className="text-muted-foreground text-sm">{c.email ?? "—"}</TableCell>
                  <TableCell>
                    {c.active ? (
                      <Badge variant="success">Aktif</Badge>
                    ) : (
                      <Badge variant="muted">Pasif</Badge>
                    )}
                  </TableCell>
                  <TableCell className="text-right">
                    <Button variant="ghost" size="sm" onClick={() => startEdit(c)} aria-label="Düzenle">
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
        title={editing ? "Şirketi düzenle" : "Yeni şirket"}
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
          <div className="grid grid-cols-3 gap-3">
            <div className="col-span-2 grid gap-2">
              <Label htmlFor="name">Ad</Label>
              <Input
                id="name"
                value={form.name}
                onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="type">Tür</Label>
              <Select
                id="type"
                value={form.type}
                onChange={(e) =>
                  setForm((f) => ({
                    ...f,
                    type: e.target.value as InsuranceCompany["type"],
                  }))
                }
              >
                {INSURANCE_TYPES.map((t) => (
                  <option key={t.value} value={t.value}>{t.label}</option>
                ))}
              </Select>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-2">
              <Label htmlFor="phone">Telefon</Label>
              <Input
                id="phone"
                value={form.phone}
                onChange={(e) => setForm((f) => ({ ...f, phone: e.target.value }))}
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="email">E-posta</Label>
              <Input
                id="email"
                type="email"
                value={form.email}
                onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
              />
            </div>
          </div>
          <div className="grid gap-2">
            <Label htmlFor="website">Web sitesi</Label>
            <Input
              id="website"
              value={form.website}
              onChange={(e) => setForm((f) => ({ ...f, website: e.target.value }))}
              placeholder="https://..."
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="address">Adres</Label>
            <Textarea
              id="address"
              rows={2}
              value={form.address}
              onChange={(e) => setForm((f) => ({ ...f, address: e.target.value }))}
            />
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
          <label className="flex cursor-pointer items-center gap-2 text-sm">
            <input
              type="checkbox"
              checked={form.active}
              onChange={(e) => setForm((f) => ({ ...f, active: e.target.checked }))}
            />
            Aktif
          </label>
        </div>
      </Modal>

      <ConfirmDialog
        open={deleteTarget != null}
        onClose={() => setDeleteTarget(null)}
        onConfirm={() => void confirmDelete()}
        title="Şirketi sil"
        description={deleteTarget ? `"${deleteTarget.name}" silinsin mi?` : ""}
        confirmLabel="Sil"
        busy={busy}
      />
    </div>
  );
}
