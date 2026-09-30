import type { FastifyInstance } from "fastify";
import { optionalUser } from "../auth.ts";
import { query } from "../db.ts";

export const productSelect = `
  select p.*, coalesce(
    (select json_agg(json_build_object('min_qty', t.min_qty, 'unit_price', t.unit_price, 'for_role', t.for_role) order by t.min_qty)
       from price_tiers t where t.product_id = p.id), '[]'
  ) as price_tiers
  from products p`;

export async function catalogRoutes(app: FastifyInstance) {
  app.get("/categories", async () => query("select * from categories order by sort, name"));

  app.get("/products", { preHandler: optionalUser }, async (req) => {
    const admin = req.user?.role === "admin";
    return query(`${productSelect} ${admin ? "" : "where p.active"} order by p.created_at desc`);
  });
}
