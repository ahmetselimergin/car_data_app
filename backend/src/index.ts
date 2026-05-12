import "dotenv/config";

import cors from "cors";
import express from "express";
import helmet from "helmet";

import { errorHandler } from "./middleware/errorHandler.js";
import { UPLOAD_ROOT } from "./middleware/upload.js";
import { brandsRouter } from "./routes/brands.js";
import { carsRouter } from "./routes/cars.js";
import { firebaseUsersRouter } from "./routes/firebaseUsers.js";
import { insuranceRouter } from "./routes/insurance.js";
import { modelsRouter } from "./routes/models.js";
import { workshopsRouter } from "./routes/workshops.js";

const app = express();
const port = Number(process.env.PORT ?? 4000);
const corsOrigin = process.env.CORS_ORIGIN ?? "http://localhost:3000";

app.use(
  helmet({
    // Admin (3000/3002) farklı origin'den /uploads görsellerini çekebilsin.
    crossOriginResourcePolicy: { policy: "cross-origin" },
  }),
);
app.use(
  cors({
    origin: corsOrigin.split(",").map((s) => s.trim()),
    credentials: true,
  }),
);
app.use(express.json({ limit: "2mb" }));
// Yüklenen logo/görseller; CORS olmadan da img tag çalışır
app.use("/uploads", express.static(UPLOAD_ROOT, { fallthrough: true, maxAge: "1d" }));

app.get("/health", (_req, res) => {
  res.json({ ok: true, service: "cardex-api", ts: new Date().toISOString() });
});

app.get("/api/v1", (_req, res) => {
  res.json({
    name: "CarDEX API",
    version: "1.0.0",
    endpoints: [
      "GET/POST/PATCH/DELETE /api/v1/cars",
      "GET/POST/PATCH/DELETE /api/v1/brands",
      "GET/POST/PATCH/DELETE /api/v1/models",
      "GET/POST/PATCH/DELETE /api/v1/workshops",
      "GET/POST/PATCH/DELETE /api/v1/insurance",
      "GET/PATCH/DELETE /api/v1/firebase-users (Firebase Auth)",
    ],
  });
});

app.use("/api/v1/cars", carsRouter);
app.use("/api/v1/brands", brandsRouter);
app.use("/api/v1/models", modelsRouter);
app.use("/api/v1/workshops", workshopsRouter);
app.use("/api/v1/insurance", insuranceRouter);
app.use("/api/v1/firebase-users", firebaseUsersRouter);

app.use(errorHandler);

app.listen(port, () => {
  console.log(`cardex-api → http://localhost:${port}`);
});
