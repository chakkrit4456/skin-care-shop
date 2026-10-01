import { readFileSync } from "node:fs";
import { mkdir } from "node:fs/promises";
import path from "node:path";
import jwt from "@fastify/jwt";
import multipart from "@fastify/multipart";
import fastifyStatic from "@fastify/static";
import Fastify from "fastify";
import { ZodError } from "zod";
import { authRoutes, ensureAdmin } from "./auth.ts";
import { migrate } from "./db.ts";
import { liveRoutes } from "./live.ts";
import { addressRoutes } from "./routes/addresses.ts";
import { adminRoutes } from "./routes/admin.ts";
import { catalogRoutes } from "./routes/catalog.ts";
import { orderRoutes } from "./routes/orders.ts";
import { productImportRoutes } from "./routes/product-import.ts";
import { uploadDir } from "./uploads.ts";

function loadEnvFile(file: string) {
  let text: string;
  try {
    text = readFileSync(file, "utf8");
  } catch {
    return;
  }
  for (const line of text.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const eq = trimmed.indexOf("=");
    if (eq < 1) continue;
    const key = trimmed.slice(0, eq).trim();
    let value = trimmed.slice(eq + 1).trim();
    if ((value.startsWith("'") && value.endsWith("'")) || (value.startsWith('"') && value.endsWith('"'))) value = value.slice(1, -1);
    if (process.env[key] === undefined) process.env[key] = value;
  }
}

loadEnvFile(path.resolve(import.meta.dirname, "../../.env"));

const secret = process.env.JWT_SECRET;
if (!secret || secret.length < 32) throw new Error("JWT_SECRET must be at least 32 characters");

await migrate(process.env.DB_DIR ?? path.resolve(import.meta.dirname, "../../db"));
const syncAdminPassword = process.env.ADMIN_SYNC_PASSWORD === "true";
await ensureAdmin(process.env.ADMIN_USERNAME, process.env.ADMIN_PASSWORD, syncAdminPassword);

const app = Fastify({ logger: true, trustProxy: true, bodyLimit: 1024 * 1024 });
await app.register(jwt, { secret });
await app.register(multipart);

app.setErrorHandler((err: Error, _req, reply) => {
  if (err instanceof ZodError) return reply.code(400).send({ error: "ข้อมูลไม่ถูกต้อง", issues: err.issues });
  const code = (err as any).statusCode ?? 500;
  if (code >= 500) app.log.error(err);
  // unique_violation
  if ((err as any).code === "23505") return reply.code(409).send({ error: "ข้อมูลซ้ำ" });
  return reply.code(code).send({ error: code >= 500 ? "server error" : err.message });
});

// Behind Nginx the API lives at "/" (Nginx strips /api). On Render one Node process
// serves everything, so set API_PREFIX=/api and STATIC_DIR to the Flutter web build.
const apiPrefix = (process.env.API_PREFIX ?? "").replace(/\/+$/, "");
await app.register(
  async (api) => {
    api.get("/health", async () => ({ ok: true }));
    await api.register(liveRoutes);
    await api.register(authRoutes);
    await api.register(catalogRoutes);
    await api.register(addressRoutes);
    await api.register(orderRoutes);
    await api.register(adminRoutes);
    await api.register(productImportRoutes);
  },
  { prefix: apiPrefix },
);

// The Android APK is built by GitHub Actions and published as a release asset.
const apkUrl = process.env.APK_URL;
if (apkUrl) app.get("/downloads/taeia.apk", async (_req, reply) => reply.redirect(apkUrl, 302));

const staticDir = process.env.STATIC_DIR;
if (staticDir) {
  const noCache = /(^|\/)(index\.html|flutter_service_worker\.js|flutter_bootstrap\.js|main\.dart\.js|manifest\.json|version\.json)$/;
  await mkdir(uploadDir, { recursive: true });
  await app.register(fastifyStatic, {
    root: path.resolve(uploadDir),
    prefix: "/uploads/",
    decorateReply: false,
    maxAge: "30d",
    immutable: true,
  });
  await app.register(fastifyStatic, {
    root: path.resolve(staticDir),
    prefix: "/",
    wildcard: false,
    cacheControl: false,
    setHeaders: (res, file) => {
      res.setHeader("Cache-Control", noCache.test(file.replace(/\\/g, "/")) ? "no-cache" : "public, max-age=3600");
    },
  });
  // Flutter routes are client-side: unknown non-API GETs get index.html.
  app.setNotFoundHandler((req, reply) => {
    if (req.method !== "GET" || (apiPrefix && req.url.startsWith(`${apiPrefix}/`)) || req.url.startsWith("/uploads/") || req.url.startsWith("/downloads/")) {
      return reply.code(404).send({ error: "not found" });
    }
    reply.header("Cache-Control", "no-cache");
    return reply.sendFile("index.html");
  });
}

await app.listen({ host: process.env.HOST ?? "127.0.0.1", port: Number(process.env.PORT ?? 3000) });
