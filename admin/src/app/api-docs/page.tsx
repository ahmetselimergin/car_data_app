"use client";

import { Check, Copy, Terminal } from "lucide-react";
import { useMemo, useState } from "react";

import { Badge } from "@/components/ui/badge";
import { API_BASE } from "@/lib/api";
import { API_DOCS, ERROR_FORMAT, type Endpoint, type Method } from "@/lib/api-docs-data";
import { cn } from "@/lib/utils";

const METHOD_STYLE: Record<Method, string> = {
  GET: "bg-emerald-100 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300",
  POST: "bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-300",
  PATCH: "bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-300",
  DELETE: "bg-rose-100 text-rose-700 dark:bg-rose-950 dark:text-rose-300",
};

function methodBadge(m: Method) {
  return (
    <span
      className={cn(
        "inline-flex h-6 items-center justify-center rounded px-2 font-mono text-[11px] font-semibold tracking-wider",
        METHOD_STYLE[m],
      )}
    >
      {m}
    </span>
  );
}

function CopyButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false);
  return (
    <button
      type="button"
      onClick={async () => {
        try {
          await navigator.clipboard.writeText(text);
          setCopied(true);
          setTimeout(() => setCopied(false), 1500);
        } catch {
          /* noop */
        }
      }}
      className="text-muted-foreground hover:bg-accent hover:text-foreground inline-flex h-7 items-center gap-1 rounded-md px-2 text-xs transition-colors"
      aria-label="Kopyala"
    >
      {copied ? (
        <>
          <Check className="size-3.5" /> Kopyalandı
        </>
      ) : (
        <>
          <Copy className="size-3.5" /> Kopyala
        </>
      )}
    </button>
  );
}

function curlExample(ep: Endpoint): string {
  const url = `${API_BASE}${ep.path}`;
  const headers: string[] = [];
  let dataPart = "";
  if (ep.body && ep.body.length > 0) {
    if (ep.contentType === "multipart/form-data") {
      dataPart = ep.body
        .filter((b) => !b.type.includes("file"))
        .map((b) => ` -F "${b.name}=<${b.name}>"`)
        .join("");
      const fileFields = ep.body.filter((b) => b.type.includes("file"));
      if (fileFields.length > 0) {
        dataPart +=
          " " +
          fileFields.map((f) => `-F "${f.name}=@/path/to/${f.name}.png"`).join(" ");
      }
    } else {
      headers.push("Content-Type: application/json");
      const sample: Record<string, string> = {};
      for (const f of ep.body) sample[f.name] = `<${f.type}>`;
      dataPart = ` -d '${JSON.stringify(sample)}'`;
    }
  }
  const headerStr = headers.map((h) => ` -H "${h}"`).join("");
  return `curl -X ${ep.method}${headerStr}${dataPart} ${url}`;
}

