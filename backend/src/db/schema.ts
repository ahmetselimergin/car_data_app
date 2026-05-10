import { sql } from "drizzle-orm";
import {
  boolean,
  index,
  integer,
  pgTable,
  serial,
  text,
  timestamp,
  uniqueIndex,
} from "drizzle-orm/pg-core";

export const brands = pgTable(
  "brands",
  {
    id: serial("id").primaryKey(),
    slug: text("slug").notNull().unique(),
    name: text("name").notNull(),
    logoUrl: text("logo_url"),
    sortOrder: integer("sort_order").notNull().default(0),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .default(sql`now()`),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .notNull()
      .default(sql`now()`),
  },
  (t) => ({
    sortIdx: index("idx_brands_sort").on(t.sortOrder, t.name),
  }),
);

export const cars = pgTable(
  "cars",
  {
    id: serial("id").primaryKey(),
    plaka: text("plaka").notNull(),
    marka: text("marka").notNull(),
    model: text("model").notNull(),
    yil: integer("yil").notNull(),
    km: integer("km").notNull().default(0),
    transmission: text("transmission"),
    fuelType: text("fuel_type"),
    color: text("color"),
    imageUrl: text("image_url"),
    notes: text("notes"),
    brandId: integer("brand_id").references(() => brands.id, {
      onDelete: "set null",
    }),
    /** Firebase Auth UID — sahibi (mobil uygulama kullanıcısı) */
    firebaseUid: text("firebase_uid"),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .default(sql`now()`),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .notNull()
      .default(sql`now()`),
  },
  (t) => ({
    plakaUnq: uniqueIndex("idx_cars_plaka").on(t.plaka),
    brandIdx: index("idx_cars_brand").on(t.brandId),
    firebaseIdx: index("idx_cars_firebase").on(t.firebaseUid),
  }),
);

export const workshops = pgTable(
  "workshops",
  {
    id: serial("id").primaryKey(),
    name: text("name").notNull(),
    phone: text("phone"),
    email: text("email"),
    address: text("address"),
    notes: text("notes"),
    active: boolean("active").notNull().default(true),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .default(sql`now()`),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .notNull()
      .default(sql`now()`),
  },
  (t) => ({
    activeIdx: index("idx_workshops_active").on(t.active, t.name),
  }),
);

export const models = pgTable(
  "models",
  {
    id: serial("id").primaryKey(),
    brandId: integer("brand_id")
      .notNull()
      .references(() => brands.id, { onDelete: "cascade" }),
    name: text("name").notNull(),
    bodyType: text("body_type"),
    yearStart: integer("year_start"),
    yearEnd: integer("year_end"),
    notes: text("notes"),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .default(sql`now()`),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .notNull()
      .default(sql`now()`),
  },
  (t) => ({
    brandIdx: index("idx_models_brand").on(t.brandId, t.name),
    brandNameUnq: uniqueIndex("idx_models_brand_name").on(t.brandId, t.name),
  }),
);

export const insuranceTypeList = ["insurance", "casco", "both"] as const;
export type InsuranceType = (typeof insuranceTypeList)[number];

export const insuranceCompanies = pgTable(
  "insurance_companies",
  {
    id: serial("id").primaryKey(),
    name: text("name").notNull(),
    type: text("type").notNull().default("both"),
    phone: text("phone"),
    email: text("email"),
    website: text("website"),
    address: text("address"),
    notes: text("notes"),
    active: boolean("active").notNull().default(true),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .default(sql`now()`),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .notNull()
      .default(sql`now()`),
  },
  (t) => ({
    activeIdx: index("idx_insurance_active").on(t.active, t.name),
  }),
);

/** Firebase custom claims rolü (DB'de tablo yok; sadece tip tarafı) */
export const firebaseRoleList = ["admin", "operator", "viewer"] as const;
export type FirebaseRole = (typeof firebaseRoleList)[number];
