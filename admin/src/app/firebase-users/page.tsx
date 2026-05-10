"use client";

import {
  AlertTriangle,
  ArrowRight,
  Ban,
  Check,
  Copy,
  Key,
  MailCheck,
  Pencil,
  RefreshCcw,
  ShieldCheck,
  ShieldOff,
  Trash2,
  UserCheck,
  X,
} from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";

import {
  ActionMenu,
  type ActionMenuEntry,
} from "@/components/ui/action-menu";
import { Badge } from "@/components/ui/badge";
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
import {
  apiUrl,
  FIREBASE_ROLES,
  readError,
  type FirebaseListResponse,
  type FirebaseRole,
  type FirebaseUser,
} from "@/lib/api";
import { sendJson } from "@/lib/use-list";

function readRole(u: FirebaseUser): FirebaseRole | null {
  const r = u.customClaims?.role;
  if (typeof r === "string" && (FIREBASE_ROLES as readonly { value: string }[]).some((x) => x.value === r)) {
    return r as FirebaseRole;
  }
  return null;
}

function roleLabel(r: FirebaseRole | null): string {
  if (!r) return "—";
  return FIREBASE_ROLES.find((x) => x.value === r)?.label ?? r;
}

type EditState = {
  email: string;
  displayName: string;
  phoneNumber: string;
  password: string;
  emailVerified: boolean;
};