function FieldTable({ title, rows }: { title: string; rows: Endpoint["body"] }) {
  if (!rows || rows.length === 0) return null;
  return (
    <div className="space-y-2">
      <p className="text-muted-foreground text-xs font-semibold uppercase tracking-wider">
        {title}
      </p>
      <div className="border-border overflow-hidden rounded-md border">
        <table className="w-full text-xs">
          <thead className="bg-muted/40 text-muted-foreground">
            <tr>
              <th className="px-3 py-2 text-left font-medium">Alan</th>
              <th className="px-3 py-2 text-left font-medium">Tip</th>
              <th className="px-3 py-2 text-left font-medium">Açıklama</th>
            </tr>
          </thead>
          <tbody className="divide-border divide-y">
            {rows.map((f) => (
              <tr key={f.name}>
                <td className="px-3 py-2 align-top">
                  <span className="font-mono">{f.name}</span>
                  {f.required ? (
                    <span className="ml-1 text-rose-600">*</span>
                  ) : null}
                </td>
                <td className="px-3 py-2 align-top">
                  <span className="font-mono text-muted-foreground">{f.type}</span>
                </td>
                <td className="px-3 py-2 align-top text-muted-foreground">
                  {f.description ?? "—"}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function EndpointCard({ ep }: { ep: Endpoint }) {
  const curl = useMemo(() => curlExample(ep), [ep]);
  const [showCurl, setShowCurl] = useState(false);

  return (
    <article
      id={`${ep.method.toLowerCase()}-${ep.path.replace(/[^a-z0-9]/gi, "-")}`}
      className="bg-card border-border space-y-4 rounded-xl border p-5 scroll-mt-24"
    >
      <header className="flex flex-wrap items-start gap-3">
        {methodBadge(ep.method)}
        <code className="bg-muted text-foreground rounded-md px-2 py-1 font-mono text-sm">
          {ep.path}
        </code>
        {ep.contentType ? (
          <Badge variant="outline">{ep.contentType}</Badge>
        ) : null}
        <CopyButton text={ep.path} />
      </header>
      <p className="text-sm font-medium">{ep.summary}</p>
      {ep.description ? (
        <p className="text-muted-foreground text-sm leading-relaxed">
          {ep.description}
        </p>
      ) : null}

      <FieldTable title="Path parametreleri" rows={ep.pathParams} />
      <FieldTable title="Query parametreleri" rows={ep.query} />
      <FieldTable title="Gövde alanları" rows={ep.body} />

      <div className="space-y-2">
        <p className="text-muted-foreground text-xs font-semibold uppercase tracking-wider">
          Yanıtlar
        </p>
        <div className="grid gap-1 text-sm">
          {ep.responses.map((r) => (
            <div key={r.status} className="flex items-start gap-3">
              <span
                className={cn(
                  "inline-flex h-6 w-12 shrink-0 items-center justify-center rounded font-mono text-xs font-semibold",
                  r.status >= 500
                    ? "bg-rose-100 text-rose-700"
                    : r.status >= 400
                      ? "bg-amber-100 text-amber-800"
                      : "bg-emerald-100 text-emerald-700",
                )}
              >
                {r.status}
              </span>
              <span className="text-muted-foreground">{r.description}</span>
            </div>
          ))}
        </div>
      </div>

      <div className="space-y-2">
        <button
          type="button"
          onClick={() => setShowCurl((v) => !v)}
          className="text-muted-foreground hover:text-foreground inline-flex items-center gap-1.5 text-xs"
        >
          <Terminal className="size-3.5" />
          {showCurl ? "cURL'ü gizle" : "cURL örneği"}
        </button>
        {showCurl ? (
          <div className="bg-muted/60 group relative overflow-hidden rounded-md border border-border">
            <pre className="overflow-x-auto p-3 font-mono text-xs leading-relaxed whitespace-pre-wrap break-all">
              {curl}
            </pre>
            <div className="absolute right-2 top-2">
              <CopyButton text={curl} />
            </div>
          </div>
        ) : null}
      </div>
    </article>
  );
}

export default function ApiDocsPage() {
  return (
    <div className="mx-auto grid max-w-6xl gap-8 p-6 lg:grid-cols-[220px_1fr]">
      <aside className="lg:sticky lg:top-6 lg:self-start">
        <p className="text-muted-foreground mb-3 text-xs font-semibold uppercase tracking-wider">
          Bölümler
        </p>
        <nav className="grid gap-1 text-sm">
          {API_DOCS.map((s) => (
            <a
              key={s.id}
              href={`#${s.id}`}
              className="hover:bg-accent hover:text-foreground rounded-md px-2 py-1.5"
            >
              {s.title}
              <span className="text-muted-foreground ml-2 text-xs">
                ({s.endpoints.length})
              </span>
            </a>
          ))}
          <a
            href="#errors"
            className="hover:bg-accent hover:text-foreground rounded-md px-2 py-1.5"
          >
            Hata formatı
          </a>
        </nav>
      </aside>

      <div className="space-y-10 min-w-0">
        <header className="space-y-3">
          <p className="text-muted-foreground text-xs font-semibold uppercase tracking-widest">
            Geliştirici dökümanı
          </p>
          <h1 className="text-3xl font-bold tracking-tight">CarDEX API</h1>
          <p className="text-muted-foreground max-w-3xl text-sm leading-relaxed">
            Panelin tükettiği REST uçları. Tüm yanıtlar JSON; hata yanıtları
            ortak bir formattadır. Base URL:{" "}
            <code className="bg-muted rounded px-1.5 py-0.5 text-xs">
              {API_BASE}
            </code>
          </p>
        </header>

        {API_DOCS.map((section) => (
          <section
            key={section.id}
            id={section.id}
            className="space-y-4 scroll-mt-24"
          >
            <div className="border-border border-b pb-2">
              <h2 className="text-xl font-semibold tracking-tight">
                {section.title}
              </h2>
              {section.description ? (
                <p className="text-muted-foreground mt-1 text-sm">
                  {section.description}
                </p>
              ) : null}
            </div>
            <div className="grid gap-4">
              {section.endpoints.map((ep) => (
                <EndpointCard key={`${ep.method}-${ep.path}`} ep={ep} />
              ))}
            </div>
          </section>
        ))}

        <section id="errors" className="space-y-3 scroll-mt-24">
          <div className="border-border border-b pb-2">
            <h2 className="text-xl font-semibold tracking-tight">
              Hata formatı
            </h2>
            <p className="text-muted-foreground mt-1 text-sm">
              Tüm 4xx/5xx yanıtları aşağıdaki şemaya uyar.
            </p>
          </div>
          <pre className="bg-muted/60 border-border overflow-x-auto rounded-md border p-4 font-mono text-xs leading-relaxed whitespace-pre">
            {ERROR_FORMAT}
          </pre>
        </section>
      </div>
    </div>
  );
}
