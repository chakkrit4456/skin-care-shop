import ExcelJS from "exceljs";
import type { FastifyInstance } from "fastify";
import { z } from "zod";
import { requireAdmin } from "../auth.ts";
import { query, tx } from "../db.ts";
import { publish } from "../live.ts";
import { deleteUpload, saveImageBuffer } from "../uploads.ts";

type Field = "image" | "name" | "price" | "vip" | "promo" | "category" | "desc";

// Matched against header text (lower-cased, spaces removed). Order matters: vip before price.
const headerRules: [Field, RegExp][] = [
  ["image", /รูป|image|photo|picture/],
  ["name", /ชื่อ|name|product/],
  ["vip", /vip|ราคาส่ง|wholesale/],
  ["price", /ราคา|price/],
  ["promo", /โปร|promo/],
  ["category", /หมวด|category/],
  ["desc", /รายละเอียด|description|detail/],
];

// Layout of the original price list: ลำดับ | รูปภาพ | ชื่อสินค้า | ราคา | โปรโมชั่น | หมวดหมู่ | รายละเอียด
const fallback: Partial<Record<Field, number>> = { image: 2, name: 3, price: 4, promo: 5, category: 6, desc: 7 };

const TEMPLATE_HEADERS = ["ลำดับ", "รูปภาพ", "ชื่อสินค้า", "ราคา (บาท)", "โปรโมชั่น", "หมวดหมู่", "รายละเอียดสินค้า", "ราคา VIP"];

function cellText(v: ExcelJS.CellValue): string {
  if (v == null) return "";
  if (typeof v === "object") {
    if ("richText" in v) return v.richText.map((r) => r.text).join("");
    if ("result" in v) return cellText(v.result as ExcelJS.CellValue);
    if ("text" in v) return String(v.text);
    if (v instanceof Date) return v.toISOString();
  }
  return String(v).trim();
}

function toPrice(v: ExcelJS.CellValue): number | null {
  const n = typeof v === "number" ? v : parseFloat(cellText(v).replace(/[,฿\s]|บาท/g, ""));
  return Number.isFinite(n) && n > 0 ? Math.round(n * 100) / 100 : null;
}

function findColumns(ws: ExcelJS.Worksheet) {
  for (let r = 1; r <= Math.min(10, ws.rowCount); r++) {
    const cols: Partial<Record<Field, number>> = {};
    ws.getRow(r).eachCell((cell, c) => {
      const h = cellText(cell.value).toLowerCase().replace(/\s/g, "");
      if (!h) return;
      for (const [field, re] of headerRules) {
        if (cols[field] == null && re.test(h)) {
          cols[field] = c;
          break;
        }
      }
    });
    if (cols.name && cols.price) return { cols, headerRow: r };
  }
  return { cols: fallback, headerRow: 1 };
}

