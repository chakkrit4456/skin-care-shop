import bcrypt from "bcryptjs";
import type { FastifyInstance, FastifyReply, FastifyRequest } from "fastify";
import { z } from "zod";
import { query } from "./db.ts";
import { publish } from "./live.ts";
import { deleteUpload, saveImageUpload } from "./uploads.ts";

export type Role = "customer" | "vip" | "admin";
export type JwtUser = { id: number; role: Role };

declare module "@fastify/jwt" {
  interface FastifyJWT {
    payload: { id: number };
    user: JwtUser;
  }
}

export const userCols = "id, username, name, phone, avatar_url, role, created_at";

/** Loads the current role from the DB so role changes apply immediately. */
export async function requireUser(req: FastifyRequest, reply: FastifyReply) {
  try {
    const { id } = await req.jwtVerify<{ id: number }>();
    const [u] = await query<JwtUser>("select id, role from users where id = $1", [id]);
    if (!u) return reply.code(401).send({ error: "unauthorized" });
    req.user = u;
  } catch {
    return reply.code(401).send({ error: "unauthorized" });
  }
}

export async function requireAdmin(req: FastifyRequest, reply: FastifyReply) {
  await requireUser(req, reply);
  if (reply.sent) return;
  if (req.user.role !== "admin") return reply.code(403).send({ error: "admin only" });
}

/** Optional auth: sets req.user if a valid token is present. */
export async function optionalUser(req: FastifyRequest) {
  if (!req.headers.authorization) return;
  try {
    const { id } = await req.jwtVerify<{ id: number }>();
    const [u] = await query<JwtUser>("select id, role from users where id = $1", [id]);
    if (u) req.user = u;
  } catch {
    /* anonymous */
  }
}

const registerBody = z.object({
  name: z.string().trim().min(1).max(100),
  username: z.string().trim().regex(/^[a-zA-Z0-9_.]{3,30}$/),
  password: z.string().min(8).max(100),
  phone: z.string().trim().max(30).optional().nullable(),
});

const profileBody = registerBody.omit({ password: true });
const passwordBody = z.object({ current_password: z.string(), new_password: z.string().min(8).max(100) });

const loginBody = z.object({ username: z.string().trim(), password: z.string() });

export async function ensureAdmin(username?: string, password?: string, syncPassword = false) {
  if (!username || !password) return;
  const [existing] = await query<{ id: number; password_hash: string }>(
    "select id, password_hash from users where lower(username) = lower($1)",
    [username],
  );
  if (existing) {
    if (!syncPassword) return;
    if (!(await bcrypt.compare(password, existing.password_hash))) {
      await query("update users set password_hash = $1, role = 'admin' where id = $2", [await bcrypt.hash(password, 10), existing.id]);
      console.log(`reset admin ${username} password from env`);
    }
    return;
  }
  await query("insert into users (username, password_hash, name, role) values ($1, $2, $1, 'admin')", [
    username.toLowerCase(),
    await bcrypt.hash(password, 10),
  ]);
  console.log(`created admin ${username}`);
}

export async function authRoutes(app: FastifyInstance) {
  const token = (id: number) => app.jwt.sign({ id }, { expiresIn: "30d" });

  app.post("/auth/register", async (req, reply) => {
    const b = registerBody.parse(req.body);
    const username = b.username.toLowerCase();
    const [taken] = await query("select 1 from users where lower(username) = $1", [username]);
    if (taken) return reply.code(409).send({ error: "ชื่อผู้ใช้นี้ถูกใช้แล้ว" });
    const [user] = await query(
      `insert into users (username, password_hash, name, phone) values ($1, $2, $3, $4) returning ${userCols}`,
      [username, await bcrypt.hash(b.password, 10), b.name, b.phone || null],
    );
    publish("users");
    return { token: token(user.id), user };
  });

  app.post("/auth/login", async (req, reply) => {
    const b = loginBody.parse(req.body);
    const [row] = await query(`select ${userCols}, password_hash from users where lower(username) = lower($1)`, [b.username]);
    if (!row || !(await bcrypt.compare(b.password, row.password_hash))) {
      return reply.code(401).send({ error: "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง" });
    }
    const { password_hash: _, ...user } = row;
    return { token: token(user.id), user };
  });

  app.get("/me", { preHandler: requireUser }, async (req) => {
    const [user] = await query(`select ${userCols} from users where id = $1`, [req.user.id]);
    return user;
  });

  app.patch("/me", { preHandler: requireUser }, async (req, reply) => {
    const b = profileBody.parse(req.body);
    const username = b.username.toLowerCase();
    const [taken] = await query("select 1 from users where lower(username) = $1 and id <> $2", [username, req.user.id]);
    if (taken) return reply.code(409).send({ error: "ชื่อผู้ใช้นี้มีคนใช้แล้ว" });
    const [user] = await query(`update users set name = $1, username = $2, phone = $3 where id = $4 returning ${userCols}`, [
      b.name, username, b.phone || null, req.user.id,
    ]);
    publish("users", "orders");
    return user;
  });

  app.post("/me/password", { preHandler: requireUser }, async (req, reply) => {
    const b = passwordBody.parse(req.body);
    const [row] = await query<{ password_hash: string }>("select password_hash from users where id = $1", [req.user.id]);
    if (!(await bcrypt.compare(b.current_password, row.password_hash))) {
      return reply.code(400).send({ error: "รหัสผ่านปัจจุบันไม่ถูกต้อง" });
    }
    await query("update users set password_hash = $1 where id = $2", [await bcrypt.hash(b.new_password, 10), req.user.id]);
    return { ok: true };
  });

  app.post("/me/avatar", { preHandler: requireUser }, async (req) => {
    const url = await saveImageUpload(req);
    const [old] = await query<{ avatar_url: string | null }>("select avatar_url from users where id = $1", [req.user.id]);
    const [user] = await query(`update users set avatar_url = $1 where id = $2 returning ${userCols}`, [url, req.user.id]);
    await deleteUpload(old?.avatar_url);
    publish("users");
    return user;
  });

  app.delete("/me/avatar", { preHandler: requireUser }, async (req) => {
    const [old] = await query<{ avatar_url: string | null }>("select avatar_url from users where id = $1", [req.user.id]);
    const [user] = await query(`update users set avatar_url = null where id = $1 returning ${userCols}`, [req.user.id]);
    await deleteUpload(old?.avatar_url);
    publish("users");
    return user;
  });
}
