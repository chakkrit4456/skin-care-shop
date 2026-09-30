import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import pg from "pg";

// numeric and bigint come back as strings by default
pg.types.setTypeParser(1700, (v) => parseFloat(v));
pg.types.setTypeParser(20, (v) => parseInt(v, 10));

export const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });

export async function query<T extends pg.QueryResultRow = any>(sql: string, params: unknown[] = []) {
  return (await pool.query<T>(sql, params)).rows;
}

export async function tx<T>(fn: (c: pg.PoolClient) => Promise<T>): Promise<T> {
  const c = await pool.connect();
  try {
    await c.query("begin");
    const r = await fn(c);
    await c.query("commit");
    return r;
  } catch (e) {
    await c.query("rollback");
    throw e;
  } finally {
    c.release();
  }
}

/** Applies db/*.sql in name order, each once. Set SKIP_SEED=true to skip *_seed.sql. */
export async function migrate(dir: string) {
  await pool.query("create table if not exists schema_migrations (name text primary key, applied_at timestamptz default now())");
  const done = new Set((await query<{ name: string }>("select name from schema_migrations")).map((r) => r.name));
  const files = (await readdir(dir)).filter((f) => f.endsWith(".sql")).sort();
  for (const f of files) {
    if (done.has(f)) continue;
    if (process.env.SKIP_SEED === "true" && f.includes("seed")) continue;
    const sql = await readFile(path.join(dir, f), "utf8");
    await tx(async (c) => {
      await c.query(sql);
      await c.query("insert into schema_migrations (name) values ($1)", [f]);
    });
    console.log(`migrated ${f}`);
  }
}
