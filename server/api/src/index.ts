import { readFileSync } from "node:fs";
import path from "node:path";
import jwt from "@fastify/jwt";
import multipart from "@fastify/multipart";
import Fastify from "fastify";
import { ZodError } from "zod";
import { authRoutes, ensureAdmin } from "./auth.ts";
import { migrate } from "./db.ts";
import { liveRoutes } from "./live.ts";
import { addressRoutes } from "./routes/addresses.ts";
import { adminRoutes } from "./routes/admin.ts";
import { catalogRoutes } from "./routes/catalog.ts";
import { orderRoutes } from "./routes/orders.ts";

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

app.get("/health", async () => ({ ok: true }));
await app.register(liveRoutes);
await app.register(authRoutes);
await app.register(catalogRoutes);
await app.register(addressRoutes);
await app.register(orderRoutes);
await app.register(adminRoutes);

await app.listen({ host: process.env.HOST ?? "127.0.0.1", port: Number(process.env.PORT ?? 3000) });
