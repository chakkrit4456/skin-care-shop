import type { FastifyInstance } from "fastify";
import { z } from "zod";
import { requireAdmin, userCols } from "../auth.ts";
import { query, tx } from "../db.ts";
import { publish } from "../live.ts";
import { deleteUpload, saveImageUpload } from "../uploads.ts";
import { productSelect } from "./catalog.ts";
import { getOrder, orderSelect } from "./orders.ts";

const productBody = z.object({
  name: z.string().trim().min(1).max(200),
  category_id: z.number().int().nullable().optional(),
  image_url: z.string().max(500).nullable().optional(),
  description: z.string().trim().max(2000).nullable().optional(),
  promotion: z.string().trim().max(100).nullable().optional(),
  retail_price: z.number().positive(),
  vip_price: z.number().positive().nullable().optional(),
  active: z.boolean().default(true),
  price_tiers: z
    .array(z.object({ min_qty: z.number().int().min(1), unit_price: z.number().positive(), for_role: z.enum(["all", "vip"]) }))
    .default([]),
});

const categoryBody = z.object({ name: z.string().trim().min(1).max(100), sort: z.number().int().default(0) });
const orderPatch = z.object({
  status: z.enum(["pending", "confirmed", "shipped", "cancelled"]).optional(),
  tracking_no: z.string().trim().max(100).nullable().optional(),
});
const userPatch = z.object({ role: z.enum(["customer", "vip", "admin"]) });
const idParam = z.object({ id: z.coerce.number().int() });

export async function adminRoutes(app: FastifyInstance) {
  app.addHook("preHandler", requireAdmin);

  // ---- products ----
  async function saveProduct(id: number | null, raw: unknown) {
    const b = productBody.parse(raw);
    const tierKeys = new Set(b.price_tiers.map((t) => `${t.min_qty}:${t.for_role}`));
    if (tierKeys.size !== b.price_tiers.length) throw Object.assign(new Error("เรทราคาซ้ำ"), { statusCode: 400 });

    const productId = await tx(async (c) => {
      const vals = [
        b.name, b.category_id ?? null, b.image_url ?? null, b.retail_price, b.vip_price ?? null, b.active,
        b.description || null, b.promotion || null,
      ];
      let pid = id;
      if (pid == null) {
        const r = await c.query(
          `insert into products (name, category_id, image_url, retail_price, vip_price, active, description, promotion)
           values ($1,$2,$3,$4,$5,$6,$7,$8) returning id`,
          vals,
        );
        pid = r.rows[0].id as number;
      } else {
        const r = await c.query(
          `update products set name=$1, category_id=$2, image_url=$3, retail_price=$4, vip_price=$5, active=$6,
             description=$7, promotion=$8 where id=$9`,
          [...vals, pid],
        );
        if (r.rowCount === 0) throw Object.assign(new Error("not found"), { statusCode: 404 });
        await c.query("delete from price_tiers where product_id = $1", [pid]);
      }
      for (const t of b.price_tiers) {
        await c.query("insert into price_tiers (product_id, min_qty, unit_price, for_role) values ($1,$2,$3,$4)", [
          pid, t.min_qty, t.unit_price, t.for_role,
        ]);
      }
      return pid;
    });
    const [p] = await query(`${productSelect} where p.id = $1`, [productId]);
    publish("products");
    return p;
  }

  app.post("/admin/products", async (req) => saveProduct(null, req.body));
  app.put("/admin/products/:id", async (req) => saveProduct(idParam.parse(req.params).id, req.body));
  app.delete("/admin/products/:id", async (req) => {
    const { id } = idParam.parse(req.params);
    const [p] = await query("delete from products where id = $1 returning image_url", [id]);
    await deleteUpload(p?.image_url);
    publish("products");
    return { ok: true };
  });

  app.post("/admin/upload", async (req) => ({ url: await saveImageUpload(req) }));

  // ---- categories ----
  app.post("/admin/categories", async (req) => {
    const b = categoryBody.parse(req.body);
    const [c] = await query("insert into categories (name, sort) values ($1, $2) returning *", [b.name, b.sort]);
    publish("categories");
    return c;
  });
  app.put("/admin/categories/:id", async (req) => {
    const { id } = idParam.parse(req.params);
    const b = categoryBody.parse(req.body);
    const [c] = await query("update categories set name=$1, sort=$2 where id=$3 returning *", [b.name, b.sort, id]);
    publish("categories");
    return c;
  });
  app.delete("/admin/categories/:id", async (req) => {
    await query("delete from categories where id = $1", [idParam.parse(req.params).id]);
    publish("categories", "products");
    return { ok: true };
  });

  // ---- orders ----
  app.get("/admin/orders", async (req) => {
    const { status } = z.object({ status: z.string().optional() }).parse(req.query);
    return status
      ? query(`${orderSelect} where o.status = $1::order_status order by o.created_at desc limit 200`, [status])
      : query(`${orderSelect} order by o.created_at desc limit 200`);
  });
  app.patch("/admin/orders/:id", async (req) => {
    const { id } = idParam.parse(req.params);
    const b = orderPatch.parse(req.body);
    await query(
      `update orders set status = coalesce($1::order_status, status),
         tracking_no = case when $2::boolean then $3 else tracking_no end
       where id = $4`,
      [b.status ?? null, b.tracking_no !== undefined, b.tracking_no ?? null, id],
    );
    publish("orders");
    return getOrder(id);
  });
  app.delete("/admin/orders/:id", async (req, reply) => {
    const { id } = idParam.parse(req.params);
    const [gone] = await query("delete from orders where id = $1 returning id", [id]);
    if (!gone) return reply.code(404).send({ error: "not found" });
    publish("orders");
    return { ok: true };
  });

  // ---- users ----
  app.get("/admin/users", async () => query(`select ${userCols} from users order by created_at desc`));
  app.patch("/admin/users/:id", async (req, reply) => {
    const { id } = idParam.parse(req.params);
    if (id === req.user.id) return reply.code(400).send({ error: "เปลี่ยนสิทธิ์ตัวเองไม่ได้" });
    const b = userPatch.parse(req.body);
    const [u] = await query(`update users set role = $1 where id = $2 returning ${userCols}`, [b.role, id]);
    // role affects which prices a user sees
    publish("users", "products");
    return u;
  });
}
