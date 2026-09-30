import type { FastifyInstance } from "fastify";
import { z } from "zod";
import { requireUser } from "../auth.ts";
import { query, tx } from "../db.ts";
import { notifyNewOrder } from "../line.ts";
import { publish } from "../live.ts";

export const orderSelect = `
  select o.*,
    coalesce((select json_agg(json_build_object('product_name', i.product_name, 'qty', i.qty, 'unit_price_snapshot', i.unit_price_snapshot) order by i.id)
      from order_items i where i.order_id = o.id), '[]') as order_items,
    (select json_build_object('id', u.id, 'username', u.username, 'name', u.name, 'phone', u.phone, 'role', u.role)
      from users u where u.id = o.user_id) as customer
  from orders o`;

const orderBody = z.object({
  items: z.array(z.object({ product_id: z.number().int(), qty: z.number().int().min(1).max(100000) })).min(1).max(200),
  note: z.string().trim().max(1000).optional().nullable(),
  address_id: z.number().int(),
});

export async function getOrder(id: number) {
  const [o] = await query(`${orderSelect} where o.id = $1`, [id]);
  return o;
}

export async function orderRoutes(app: FastifyInstance) {
  app.post("/orders", { preHandler: requireUser }, async (req, reply) => {
    const b = orderBody.parse(req.body);
    const [addr] = await query("select * from addresses where id = $1 and user_id = $2", [b.address_id, req.user.id]);
    if (!addr) return reply.code(400).send({ error: "need_address" });
    let id: number;
    try {
      id = await tx(async (c) => {
        const r = await c.query("select create_order($1, $2::jsonb, $3) as id", [req.user.id, JSON.stringify(b.items), b.note || null]);
        return r.rows[0].id as number;
      });
    } catch (e: any) {
      return reply.code(400).send({ error: e.message });
    }
    await query(
      `update orders set ship_recipient=$1, ship_phone=$2, ship_line=$3, ship_subdistrict=$4,
         ship_district=$5, ship_province=$6, ship_postal=$7 where id=$8`,
      [addr.recipient_name, addr.phone, addr.address_line, addr.subdistrict, addr.district, addr.province, addr.postal_code, id],
    );
    const order = await getOrder(id);
    publish("orders");
    notifyNewOrder(order).catch((e) => req.log.error(e, "LINE notify failed"));
    return order;
  });

  app.get("/orders/mine", { preHandler: requireUser }, async (req) =>
    query(`${orderSelect} where o.user_id = $1 order by o.created_at desc limit 200`, [req.user.id]),
  );
}
