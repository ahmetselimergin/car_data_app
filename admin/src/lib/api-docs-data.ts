export type Method = "GET" | "POST" | "PATCH" | "DELETE";

export type Field = {
  name: string;
  type: string;
  required?: boolean;
  description?: string;
};

export type Endpoint = {
  method: Method;
  path: string;
  summary: string;
  description?: string;
  contentType?: "application/json" | "multipart/form-data";
  query?: Field[];
  pathParams?: Field[];
  body?: Field[];
  responses: { status: number; description: string }[];
};

export type DocSection = {
  id: string;
  title: string;
  description?: string;
  endpoints: Endpoint[];
};

const TIMESTAMPS: Field[] = [
  { name: "createdAt", type: "ISO 8601" },
  { name: "updatedAt", type: "ISO 8601" },
];

export const API_DOCS: DocSection[] = [
  {
    id: "health",
    title: "Sistem",
    description: "Sağlık durumu ve API meta bilgisi.",
    endpoints: [
      {
        method: "GET",
        path: "/health",
        summary: "Sağlık kontrolü",
        responses: [{ status: 200, description: "{ ok: true, service, ts }" }],
      },
      {
        method: "GET",
        path: "/api/v1",
        summary: "API kökü, endpoint listesi",
        responses: [{ status: 200, description: "{ name, version, endpoints[] }" }],
      },
    ],
  },
  {
    id: "cars",
    title: "Araçlar",
    description: "Bir kullanıcıya bağlı (opsiyonel) araç kayıtları.",
    endpoints: [
      {
        method: "GET",
        path: "/api/v1/cars",
        summary: "Liste",
        query: [
          {
            name: "firebaseUid",
            type: "string",
            description: "Bu Firebase kullanıcısının araçlarını getirir.",
          },
        ],
        responses: [{ status: 200, description: "Car[] (her satıra brand objesi gömülür)" }],
      },
      {
        method: "POST",
        path: "/api/v1/cars",
        summary: "Yeni araç oluştur",
        contentType: "application/json",
        body: [
          { name: "plaka", type: "string", required: true },
          { name: "marka", type: "string", required: true },
          { name: "model", type: "string", required: true },
          { name: "yil", type: "number", required: true, description: "1900–2100" },
          { name: "km", type: "number", description: "≥ 0, varsayılan 0" },
          { name: "transmission", type: "string?" },
          { name: "fuelType", type: "string?" },
          { name: "color", type: "string?" },
          { name: "imageUrl", type: "url?" },
          { name: "notes", type: "string?" },
          { name: "brandId", type: "number?", description: "brands tablosuna FK" },
          {
            name: "firebaseUid",
            type: "string?",
            description: "Sahip Firebase Auth UID",
          },
        ],
        responses: [
          { status: 201, description: "Car (brand bilgisi ile)" },
          { status: 400, description: "Doğrulama / yabancı anahtar hatası" },
        ],
      },
      {
        method: "GET",
        path: "/api/v1/cars/:id",
        summary: "Tek araç",
        pathParams: [{ name: "id", type: "number", required: true }],
        responses: [
          { status: 200, description: "Car" },
          { status: 404, description: "Bulunamadı" },
        ],
      },
      {
        method: "PATCH",
        path: "/api/v1/cars/:id",
        summary: "Aracı güncelle (kısmi)",
        contentType: "application/json",
        pathParams: [{ name: "id", type: "number", required: true }],
        body: [
          { name: "plaka", type: "string?" },
          { name: "marka", type: "string?" },
          { name: "model", type: "string?" },
          { name: "yil", type: "number?" },
          { name: "km", type: "number?" },
          { name: "transmission", type: "string?" },
          { name: "fuelType", type: "string?" },
          { name: "color", type: "string?" },
          { name: "imageUrl", type: "url?" },
          { name: "notes", type: "string?" },
          { name: "brandId", type: "number | null?" },
          { name: "firebaseUid", type: "string | null?" },
        ],
        responses: [
          { status: 200, description: "Car" },
          { status: 400, description: "EMPTY / doğrulama" },
        ],
      },
      {
        method: "DELETE",
        path: "/api/v1/cars/:id",
        summary: "Aracı sil",
        pathParams: [{ name: "id", type: "number", required: true }],
        responses: [
          { status: 204, description: "Silindi (gövdesiz)" },
          { status: 404, description: "Bulunamadı" },
        ],
      },
    ],
  },
  {
    id: "brands",
    title: "Markalar",
    description:
      "Logo dosyası ile birlikte yönetilir. POST/PATCH multipart/form-data alır; logo dosyası `logo` alanında.",
    endpoints: [
      {
        method: "GET",
        path: "/api/v1/brands",
        summary: "Liste (sortOrder, name)",
        responses: [{ status: 200, description: "Brand[]" }],
      },
      {
        method: "POST",
        path: "/api/v1/brands",
        summary: "Yeni marka",
        contentType: "multipart/form-data",
        body: [
          { name: "slug", type: "string", required: true, description: "Otomatik normalize edilir" },
          { name: "name", type: "string", required: true },
          { name: "sortOrder", type: "number", description: "Varsayılan 0" },
          {
            name: "logo",
            type: "file",
            description: "PNG/JPG/WEBP/SVG, ≤ 5 MB. Disk yolu /uploads/brands/...",
          },
        ],
        responses: [
          { status: 201, description: "Brand" },
          { status: 400, description: "Doğrulama / desteklenmeyen dosya türü" },
          { status: 409, description: "Slug zaten kullanılıyor (23505)" },
        ],
      },
      {
        method: "GET",
        path: "/api/v1/brands/:id",
        summary: "Tek marka",
        pathParams: [{ name: "id", type: "number", required: true }],
        responses: [
          { status: 200, description: "Brand" },
          { status: 404, description: "Bulunamadı" },
        ],
      },
      {
        method: "PATCH",
        path: "/api/v1/brands/:id",
        summary: "Markayı güncelle",
        contentType: "multipart/form-data",
        pathParams: [{ name: "id", type: "number", required: true }],
        body: [
          { name: "slug", type: "string?" },
          { name: "name", type: "string?" },
          { name: "sortOrder", type: "number?" },
          { name: "logo", type: "file?", description: "Yeni dosya: eski logo silinir" },
          {
            name: "removeLogo",
            type: "1 | 0",
            description: "Mevcut logoyu silmek için (yeni dosya yoksa)",
          },
        ],
        responses: [
          { status: 200, description: "Brand" },
          { status: 404, description: "Bulunamadı" },
        ],
      },
      {
        method: "DELETE",
        path: "/api/v1/brands/:id",
        summary: "Markayı sil (logosu da diskten silinir)",
        pathParams: [{ name: "id", type: "number", required: true }],
        responses: [
          { status: 204, description: "Silindi" },
          { status: 404, description: "Bulunamadı" },
        ],
      },
    ],
  },
  {
    id: "models",
    title: "Modeller",
    description: "Bir markaya bağlı model kataloğu. (brandId + name) çifti uniq.",
    endpoints: [
      {
        method: "GET",
        path: "/api/v1/models",
        summary: "Liste",
        query: [
          {
            name: "brandId",
            type: "number",
            description: "Sadece bu markanın modelleri",
          },
        ],
        responses: [{ status: 200, description: "Model[]" }],
      },
      {
        method: "POST",
        path: "/api/v1/models",
        summary: "Yeni model",
        contentType: "application/json",
        body: [
          { name: "brandId", type: "number", required: true },
          { name: "name", type: "string", required: true },
          { name: "bodyType", type: "string?" },
          { name: "yearStart", type: "number?" },
          { name: "yearEnd", type: "number?" },
          { name: "notes", type: "string?" },
        ],
        responses: [
          { status: 201, description: "Model" },
          { status: 400, description: "Marka yok / doğrulama" },
        ],
      },
      {
        method: "GET",
        path: "/api/v1/models/:id",
        summary: "Tek model",
        pathParams: [{ name: "id", type: "number", required: true }],
        responses: [{ status: 200, description: "Model" }],
      },
      {
        method: "PATCH",
        path: "/api/v1/models/:id",
        summary: "Modeli güncelle",
        contentType: "application/json",
        pathParams: [{ name: "id", type: "number", required: true }],
        body: [
          { name: "brandId", type: "number?" },
          { name: "name", type: "string?" },
          { name: "bodyType", type: "string?" },
          { name: "yearStart", type: "number?" },
          { name: "yearEnd", type: "number?" },
          { name: "notes", type: "string?" },
        ],
        responses: [{ status: 200, description: "Model" }],
      },
      {
        method: "DELETE",
        path: "/api/v1/models/:id",
        summary: "Modeli sil",
        pathParams: [{ name: "id", type: "number", required: true }],
        responses: [{ status: 204, description: "Silindi" }],
      },
    ],
  },
  {
    id: "workshops",
    title: "Tamirhaneler",
    endpoints: [
      {
        method: "GET",
        path: "/api/v1/workshops",
        summary: "Liste (önce aktifler)",
        responses: [{ status: 200, description: "Workshop[]" }],
      },
      {
        method: "POST",
        path: "/api/v1/workshops",
        summary: "Yeni tamirhane",
        contentType: "application/json",
        body: [
          { name: "name", type: "string", required: true },
          { name: "phone", type: "string?" },
          { name: "email", type: "email?" },
          { name: "address", type: "string?" },
          { name: "notes", type: "string?" },
          { name: "active", type: "boolean", description: "Varsayılan true" },
        ],
        responses: [{ status: 201, description: "Workshop" }],
      },
      {
        method: "GET",
        path: "/api/v1/workshops/:id",
        summary: "Tek kayıt",
        pathParams: [{ name: "id", type: "number", required: true }],
        responses: [{ status: 200, description: "Workshop" }],
      },
      {
        method: "PATCH",
        path: "/api/v1/workshops/:id",
        summary: "Güncelle",
        contentType: "application/json",
        pathParams: [{ name: "id", type: "number", required: true }],
        body: [
          { name: "name", type: "string?" },
          { name: "phone", type: "string?" },
          { name: "email", type: "email?" },
          { name: "address", type: "string?" },
          { name: "notes", type: "string?" },
          { name: "active", type: "boolean?" },
        ],
        responses: [{ status: 200, description: "Workshop" }],
      },
      {
        method: "DELETE",
        path: "/api/v1/workshops/:id",
        summary: "Sil",
        pathParams: [{ name: "id", type: "number", required: true }],
        responses: [{ status: 204, description: "Silindi" }],
      },
    ],
  },
  {
    id: "insurance",
    title: "Sigorta & Kasko",
    endpoints: [
      {
        method: "GET",
        path: "/api/v1/insurance",
        summary: "Liste",
        responses: [{ status: 200, description: "InsuranceCompany[]" }],
      },
      {
        method: "POST",
        path: "/api/v1/insurance",
        summary: "Yeni şirket",
        contentType: "application/json",
        body: [
          { name: "name", type: "string", required: true },
          {
            name: "type",
            type: "'insurance' | 'casco' | 'both'",
            description: "Varsayılan 'both'",
          },
          { name: "phone", type: "string?" },
          { name: "email", type: "email?" },
          { name: "website", type: "string?" },
          { name: "address", type: "string?" },
          { name: "notes", type: "string?" },
          { name: "active", type: "boolean", description: "Varsayılan true" },
        ],
        responses: [{ status: 201, description: "InsuranceCompany" }],
      },
      {
        method: "GET",
        path: "/api/v1/insurance/:id",
        summary: "Tek kayıt",
        pathParams: [{ name: "id", type: "number", required: true }],
        responses: [{ status: 200, description: "InsuranceCompany" }],
      },
      {
        method: "PATCH",
        path: "/api/v1/insurance/:id",
        summary: "Güncelle",
        contentType: "application/json",
        pathParams: [{ name: "id", type: "number", required: true }],
        body: [
          { name: "name", type: "string?" },
          { name: "type", type: "string?" },
          { name: "phone", type: "string?" },
          { name: "email", type: "email?" },
          { name: "website", type: "string?" },
          { name: "address", type: "string?" },
          { name: "notes", type: "string?" },
          { name: "active", type: "boolean?" },
        ],
        responses: [{ status: 200, description: "InsuranceCompany" }],
      },
      {
        method: "DELETE",
        path: "/api/v1/insurance/:id",
        summary: "Sil",
        pathParams: [{ name: "id", type: "number", required: true }],
        responses: [{ status: 204, description: "Silindi" }],
      },
    ],
  },
  {
    id: "firebase",
    title: "Firebase Auth",
    description:
      "Firebase Admin SDK üzerinden mobil uygulama kullanıcıları. Sunucuda FIREBASE_SERVICE_ACCOUNT_PATH ayarlı olmalı; aksi halde 503 döner.",
    endpoints: [
      {
        method: "GET",
        path: "/api/v1/firebase-users/status",
        summary: "Firebase'in yapılandırılıp yapılandırılmadığı",
        responses: [{ status: 200, description: "{ enabled: boolean }" }],
      },
      {
        method: "GET",
        path: "/api/v1/firebase-users",
        summary: "Sayfalı kullanıcı listesi",
        query: [
          { name: "limit", type: "number", description: "1–1000 (vars. 100)" },
          {
            name: "pageToken",
            type: "string",
            description: "Önceki yanıttan dönen sayfa anahtarı",
          },
        ],
        responses: [
          {
            status: 200,
            description: "{ users: FirebaseUser[], pageToken: string | null }",
          },
          { status: 503, description: "Firebase ayarsız" },
        ],
      },
      {
        method: "GET",
        path: "/api/v1/firebase-users/:uid",
        summary: "Tek kullanıcı",
        pathParams: [{ name: "uid", type: "string", required: true }],
        responses: [
          { status: 200, description: "FirebaseUser" },
          { status: 404, description: "Bulunamadı" },
        ],
      },
      {
        method: "PATCH",
        path: "/api/v1/firebase-users/:uid",
        summary: "Kullanıcıyı güncelle",
        contentType: "application/json",
        pathParams: [{ name: "uid", type: "string", required: true }],
        body: [
          { name: "email", type: "email?" },
          { name: "emailVerified", type: "boolean?" },
          { name: "displayName", type: "string?" },
          { name: "phoneNumber", type: "string?" },
          { name: "photoURL", type: "url?" },
          { name: "disabled", type: "boolean?" },
          { name: "password", type: "string?", description: "≥ 6 karakter" },
        ],
        responses: [
          { status: 200, description: "FirebaseUser" },
          { status: 409, description: "E-posta başka kullanıcıda" },
        ],
      },
      {
        method: "POST",
        path: "/api/v1/firebase-users/:uid/disable",
        summary: "Kullanıcıyı devredışı bırak",
        pathParams: [{ name: "uid", type: "string", required: true }],
        responses: [{ status: 200, description: "FirebaseUser" }],
      },
      {
        method: "POST",
        path: "/api/v1/firebase-users/:uid/enable",
        summary: "Kullanıcıyı tekrar aktifleştir",
        pathParams: [{ name: "uid", type: "string", required: true }],
        responses: [{ status: 200, description: "FirebaseUser" }],
      },
      {
        method: "POST",
        path: "/api/v1/firebase-users/:uid/reset-password",
        summary: "Parola sıfırlama linki üret",
        pathParams: [{ name: "uid", type: "string", required: true }],
        responses: [
          { status: 200, description: "{ link, email }" },
          { status: 400, description: "Kullanıcının e-postası yok" },
        ],
      },
      {
        method: "POST",
        path: "/api/v1/firebase-users/:uid/verify-email",
        summary: "E-posta doğrulama linki üret",
        pathParams: [{ name: "uid", type: "string", required: true }],
        responses: [{ status: 200, description: "{ link, email }" }],
      },
      {
        method: "POST",
        path: "/api/v1/firebase-users/:uid/claims",
        summary: "Panel rolü (custom claim) ata veya kaldır",
        description:
          "Verilen role panel için Firebase custom claim olarak kaydedilir. Ardından refresh token'lar iptal edilir; kullanıcı yeniden giriş yaptığında claim aktif olur.",
        contentType: "application/json",
        pathParams: [{ name: "uid", type: "string", required: true }],
        body: [
          {
            name: "role",
            type: "'admin' | 'operator' | 'viewer' | null",
            required: true,
            description: "null gönderilirse rol kaldırılır",
          },
        ],
        responses: [{ status: 200, description: "FirebaseUser (yeni claim'lerle)" }],
      },
      {
        method: "POST",
        path: "/api/v1/firebase-users/:uid/revoke-tokens",
        summary: "Tüm refresh token'ları iptal et (zorla logout)",
        pathParams: [{ name: "uid", type: "string", required: true }],
        responses: [{ status: 204, description: "Tamam" }],
      },
      {
        method: "DELETE",
        path: "/api/v1/firebase-users/:uid",
        summary: "Firebase kullanıcısını sil",
        pathParams: [{ name: "uid", type: "string", required: true }],
        responses: [
          { status: 204, description: "Silindi" },
          { status: 404, description: "Bulunamadı" },
        ],
      },
    ],
  },
  {
    id: "uploads",
    title: "Yüklenen dosyalar",
    description:
      "Markalar için yüklenen logolar. Statik servis edilir, kimlik doğrulama yok.",
    endpoints: [
      {
        method: "GET",
        path: "/uploads/brands/:filename",
        summary: "Marka logosu",
        responses: [
          { status: 200, description: "image/* binary" },
          { status: 404, description: "Dosya yok" },
        ],
      },
    ],
  },
];

export const COMMON_TIMESTAMPS = TIMESTAMPS;

export const ERROR_FORMAT = `{
  "error": "Kısa hata özeti",
  "detail"?: "Açıklama veya doğrulama mesajları",
  "code"?: "BAD_ID | NOT_FOUND | EMPTY | ...",
  "debug"?: "Yalnızca dev ortamında postgres ham mesajı"
}`;
