"use client";

import {
  ArrowUpRight,
  Building2,
  Car,
  Layers,
  ShieldCheck,
  Tag,
  Users,
} from "lucide-react";
import Link from "next/link";

import { API_BASE, apiUrl, readError } from "@/lib/api";
import type {
  Brand,
  Car as CarT,
  FirebaseListResponse,
  InsuranceCompany,
  Model,
  Workshop,
} from "@/lib/api";
import { useList } from "@/lib/use-list";
import { useEffect, useState } from "react";

function StatCard({
  href,
  title,
  count,
  loading,
  icon: Icon,
}: {
  href: string;
  title: string;
  count: number;
  loading: boolean;
  icon: React.ComponentType<{ className?: string }>;
}) {
  return (
    <Link
      href={href}
      className="group bg-card border-border hover:border-ring relative flex flex-col gap-3 rounded-xl border p-5 transition-colors"
    >
      <div className="flex items-start justify-between">
        <div className="bg-primary/10 text-primary flex size-10 items-center justify-center rounded-lg">
          <Icon className="size-5" />
        </div>
        <ArrowUpRight className="text-muted-foreground size-4 opacity-0 transition-opacity group-hover:opacity-100" />
      </div>
      <div>
        <p className="text-muted-foreground text-sm">{title}</p>
        <p className="mt-1 text-2xl font-semibold tracking-tight tabular-nums">
          {loading ? "—" : count.toLocaleString("tr-TR")}
        </p>
      </div>
    </Link>
  );
}

export default function Dashboard() {
  const cars = useList<CarT>("/api/v1/cars");
  const brands = useList<Brand>("/api/v1/brands");
  const models = useList<Model>("/api/v1/models");
  const workshops = useList<Workshop>("/api/v1/workshops");
  const insurance = useList<InsuranceCompany>("/api/v1/insurance");

  const [fbCount, setFbCount] = useState<number | null>(null);
  const [fbLoading, setFbLoading] = useState(true);
  const [fbError, setFbError] = useState<string | null>(null);

  useEffect(() => {
    void (async () => {
      try {
        const res = await fetch(apiUrl("/api/v1/firebase-users?limit=1000"), {
          cache: "no-store",
        });
        if (!res.ok) {
          if (res.status !== 503) setFbError(await readError(res));
          setFbCount(0);
          return;
        }
        const j = (await res.json()) as FirebaseListResponse;
        setFbCount(j.users.length);
      } catch {
        setFbCount(0);
      } finally {
        setFbLoading(false);
      }
    })();
  }, []);

  const anyError =
    cars.error ||
    brands.error ||
    models.error ||
    workshops.error ||
    insurance.error ||
    fbError;

  return (
    <div className="mx-auto max-w-6xl space-y-8 p-6">
      <header>
        <p className="text-muted-foreground text-xs font-semibold tracking-widest uppercase">
          Yönetim paneli
        </p>
        <h1 className="mt-1 text-3xl font-bold tracking-tight">
          Hoş geldin
        </h1>
        <p className="text-muted-foreground mt-2 text-sm">
          API:{" "}
          <code className="bg-muted rounded px-1.5 py-0.5 text-xs">
            {API_BASE}
          </code>
        </p>
      </header>

      {anyError ? (
        <div className="border-destructive/30 bg-destructive/5 text-destructive rounded-lg border p-4 text-sm">
          {anyError}
        </div>
      ) : null}

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <StatCard
          href="/cars"
          title="Araç sayısı"
          icon={Car}
          loading={cars.loading}
          count={cars.data.length}
        />
        <StatCard
          href="/brands"
          title="Marka"
          icon={Tag}
          loading={brands.loading}
          count={brands.data.length}
        />
        <StatCard
          href="/models"
          title="Model"
          icon={Layers}
          loading={models.loading}
          count={models.data.length}
        />
        <StatCard
          href="/workshops"
          title="Tamirhane"
          icon={Building2}
          loading={workshops.loading}
          count={workshops.data.length}
        />
        <StatCard
          href="/insurance"
          title="Sigorta & Kasko"
          icon={ShieldCheck}
          loading={insurance.loading}
          count={insurance.data.length}
        />
        <StatCard
          href="/firebase-users"
          title="Kullanıcı"
          icon={Users}
          loading={fbLoading}
          count={fbCount ?? 0}
        />
      </div>
    </div>
  );
}
