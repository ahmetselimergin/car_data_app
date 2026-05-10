"use client";

import { ArrowLeft, Pencil, Plus, RefreshCcw, Trash2 } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback, useEffect, useMemo, useState } from "react";

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
import {
  apiUrl,
  assetUrl,
  FIREBASE_ROLES,
  readError,
  type Brand,
  type Car,
  type FirebaseRole,
  type FirebaseUser,
} from "@/lib/api";
import { sendJson, useList } from "@/lib/use-list";

type CarFormState = {
  plaka: string;
  brandId: string;
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

const EMPTY_CAR: CarFormState = {
  plaka: "",
  brandId: "",
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

function readRole(u: FirebaseUser | null): FirebaseRole | null {
  const r = u?.customClaims?.role;
  if (
    typeof r === "string" &&
    (FIREBASE_ROLES as readonly { value: string }[]).some((x) => x.value === r)
  ) {
    return r as FirebaseRole;
  }
  return null;
}

export default function FirebaseUserDetailPage() {
  const params = useParams<{ uid: string }>();
  const uid = params.uid;

  const [user, setUser] = useState<FirebaseUser | null>(null);
  const [userLoading, setUserLoading] = useState(true);
  const [userError, setUserError] = useState<string | null>(null);

  const brands = useList<Brand>("/api/v1/brands");

  const [cars, setCars] = useState<Car[]>([]);
  const [carsLoading, setCarsLoading] = useState(true);
  const [carsError, setCarsError] = useState<string | null>(null);

  const [carDialog, setCarDialog] = useState(false);
  const [editingCar, setEditingCar] = useState<Car | null>(null);
  const [carForm, setCarForm] = useState<CarFormState>(EMPTY_CAR);
  const [deleteCarTarget, setDeleteCarTarget] = useState<Car | null>(null);
  const [busy, setBusy] = useState(false);

  const role = readRole(user);

  const loadUser = useCallback(async () => {
    setUserLoading(true);
    setUserError(null);
    try {
      const res = await fetch(apiUrl(`/api/v1/firebase-users/${uid}`), {
        cache: "no-store",
      });
      if (!res.ok) {
        setUserError(await readError(res));
        return;
      }
      setUser((await res.json()) as FirebaseUser);
    } catch (e) {
      setUserError(e instanceof Error ? e.message : "Hata");
    } finally {
      setUserLoading(false);
    }
  }, [uid]);

  const loadCars = useCallback(async () => {
    setCarsLoading(true);
    setCarsError(null);
    try {
      const res = await fetch(
        apiUrl(`/api/v1/cars?firebaseUid=${encodeURIComponent(uid)}`),
        { cache: "no-store" },
      );
      if (!res.ok) {
        setCarsError(await readError(res));
        setCars([]);
        return;
      }
      const j = (await res.json()) as Car[];
      setCars(Array.isArray(j) ? j : []);
    } catch (e) {
      setCarsError(e instanceof Error ? e.message : "Hata");
    } finally {
      setCarsLoading(false);
    }
  }, [uid]);

  useEffect(() => {
    if (uid) {
      void loadUser();
      void loadCars();
    }
  }, [uid, loadUser, loadCars]);

  const brandMap = useMemo(() => {
    const m = new Map<number, Brand>();
    for (const b of brands.data) m.set(b.id, b);
    return m;
  }, [brands.data]);

  function startAddCar() {
    setEditingCar(null);
    setCarForm(EMPTY_CAR);
    setCarDialog(true);
  }

  function startEditCar(c: Car) {
    setEditingCar(c);
    setCarForm({
      plaka: c.plaka,
      brandId: c.brandId != null ? String(c.brandId) : "",
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
    setCarDialog(true);
  }

  async function submitCar() {
    setBusy(true);
    setCarsError(null);
    try {
      const body = {
        plaka: carForm.plaka.trim(),
        marka: carForm.marka.trim(),
        model: carForm.model.trim(),
        yil: Number(carForm.yil),
        km: Math.max(0, Number(carForm.km) || 0),
        transmission: carForm.transmission.trim() || null,
        fuelType: carForm.fuelType.trim() || null,
        color: carForm.color.trim() || null,
        imageUrl: carForm.imageUrl.trim() || null,
        notes: carForm.notes.trim() || null,
        brandId: carForm.brandId ? Number(carForm.brandId) : null,
        firebaseUid: uid,
      };
      if (editingCar) {
        await sendJson<Car>(`/api/v1/cars/${editingCar.id}`, "PATCH", body);
      } else {
        await sendJson<Car>("/api/v1/cars", "POST", body);
      }
      setCarDialog(false);
      await loadCars();
    } catch (e) {
      setCarsError(e instanceof Error ? e.message : "Hata");
    } finally {
      setBusy(false);
    }
  }

  async function confirmDeleteCar() {
    if (!deleteCarTarget) return;
    setBusy(true);
    try {
      await sendJson(`/api/v1/cars/${deleteCarTarget.id}`, "DELETE");
      setDeleteCarTarget(null);
      await loadCars();
    } catch (e) {
      setCarsError(e instanceof Error ? e.message : "Hata");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="mx-auto max-w-6xl space-y-6 p-6">
      <Link
        href="/firebase-users"
        className="text-muted-foreground hover:text-foreground inline-flex items-center gap-1.5 text-sm"
      >
        <ArrowLeft className="size-4" /> Kullanıcılara dön
      </Link>

      {userError ? (
        <div className="border-destructive/30 bg-destructive/5 text-destructive rounded-lg border p-4 text-sm">
          {userError}
        </div>
      ) : null}

      <section className="bg-card border-border rounded-xl border p-5">
        {userLoading || !user ? (
          <p className="text-muted-foreground text-sm">Yükleniyor…</p>
        ) : (
          <div className="flex flex-wrap items-start gap-4">
            {user.photoURL ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={user.photoURL}
                alt=""
                className="bg-muted border-border size-16 shrink-0 rounded-full border object-cover"
              />
            ) : (
              <span className="bg-muted text-muted-foreground flex size-16 shrink-0 items-center justify-center rounded-full text-lg font-semibold">
                {(user.displayName ?? user.email ?? "?")
                  .slice(0, 1)
                  .toUpperCase()}
              </span>
            )}
            <div className="min-w-0 flex-1 space-y-2">
              <div className="flex flex-wrap items-center gap-2">
                <h1 className="text-2xl font-bold tracking-tight">
                  {user.displayName ?? user.email ?? user.uid}
                </h1>
                {role ? (
                  <Badge variant={role === "admin" ? "default" : "outline"}>
                    {FIREBASE_ROLES.find((r) => r.value === role)?.label}
                  </Badge>
                ) : null}
                {user.disabled ? (
                  <Badge variant="muted">Devredışı</Badge>
                ) : (
                  <Badge variant="success">Aktif</Badge>
                )}
                {user.emailVerified ? (
                  <Badge
                    variant="outline"
                    className="text-emerald-700 dark:text-emerald-300"
                  >
                    Onaylı
                  </Badge>
                ) : user.email ? (
                  <Badge variant="warning">Onaysız</Badge>
                ) : null}
              </div>
              <dl className="grid gap-x-6 gap-y-1 text-sm sm:grid-cols-2">
                <div className="flex gap-2">
                  <dt className="text-muted-foreground w-20">UID</dt>
                  <dd className="font-mono text-xs">{user.uid}</dd>
                </div>
                <div className="flex gap-2">
                  <dt className="text-muted-foreground w-20">E-posta</dt>
                  <dd>{user.email ?? "—"}</dd>
                </div>
                <div className="flex gap-2">
                  <dt className="text-muted-foreground w-20">Telefon</dt>
                  <dd>{user.phoneNumber ?? "—"}</dd>
                </div>
                <div className="flex gap-2">
                  <dt className="text-muted-foreground w-20">Sağlayıcı</dt>
                  <dd>
                    {user.providers.length === 0
                      ? "—"
                      : user.providers
                          .map((p) => p.providerId.replace(".com", ""))
                          .join(", ")}
                  </dd>
                </div>
                <div className="flex gap-2">
                  <dt className="text-muted-foreground w-20">Kayıt</dt>
                  <dd>
                    {new Date(user.metadata.createdAt).toLocaleString("tr-TR")}
                  </dd>
                </div>
                <div className="flex gap-2">
                  <dt className="text-muted-foreground w-20">Son giriş</dt>
                  <dd>
                    {user.metadata.lastSignInAt
                      ? new Date(user.metadata.lastSignInAt).toLocaleString("tr-TR")
                      : "—"}
                  </dd>
                </div>
              </dl>
            </div>
          </div>
        )}
      </section>

      <section className="space-y-4">
        <div className="flex flex-wrap items-end justify-between gap-3">
          <div>
            <h2 className="text-lg font-semibold tracking-tight">Araçlar</h2>
            <p className="text-muted-foreground text-sm">
              Bu Firebase kullanıcısına atanmış araçlar.
            </p>
          </div>
          <div className="flex gap-2">
            <Button variant="outline" onClick={() => void loadCars()}>
              <RefreshCcw className="size-4" /> Yenile
            </Button>
            <Button onClick={startAddCar}>
              <Plus className="size-4" /> Araç ekle
            </Button>
          </div>
        </div>

        {carsError ? (
          <div className="border-destructive/30 bg-destructive/5 text-destructive rounded-lg border p-4 text-sm">
            {carsError}
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
                <TableHead className="w-32 text-right">İşlem</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {carsLoading ? (
                <TableRow>
                  <TableCell
                    colSpan={7}
                    className="text-muted-foreground h-24 text-center"
                  >
                    Yükleniyor…
                  </TableCell>
                </TableRow>
              ) : cars.length === 0 ? (
                <TableRow>
                  <TableCell
                    colSpan={7}
                    className="text-muted-foreground h-24 text-center"
                  >
                    Bu kullanıcının aracı yok.
                  </TableCell>
                </TableRow>
              ) : (
                cars.map((c) => {
                  const b = c.brandId != null ? brandMap.get(c.brandId) : null;
                  const logo = b?.logoUrl ? assetUrl(b.logoUrl) : null;
                  return (
                    <TableRow key={c.id}>
                      <TableCell>
                        {logo ? (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img
                            src={logo}
                            alt=""
                            className="bg-muted border-border size-8 rounded-md border object-contain"
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
                      <TableCell className="text-right">
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => startEditCar(c)}
                          aria-label="Düzenle"
                        >
                          <Pencil className="size-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          className="text-destructive hover:text-destructive"
                          onClick={() => setDeleteCarTarget(c)}
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
      </section>

      <Modal
        open={carDialog}
        onClose={() => setCarDialog(false)}
        title={editingCar ? "Aracı düzenle" : "Yeni araç"}
        size="lg"
        footer={
          <>
            <Button variant="outline" onClick={() => setCarDialog(false)}>
              İptal
            </Button>
            <Button onClick={() => void submitCar()} disabled={busy}>
              {busy ? "Kaydediliyor…" : "Kaydet"}
            </Button>
          </>
        }
      >
        <div className="grid gap-4">
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-2">
              <Label htmlFor="plaka">Plaka</Label>
              <Input
                id="plaka"
                value={carForm.plaka}
                onChange={(e) =>
                  setCarForm((f) => ({ ...f, plaka: e.target.value }))
                }
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="brandId">Marka (logo)</Label>
              <Select
                id="brandId"
                value={carForm.brandId}
                onChange={(e) =>
                  setCarForm((f) => ({ ...f, brandId: e.target.value }))
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
                value={carForm.marka}
                onChange={(e) =>
                  setCarForm((f) => ({ ...f, marka: e.target.value }))
                }
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="model">Model</Label>
              <Input
                id="model"
                value={carForm.model}
                onChange={(e) =>
                  setCarForm((f) => ({ ...f, model: e.target.value }))
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
                value={carForm.yil}
                onChange={(e) =>
                  setCarForm((f) => ({ ...f, yil: e.target.value }))
                }
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="km">Km</Label>
              <Input
                id="km"
                type="number"
                value={carForm.km}
                onChange={(e) =>
                  setCarForm((f) => ({ ...f, km: e.target.value }))
                }
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="color">Renk</Label>
              <Input
                id="color"
                value={carForm.color}
                onChange={(e) =>
                  setCarForm((f) => ({ ...f, color: e.target.value }))
                }
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-2">
              <Label htmlFor="transmission">Vites</Label>
              <Input
                id="transmission"
                value={carForm.transmission}
                onChange={(e) =>
                  setCarForm((f) => ({ ...f, transmission: e.target.value }))
                }
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="fuelType">Yakıt</Label>
              <Input
                id="fuelType"
                value={carForm.fuelType}
                onChange={(e) =>
                  setCarForm((f) => ({ ...f, fuelType: e.target.value }))
                }
              />
            </div>
          </div>
          <div className="grid gap-2">
            <Label htmlFor="imageUrl">Görsel URL</Label>
            <Input
              id="imageUrl"
              value={carForm.imageUrl}
              onChange={(e) =>
                setCarForm((f) => ({ ...f, imageUrl: e.target.value }))
              }
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="notes">Notlar</Label>
            <Textarea
              id="notes"
              rows={3}
              value={carForm.notes}
              onChange={(e) =>
                setCarForm((f) => ({ ...f, notes: e.target.value }))
              }
            />
          </div>
        </div>
      </Modal>

      <ConfirmDialog
        open={deleteCarTarget != null}
        onClose={() => setDeleteCarTarget(null)}
        onConfirm={() => void confirmDeleteCar()}
        title="Aracı sil"
        description={
          deleteCarTarget ? `${deleteCarTarget.plaka} silinsin mi?` : ""
        }
        confirmLabel="Sil"
        busy={busy}
      />
    </div>
  );
}