export async function productImportRoutes(app: FastifyInstance) {
  // The blank template holds no shop data, so it is public: a browser link can download it.
  app.get("/admin/products/import-template", async (_req, reply) => {
    const wb = new ExcelJS.Workbook();
    const ws = wb.addWorksheet("สินค้า");
    ws.addRow(TEMPLATE_HEADERS).font = { bold: true };
    ws.addRow([1, "", "ครีมตัวอย่าง 30ml", 290, "ซื้อ 2 แถม 1", "สกินแคร์", "วางรูปในช่องรูปภาพได้เลย", 250]);
    ws.columns.forEach((c, i) => (c.width = [8, 14, 34, 12, 18, 16, 40, 12][i]));
    const buf = await wb.xlsx.writeBuffer();
    return reply
      .header("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
      .header("Content-Disposition", 'attachment; filename="product-template.xlsx"')
      .send(Buffer.from(buf));
  });

  app.post("/admin/products/import", { preHandler: requireAdmin }, async (req, reply) => {
    const { mode } = z.object({ mode: z.enum(["skip", "update"]).default("skip") }).parse(req.query);
    const file = await req.file({ limits: { fileSize: 25 * 1024 * 1024 } });
    if (!file) return reply.code(400).send({ error: "ไม่พบไฟล์" });
    const data = await file.toBuffer();
    if (file.file.truncated) return reply.code(413).send({ error: "ไฟล์ใหญ่เกิน 25MB" });
    if (!/\.xlsx$/i.test(file.filename)) return reply.code(400).send({ error: "รองรับเฉพาะไฟล์ .xlsx" });

    const wb = new ExcelJS.Workbook();
    try {
      await wb.xlsx.load(data as any);
    } catch {
      return reply.code(400).send({ error: "อ่านไฟล์ Excel ไม่ได้" });
    }
    const ws = wb.worksheets[0];
    if (!ws) return reply.code(400).send({ error: "ไฟล์ไม่มีชีต" });
    const { cols, headerRow } = findColumns(ws);

    // Pictures placed over a row belong to that row (1-based).
    const media = (wb.model as any).media as { buffer: Buffer; extension: string }[] | undefined;
    const images = new Map<number, { buffer: Buffer; extension: string }>();
    for (const img of ws.getImages()) {
      const m = media?.[Number(img.imageId)];
      const row = Math.floor(img.range.tl.nativeRow ?? img.range.tl.row) + 1;
      if (m && !images.has(row)) images.set(row, m);
    }

    const categories = new Map<string, number>(
      (await query<{ id: number; name: string }>("select id, name from categories")).map((c) => [c.name, c.id]),
    );
    const existing = new Map<string, number>(
      (await query<{ id: number; name: string }>("select id, name from products")).map((p) => [p.name.toLowerCase(), p.id]),
    );

    const result = { added: 0, updated: 0, skipped: 0, errors: [] as string[] };
    const get = (row: ExcelJS.Row, f: Field) => (cols[f] ? row.getCell(cols[f]!).value : null);

    for (let r = headerRow + 1; r <= ws.rowCount; r++) {
      const row = ws.getRow(r);
      const name = cellText(get(row, "name")).slice(0, 200);
      if (!name) continue;
      const price = toPrice(get(row, "price"));
      if (price == null) {
        result.errors.push(`แถว ${r}: ${name} — ไม่มีราคา`);
        continue;
      }
      const id = existing.get(name.toLowerCase());
      if (id && mode === "skip") {
        result.skipped++;
        continue;
      }
      const vip = toPrice(get(row, "vip"));
      const promo = cellText(get(row, "promo")).slice(0, 100) || null;
      const desc = cellText(get(row, "desc")).slice(0, 2000) || null;
      const catName = cellText(get(row, "category")).split(" - ")[0].trim().slice(0, 100);
      try {
        let categoryId: number | null = null;
        if (catName) {
          categoryId = categories.get(catName) ?? null;
          if (categoryId == null) {
            const [c] = await query<{ id: number }>(
              "insert into categories (name, sort) values ($1, $2) on conflict (name) do update set name = excluded.name returning id",
              [catName, categories.size + 1],
            );
            categoryId = c.id;
            categories.set(catName, categoryId);
          }
        }
        const pic = images.get(r);
        const imageUrl = pic ? await saveImageBuffer(pic.buffer, pic.extension) : null;
        await tx(async (c) => {
          if (id) {
            const old = imageUrl ? (await c.query("select image_url from products where id=$1", [id])).rows[0]?.image_url : null;
            if (old && old !== imageUrl) await deleteUpload(old);
            await c.query(
              `update products set retail_price=$1, vip_price=coalesce($2, vip_price), promotion=$3, description=coalesce($4, description),
                 category_id=coalesce($5, category_id), image_url=coalesce($6, image_url) where id=$7`,
              [price, vip, promo, desc, categoryId, imageUrl, id],
            );
          } else {
            const ins = await c.query(
              `insert into products (name, category_id, image_url, retail_price, vip_price, active, description, promotion)
               values ($1,$2,$3,$4,$5,true,$6,$7) returning id`,
              [name, categoryId, imageUrl, price, vip, desc, promo],
            );
            existing.set(name.toLowerCase(), ins.rows[0].id);
          }
        });
        id ? result.updated++ : result.added++;
      } catch (e) {
        result.errors.push(`แถว ${r}: ${name} — ${(e as Error).message}`);
      }
    }

    if (result.added || result.updated) publish("products", "categories");
    return result;
  });
}