export default function FirebaseUsersPage() {
  const [users, setUsers] = useState<FirebaseUser[]>([]);
  const [pageToken, setPageToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [info, setInfo] = useState<string | null>(null);
  const [enabled, setEnabled] = useState<boolean | null>(null);
  const [search, setSearch] = useState("");

  const [editing, setEditing] = useState<FirebaseUser | null>(null);
  const [editForm, setEditForm] = useState<EditState>({
    email: "",
    displayName: "",
    phoneNumber: "",
    password: "",
    emailVerified: false,
  });
  const [deleteTarget, setDeleteTarget] = useState<FirebaseUser | null>(null);
  const [linkInfo, setLinkInfo] = useState<{
    title: string;
    email: string;
    link: string;
  } | null>(null);
  const [busy, setBusy] = useState(false);

  const checkEnabled = useCallback(async () => {
    try {
      const res = await fetch(apiUrl("/api/v1/firebase-users/status"), {
        cache: "no-store",
      });
      if (res.ok) {
        const j = (await res.json()) as { enabled: boolean };
        setEnabled(j.enabled);
        return j.enabled;
      }
    } catch {
      /* sessizce yut */
    }
    setEnabled(false);
    return false;
  }, []);

  const load = useCallback(
    async (token: string | null = null, append = false) => {
      setLoading(true);
      setError(null);
      try {
        const ok = await checkEnabled();
        if (!ok) {
          setUsers([]);
          setPageToken(null);
          return;
        }
        const url = new URL(apiUrl("/api/v1/firebase-users"));
        url.searchParams.set("limit", "200");
        if (token) url.searchParams.set("pageToken", token);
        const res = await fetch(url.toString(), { cache: "no-store" });
        if (!res.ok) {
          setError(await readError(res));
          if (!append) setUsers([]);
          return;
        }
        const j = (await res.json()) as FirebaseListResponse;
        setUsers((prev) => (append ? [...prev, ...j.users] : j.users));
        setPageToken(j.pageToken);
      } catch (e) {
        setError(e instanceof Error ? e.message : "İstek başarısız");
      } finally {
        setLoading(false);
      }
    },
    [checkEnabled],
  );

  useEffect(() => {
    void load(null, false);
  }, [load]);

  function startEdit(u: FirebaseUser) {
    setEditing(u);
    setEditForm({
      email: u.email ?? "",
      displayName: u.displayName ?? "",
      phoneNumber: u.phoneNumber ?? "",
      password: "",
      emailVerified: u.emailVerified,
    });
  }

  async function submitEdit() {
    if (!editing) return;
    setBusy(true);
    setError(null);
    try {
      const body: Record<string, unknown> = {};
      if (editForm.email.trim() && editForm.email !== (editing.email ?? "")) {
        body.email = editForm.email.trim();
      }
      if (editForm.displayName !== (editing.displayName ?? "")) {
        body.displayName = editForm.displayName.trim() || null;
      }
      if (editForm.phoneNumber !== (editing.phoneNumber ?? "")) {
        body.phoneNumber = editForm.phoneNumber.trim() || null;
      }
      if (editForm.emailVerified !== editing.emailVerified) {
        body.emailVerified = editForm.emailVerified;
      }
      if (editForm.password.length >= 6) {
        body.password = editForm.password;
      }
      if (Object.keys(body).length === 0) {
        setEditing(null);
        return;
      }
      await sendJson<FirebaseUser>(
        `/api/v1/firebase-users/${editing.uid}`,
        "PATCH",
        body,
      );
      setEditing(null);
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Güncellenemedi");
    } finally {
      setBusy(false);
    }
  }

  async function toggleDisabled(u: FirebaseUser) {
    setBusy(true);
    setError(null);
    try {
      await sendJson(
        `/api/v1/firebase-users/${u.uid}/${u.disabled ? "enable" : "disable"}`,
        "POST",
      );
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "İşlem başarısız");
    } finally {
      setBusy(false);
    }
  }

  async function generateLink(u: FirebaseUser, kind: "reset-password" | "verify-email") {
    setBusy(true);
    setError(null);
    setInfo(null);
    try {
      const r = await sendJson<{ link: string; email: string }>(
        `/api/v1/firebase-users/${u.uid}/${kind}`,
        "POST",
      );
      if (r) {
        setLinkInfo({
          title:
            kind === "reset-password"
              ? "Parola sıfırlama linki"
              : "E-posta doğrulama linki",
          email: r.email,
          link: r.link,
        });
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "İşlem başarısız");
    } finally {
      setBusy(false);
    }
  }

  async function revokeTokens(u: FirebaseUser) {
    setBusy(true);
    setError(null);
    try {
      await sendJson(`/api/v1/firebase-users/${u.uid}/revoke-tokens`, "POST");
      setInfo(`${u.email ?? u.uid} için tüm oturum token'ları iptal edildi.`);
    } catch (e) {
      setError(e instanceof Error ? e.message : "İşlem başarısız");
    } finally {
      setBusy(false);
    }
  }

  async function setRole(u: FirebaseUser, role: FirebaseRole | null) {
    setBusy(true);
    setError(null);
    try {
      await sendJson<FirebaseUser>(`/api/v1/firebase-users/${u.uid}/claims`, "POST", {
        role,
      });
      const label = role ? roleLabel(role) : "rolsüz";
      setInfo(`${u.email ?? u.uid}: ${label} olarak ayarlandı.`);
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Rol atanamadı");
    } finally {
      setBusy(false);
    }
  }

  async function confirmDelete() {
    if (!deleteTarget) return;
    setBusy(true);
    try {
      await sendJson(`/api/v1/firebase-users/${deleteTarget.uid}`, "DELETE");
      setDeleteTarget(null);
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Silinemedi");
    } finally {
      setBusy(false);
    }
  }

  const filtered = search.trim()
    ? users.filter((u) => {
        const q = search.toLowerCase();
        return (
          (u.email ?? "").toLowerCase().includes(q) ||
          (u.displayName ?? "").toLowerCase().includes(q) ||
          u.uid.toLowerCase().includes(q)
        );
      })
    : users;

  if (enabled === false) {
    return (
      <div className="mx-auto max-w-3xl p-6">
        <h1 className="text-2xl font-bold tracking-tight">Firebase Auth</h1>
        <div className="border-amber-300 bg-amber-50 text-amber-900 dark:border-amber-700 dark:bg-amber-950 dark:text-amber-200 mt-4 flex items-start gap-3 rounded-lg border p-4 text-sm">
          <AlertTriangle className="mt-0.5 size-4 shrink-0" />
          <div>
            <p className="font-medium">Firebase yapılandırılmadı.</p>
            <p className="text-amber-800 dark:text-amber-300 mt-1">
              <code className="bg-muted rounded px-1 text-xs">
                backend/.env
              </code>{" "}
              içinde{" "}
              <code className="bg-muted rounded px-1 text-xs">
                FIREBASE_SERVICE_ACCOUNT_PATH
              </code>{" "}
              ayarlayın ve service account JSON'unu{" "}
              <code className="bg-muted rounded px-1 text-xs">backend/</code>{" "}
              altına koyun. Sonra backend'i yeniden başlatın.
            </p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-6xl space-y-6 p-6">
      <header className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">
            Firebase Auth Kullanıcıları
          </h1>
          <p className="text-muted-foreground text-sm">
            Firebase'e kayıtlı tüm kimlikler. Burada yapılan değişiklik anında
            uygulamaya yansır.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <Input
            type="search"
            placeholder="E-posta, ad veya UID ara…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="h-9 w-64"
          />
          <Button variant="outline" onClick={() => void load(null, false)}>
            <RefreshCcw className="size-4" /> Yenile
          </Button>
        </div>
      </header>

      {info ? (
        <div className="border-emerald-300 bg-emerald-50 text-emerald-900 dark:border-emerald-800 dark:bg-emerald-950 dark:text-emerald-200 flex items-start gap-3 rounded-lg border p-3 text-sm">
          <Check className="mt-0.5 size-4 shrink-0" />
          <span className="flex-1">{info}</span>
          <button onClick={() => setInfo(null)} aria-label="Kapat">
            <X className="size-4" />
          </button>
        </div>
      ) : null}

      {error ? (
        <div className="border-destructive/30 bg-destructive/5 text-destructive rounded-lg border p-4 text-sm">
          {error}
        </div>
      ) : null}

      <div className="border-border rounded-xl border">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Kullanıcı</TableHead>
              <TableHead>Rol</TableHead>
              <TableHead>Sağlayıcı</TableHead>
              <TableHead>Durum</TableHead>
              <TableHead>Son giriş</TableHead>
              <TableHead className="w-32 text-right">İşlem</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {loading && users.length === 0 ? (
              <TableRow>
                <TableCell
                  colSpan={6}
                  className="text-muted-foreground h-24 text-center"
                >
                  Yükleniyor…
                </TableCell>
              </TableRow>
            ) : filtered.length === 0 ? (
              <TableRow>
                <TableCell
                  colSpan={6}
                  className="text-muted-foreground h-24 text-center"
                >
                  Kayıt yok.
                </TableCell>
              </TableRow>
            ) : (
              filtered.map((u) => <UserRow
                key={u.uid}
                u={u}
                busy={busy}
                onEdit={() => startEdit(u)}
                onDelete={() => setDeleteTarget(u)}
                onToggle={() => void toggleDisabled(u)}
                onReset={() => void generateLink(u, "reset-password")}
                onVerify={() => void generateLink(u, "verify-email")}
                onRevoke={() => void revokeTokens(u)}
                onSetRole={(r) => void setRole(u, r)}
              />)
            )}
          </TableBody>
        </Table>
      </div>

      {pageToken ? (
        <div className="flex justify-center">
          <Button
            variant="outline"
            onClick={() => void load(pageToken, true)}
            disabled={loading}
          >
            Daha fazla yükle
          </Button>
        </div>
      ) : null}

      <Modal
        open={editing != null}
        onClose={() => setEditing(null)}
        title="Firebase kullanıcısını düzenle"
        description={editing ? `UID: ${editing.uid}` : ""}
        size="lg"
        footer={
          <>
            <Button variant="outline" onClick={() => setEditing(null)}>
              İptal
            </Button>
            <Button onClick={() => void submitEdit()} disabled={busy}>
              {busy ? "Kaydediliyor…" : "Kaydet"}
            </Button>
          </>
        }
      >
        <div className="grid gap-4">
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-2">
              <Label htmlFor="fb-email">E-posta</Label>
              <Input
                id="fb-email"
                type="email"
                value={editForm.email}
                onChange={(e) =>
                  setEditForm((f) => ({ ...f, email: e.target.value }))
                }
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="fb-name">Görünen ad</Label>
              <Input
                id="fb-name"
                value={editForm.displayName}
                onChange={(e) =>
                  setEditForm((f) => ({ ...f, displayName: e.target.value }))
                }
              />
            </div>
          </div>
          <div className="grid gap-2">
            <Label htmlFor="fb-phone">Telefon (E.164: +905xx…)</Label>
            <Input
              id="fb-phone"
              value={editForm.phoneNumber}
              onChange={(e) =>
                setEditForm((f) => ({ ...f, phoneNumber: e.target.value }))
              }
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="fb-pwd">Yeni parola (≥ 6 karakter, opsiyonel)</Label>
            <Input
              id="fb-pwd"
              type="text"
              autoComplete="off"
              value={editForm.password}
              onChange={(e) =>
                setEditForm((f) => ({ ...f, password: e.target.value }))
              }
            />
          </div>
          <label className="flex cursor-pointer items-center gap-2 text-sm">
            <input
              type="checkbox"
              checked={editForm.emailVerified}
              onChange={(e) =>
                setEditForm((f) => ({ ...f, emailVerified: e.target.checked }))
              }
            />
            E-posta doğrulanmış say
          </label>
        </div>
      </Modal>

      <Modal
        open={linkInfo != null}
        onClose={() => setLinkInfo(null)}
        title={linkInfo?.title ?? ""}
        description={
          linkInfo
            ? `Bu link ${linkInfo.email} için oluşturuldu. Linki kullanıcıya gönderebilirsiniz.`
            : ""
        }
        size="lg"
        footer={
          <Button onClick={() => setLinkInfo(null)}>Tamam</Button>
        }
      >
        {linkInfo ? (
          <div className="space-y-3">
            <div className="bg-muted/60 group relative overflow-hidden rounded-md border border-border">
              <pre className="overflow-x-auto p-3 font-mono text-xs leading-relaxed break-all whitespace-pre-wrap">
                {linkInfo.link}
              </pre>
              <button
                type="button"
                onClick={async () => {
                  try {
                    await navigator.clipboard.writeText(linkInfo.link);
                    setInfo("Link panoya kopyalandı");
                  } catch {
                    /* noop */
                  }
                }}
                className="bg-background hover:bg-muted absolute right-2 top-2 inline-flex h-7 items-center gap-1 rounded-md border border-border px-2 text-xs"
              >
                <Copy className="size-3.5" /> Kopyala
              </button>
            </div>
          </div>
        ) : null}
      </Modal>

      <ConfirmDialog
        open={deleteTarget != null}
        onClose={() => setDeleteTarget(null)}
        onConfirm={() => void confirmDelete()}
        title="Firebase kullanıcısını sil"
        description={
          deleteTarget
            ? `${deleteTarget.email ?? deleteTarget.uid} kalıcı olarak silinsin mi? Bu işlem geri alınamaz; kullanıcı uygulamada artık giriş yapamaz.`
            : ""
        }
        confirmLabel="Sil"
        busy={busy}
      />
    </div>
  );
}

function UserRow({
  u,
  busy,
  onEdit,
  onDelete,
  onToggle,
  onReset,
  onVerify,
  onRevoke,
  onSetRole,
}: {
  u: FirebaseUser;
  busy: boolean;
  onEdit: () => void;
  onDelete: () => void;
  onToggle: () => void;
  onReset: () => void;
  onVerify: () => void;
  onRevoke: () => void;
  onSetRole: (r: FirebaseRole | null) => void;
}) {
  const lastSignIn = u.metadata.lastSignInAt
    ? new Date(u.metadata.lastSignInAt).toLocaleString("tr-TR", {
        dateStyle: "short",
        timeStyle: "short",
      })
    : "—";

  const role = readRole(u);

  const items: ActionMenuEntry[] = [
    { label: "Düzenle", icon: Pencil, onClick: onEdit },
    { separator: true },
    {
      label: role === "admin" ? "✓ Yönetici" : "Yönetici yap",
      icon: ShieldCheck,
      onClick: () => onSetRole(role === "admin" ? null : "admin"),
    },
    {
      label: role === "operator" ? "✓ Operatör" : "Operatör yap",
      icon: ShieldCheck,
      onClick: () => onSetRole(role === "operator" ? null : "operator"),
    },
    {
      label: role === "viewer" ? "✓ Görüntüleyici" : "Görüntüleyici yap",
      icon: ShieldCheck,
      onClick: () => onSetRole(role === "viewer" ? null : "viewer"),
    },
    { separator: true },
    u.disabled
      ? { label: "Aktifleştir", icon: UserCheck, onClick: onToggle }
      : { label: "Devredışı bırak", icon: Ban, onClick: onToggle },
    { label: "Parola sıfırlama linki", icon: Key, onClick: onReset },
    ...(u.email && !u.emailVerified
      ? [
          {
            label: "E-posta doğrulama linki",
            icon: MailCheck,
            onClick: onVerify,
          } as ActionMenuEntry,
        ]
      : []),
    { label: "Oturumları sonlandır", icon: ShieldOff, onClick: onRevoke },
    { separator: true },
    { label: "Sil", icon: Trash2, destructive: true, onClick: onDelete },
  ];

  return (
    <TableRow>
      <TableCell>
        <div className="flex items-center gap-3 min-w-0">
          {u.photoURL ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={u.photoURL}
              alt=""
              className="bg-muted border-border size-9 rounded-full border object-cover"
            />
          ) : (
            <span className="bg-muted text-muted-foreground flex size-9 shrink-0 items-center justify-center rounded-full text-xs font-semibold">
              {(u.displayName ?? u.email ?? "?").slice(0, 1).toUpperCase()}
            </span>
          )}
          <div className="min-w-0">
            <Link
              href={`/firebase-users/${u.uid}`}
              className="truncate text-sm font-medium hover:underline"
            >
              {u.displayName ?? u.email ?? u.uid}
            </Link>
            <p className="text-muted-foreground truncate text-xs">
              {u.email ?? u.uid}
            </p>
          </div>
        </div>
      </TableCell>
      <TableCell>
        {role ? (
          <Badge variant={role === "admin" ? "default" : "outline"}>
            {roleLabel(role)}
          </Badge>
        ) : (
          <span className="text-muted-foreground text-xs">—</span>
        )}
      </TableCell>
      <TableCell className="text-xs">
        <div className="flex flex-wrap gap-1">
          {u.providers.length === 0 ? (
            <Badge variant="muted">—</Badge>
          ) : (
            u.providers.map((p) => (
              <Badge key={p.providerId} variant="outline">
                {p.providerId.replace(".com", "")}
              </Badge>
            ))
          )}
        </div>
      </TableCell>
      <TableCell>
        <div className="flex flex-wrap gap-1">
          {u.disabled ? (
            <Badge variant="muted">Devredışı</Badge>
          ) : (
            <Badge variant="success">Aktif</Badge>
          )}
          {u.emailVerified ? (
            <Badge
              variant="outline"
              className="text-emerald-700 dark:text-emerald-300"
            >
              Onaylı
            </Badge>
          ) : u.email ? (
            <Badge variant="warning">Onaysız</Badge>
          ) : null}
        </div>
      </TableCell>
      <TableCell className="text-xs text-muted-foreground">{lastSignIn}</TableCell>
      <TableCell className="text-right">
        <Link
          href={`/firebase-users/${u.uid}`}
          className="text-muted-foreground hover:text-foreground hover:bg-accent inline-flex h-8 items-center gap-1 rounded-md px-2 text-xs font-medium"
        >
          Detay
          <ArrowRight className="size-3.5" />
        </Link>
        <ActionMenu items={items} disabled={busy} />
      </TableCell>
    </TableRow>
  );
}
