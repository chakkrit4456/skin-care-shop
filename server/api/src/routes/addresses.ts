import type { FastifyInstance } from "fastify";
import { z } from "zod";
import { requireUser } from "../auth.ts";
import { query, tx } from "../db.ts";
import { publish } from "../live.ts";

const addressBody = z.object({
  label: z.string().trim().max(50).default(""),
  recipient_name: z.string().trim().min(1).max(100),
  phone: z.string().trim().min(1).max(30),
  address_line: z.string().trim().min(1).max(300),
  subdistrict: z.string().trim().max(100).default(""),
  district: z.string().trim().max(100).default(""),
  province: z.string().trim().min(1).max(100),
  postal_code: z.string().trim().max(10).default(""),
  is_default: z.boolean().default(false),
});

const cols = "id, label, recipient_name, phone, address_line, subdistrict, district, province, postal_code, is_default";

export async function addressRoutes(app: FastifyInstance) {
  app.addHook("preHandler", requireUser);

  app.get("/me/addresses", async (req) =>
    query(`select ${cols} from addresses where user_id = $1 order by is_default desc, id`, [req.user.id]),
  );

  async function save(id: number | null, userId: number, raw: unknown) {
    const b = addressBody.parse(raw);
    return tx(async (c) => {
      const [{ n }] = (await c.query("select count(*)::int as n from addresses where user_id = $1", [userId])).rows;
      const makeDefault = b.is_default || n === 0 || (id != null && n === 1);
      if (makeDefault) await c.query("update addresses set is_default = false where user_id = $1", [userId]);
      const vals = [b.label, b.recipient_name, b.phone, b.address_line, b.subdistrict, b.district, b.province, b.postal_code, makeDefault];
      const r = id == null
        ? await c.query(
            `insert into addresses (user_id, label, recipient_name, phone, address_line, subdistrict, district, province, postal_code, is_default)
             values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) returning ${cols}`,
            [userId, ...vals],
          )
        : await c.query(
            `update addresses set label=$2, recipient_name=$3, phone=$4, address_line=$5, subdistrict=$6, district=$7,
               province=$8, postal_code=$9, is_default=$10 where id=$11 and user_id=$1 returning ${cols}`,
            [userId, ...vals, id],
          );
      if (r.rowCount === 0) throw Object.assign(new Error("address_not_found"), { statusCode: 404 });
      return r.rows[0];
    });
  }

  app.post("/me/addresses", async (req) => {
    const row = await save(null, req.user.id, req.body);
    publish("addresses");
    return row;
  });

  app.put("/me/addresses/:id", async (req) => {
    const id = z.object({ id: z.coerce.number().int() }).parse(req.params).id;
    const row = await save(id, req.user.id, req.body);
    publish("addresses");
    return row;
  });

  app.delete("/me/addresses/:id", async (req) => {
    const id = z.object({ id: z.coerce.number().int() }).parse(req.params).id;
    const [gone] = await query("delete from addresses where id = $1 and user_id = $2 returning is_default", [id, req.user.id]);
    if (gone?.is_default) {
      await query(
        "update addresses set is_default = true where id = (select id from addresses where user_id = $1 order by id limit 1)",
        [req.user.id],
      );
    }
    publish("addresses");
    return { ok: true };
  });
}
