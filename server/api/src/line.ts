const baht = (n: number) => "฿" + Number(n).toLocaleString("th-TH");

export async function notifyNewOrder(order: any) {
  const token = process.env.LINE_CHANNEL_ACCESS_TOKEN;
  const to = process.env.LINE_TARGET_ID;
  if (!token || !to || !order) return;

  const c = order.customer ?? {};
  const text = [
    `🛒 ออเดอร์ใหม่ #${order.id}`,
    `ลูกค้า: ${c.name || "-"} (${c.username})${c.phone ? " โทร " + c.phone : ""}`,
    order.ship_recipient
      ? `ที่อยู่: ${order.ship_recipient} ${order.ship_phone}\n${order.ship_line} ${order.ship_subdistrict} ${order.ship_district} ${order.ship_province} ${order.ship_postal}`.trim()
      : "",
    ...order.order_items.map(
      (i: any) => `• ${i.product_name} x${i.qty} @${baht(i.unit_price_snapshot)} = ${baht(i.qty * i.unit_price_snapshot)}`,
    ),
    `รวม ${baht(order.total)}`,
    order.note ? `หมายเหตุ: ${order.note}` : "",
  ].filter(Boolean).join("\n");

  const res = await fetch("https://api.line.me/v2/bot/message/push", {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
    body: JSON.stringify({ to, messages: [{ type: "text", text }] }),
  });
  if (!res.ok) throw new Error(`LINE ${res.status}: ${await res.text()}`);
}
