"use client";

import { useCallback, useEffect, useState } from "react";

import { apiUrl, readError } from "@/lib/api";

export function useList<T>(path: string) {
  const [data, setData] = useState<T[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(apiUrl(path), { cache: "no-store" });
      if (!res.ok) {
        setError(await readError(res));
        setData([]);
        return;
      }
      const j = (await res.json()) as T[];
      setData(Array.isArray(j) ? j : []);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Ağ hatası");
      setData([]);
    } finally {
      setLoading(false);
    }
  }, [path]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  return { data, loading, error, refresh, setError };
}

export async function sendJson<T>(
  path: string,
  method: "POST" | "PATCH" | "DELETE",
  body?: unknown,
): Promise<T | null> {
  const res = await fetch(apiUrl(path), {
    method,
    headers: body ? { "Content-Type": "application/json" } : undefined,
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok && res.status !== 204) {
    throw new Error(await readError(res));
  }
  if (res.status === 204) return null;
  return (await res.json()) as T;
}

/** multipart/form-data göndermek için (file upload). Content-Type'i tarayıcı set eder. */
export async function sendForm<T>(
  path: string,
  method: "POST" | "PATCH",
  form: FormData,
): Promise<T | null> {
  const res = await fetch(apiUrl(path), { method, body: form });
  if (!res.ok && res.status !== 204) {
    throw new Error(await readError(res));
  }
  if (res.status === 204) return null;
  return (await res.json()) as T;
}
