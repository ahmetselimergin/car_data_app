export const API_BASE =
  process.env.NEXT_PUBLIC_API_URL?.replace(/\/$/, "") ?? "http://localhost:4000";

export function apiUrl(path: string): string {
  const p = path.startsWith("/") ? path : `/${path}`;
  return `${API_BASE}${p}`;
}

/** /uploads/... gibi rölatif path'i tam URL'e çevirir; tam URL gelirse aynen döner */
export function assetUrl(pathOrUrl: string | null | undefined): string | null {
  if (!pathOrUrl) return null;
  if (/^https?:\/\//i.test(pathOrUrl)) return pathOrUrl;
  return apiUrl(pathOrUrl);
}

export async function readError(res: Response): Promise<string> {
  let msg = `HTTP ${res.status}`;
  try {
    const j = (await res.json()) as {
      error?: string;
      detail?: string | string[];
      debug?: string;
      code?: string;
    };
    if (j.error) msg = j.error;
    if (Array.isArray(j.detail)) msg = `${msg}: ${j.detail.join(", ")}`;
    else if (j.detail) msg = `${msg}: ${j.detail}`;
    if (j.debug && process.env.NODE_ENV === "development") {
      msg += ` (${j.debug})`;
    }
  } catch {
    /* JSON değil */
  }
  return msg;
}

export type Brand = {
  id: number;
  slug: string;
  name: string;
  logoUrl: string | null;
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
};

export type Car = {
  id: number;
  plaka: string;
  marka: string;
  model: string;
  yil: number;
  km: number;
  transmission: string | null;
  fuelType: string | null;
  color: string | null;
  imageUrl: string | null;
  notes: string | null;
  brandId: number | null;
  brand: Brand | null;
  firebaseUid: string | null;
  createdAt: string;
  updatedAt: string;
};

export type Workshop = {
  id: number;
  name: string;
  phone: string | null;
  email: string | null;
  address: string | null;
  notes: string | null;
  active: boolean;
  createdAt: string;
  updatedAt: string;
};

export type Model = {
  id: number;
  brandId: number;
  name: string;
  bodyType: string | null;
  yearStart: number | null;
  yearEnd: number | null;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
};

export const INSURANCE_TYPES = [
  { value: "insurance", label: "Trafik" },
  { value: "casco", label: "Kasko" },
  { value: "both", label: "Trafik + Kasko" },
] as const;

export type InsuranceCompany = {
  id: number;
  name: string;
  type: (typeof INSURANCE_TYPES)[number]["value"];
  phone: string | null;
  email: string | null;
  website: string | null;
  address: string | null;
  notes: string | null;
  active: boolean;
  createdAt: string;
  updatedAt: string;
};

export const FIREBASE_ROLES = [
  { value: "admin", label: "Yönetici" },
  { value: "operator", label: "Operatör" },
  { value: "viewer", label: "Görüntüleyici" },
] as const;

export type FirebaseRole = (typeof FIREBASE_ROLES)[number]["value"];

export type FirebaseProvider = {
  providerId: string;
  uid: string;
  email: string | null;
  displayName: string | null;
};

export type FirebaseUser = {
  uid: string;
  email: string | null;
  emailVerified: boolean;
  displayName: string | null;
  photoURL: string | null;
  phoneNumber: string | null;
  disabled: boolean;
  providers: FirebaseProvider[];
  metadata: {
    createdAt: string;
    lastSignInAt: string;
    lastRefreshAt: string | null;
  };
  customClaims: Record<string, unknown> | null;
};

export type FirebaseListResponse = {
  users: FirebaseUser[];
  pageToken: string | null;
};
