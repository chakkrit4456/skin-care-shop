// End-to-end check against a running API on a freshly seeded DB.
// docker compose exec -T api node --input-type=module - < api/test/smoke.mjs
const base = process.env.API ?? "http://localhost:3000";
const admin = { username: process.env.ADMIN_USERNAME, password: process.env.ADMIN_PASSWORD };
let failed = 0;

async function call(method, path, body, token) {
  const res = await fetch(base + path, {
    method,
    headers: { ...(body ? { "Content-Type": "application/json" } : {}), ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: res.status, body: await res.json().catch(() => null) };
}

function check(name, cond, detail) {
  console.log(`${cond ? "PASS" : "FAIL"} ${name}${cond ? "" : " -> " + JSON.stringify(detail)}`);
  if (!cond) failed++;
}

const u = `smoke${Date.now() % 100000}`;
const reg = await call("POST", "/auth/register", { name: "Smoke", username: u, password: "password123" });
check("register", reg.status === 200 && reg.body.token, reg);
const dup = await call("POST", "/auth/register", { name: "x", username: u.toUpperCase(), password: "password123" });
check("duplicate username rejected", dup.status === 409, dup);
check("short password rejected", (await call("POST", "/auth/register", { name: "x", username: u + "b", password: "short" })).status === 400);

const login = await call("POST", "/auth/login", { username: u, password: "password123" });
check("login", login.status === 200, login);
check("wrong password", (await call("POST", "/auth/login", { username: u, password: "nope12345" })).status === 401);
const tok = login.body.token;

const me = await call("GET", "/me", null, tok);
check("me is customer", me.body?.role === "customer", me);

const products = await call("GET", "/products");
const cream = products.body.find((p) => p.retail_price === 29 && p.vip_price === 25);
check("products with tiers", cream && cream.price_tiers.length === 3 && typeof cream.retail_price === "number", cream);

check("orders need login", (await call("POST", "/orders", { items: [{ product_id: cream.id, qty: 1 }] })).status === 401);
check("admin route forbidden", (await call("GET", "/admin/users", null, tok)).status === 403);

// retail 29, 5+ = 26, 10+ = 24, vip 1 = 25, vip 10+ = 22
const order = await call("POST", "/orders", { items: [{ product_id: cream.id, qty: 4 }, { product_id: cream.id, qty: 10 }], note: "test" }, tok);
const prices = order.body?.order_items?.map((i) => i.unit_price_snapshot);
check("customer tier prices", JSON.stringify(prices) === "[29,24]" && order.body.total === 29 * 4 + 240, order.body);
check("empty cart rejected", (await call("POST", "/orders", { items: [] }, tok)).status === 400);

const adm = await call("POST", "/auth/login", admin);
check("admin login", adm.status === 200, adm);
const at = adm.body.token;

const promote = await call("PATCH", `/admin/users/${me.body.id}`, { role: "vip" }, at);
check("promote to vip", promote.body?.role === "vip", promote);
check("admin cannot change own role", (await call("PATCH", `/admin/users/${adm.body.user.id}`, { role: "customer" }, at)).status === 400);

const vipOrder = await call("POST", "/orders", { items: [{ product_id: cream.id, qty: 1 }, { product_id: cream.id, qty: 10 }] }, tok);
check("vip prices", JSON.stringify(vipOrder.body?.order_items?.map((i) => i.unit_price_snapshot)) === "[25,22]", vipOrder.body);

const created = await call("POST", "/admin/products", {
  name: "Smoke product", retail_price: 100, active: true,
  price_tiers: [{ min_qty: 5, unit_price: 90, for_role: "all" }, { min_qty: 20, unit_price: 80, for_role: "all" }],
}, at);
check("admin create product", created.body?.price_tiers?.length === 2, created);
const updated = await call("PUT", `/admin/products/${created.body.id}`, {
  name: "Smoke product 2", retail_price: 100, active: false, price_tiers: [{ min_qty: 3, unit_price: 95, for_role: "all" }],
}, at);
check("admin update replaces tiers", updated.body?.price_tiers?.length === 1 && updated.body.name === "Smoke product 2", updated);
const pub = await call("GET", "/products");
check("inactive hidden from public", !pub.body.some((p) => p.id === created.body.id));
check("inactive can't be ordered", (await call("POST", "/orders", { items: [{ product_id: created.body.id, qty: 1 }] }, tok)).status === 400);
check("admin delete product", (await call("DELETE", `/admin/products/${created.body.id}`, null, at)).status === 200);

const ship = await call("PATCH", `/admin/orders/${order.body.id}`, { tracking_no: "TH123" }, at);
check("tracking number", ship.body?.tracking_no === "TH123" && ship.body.status === "pending", ship.body);
const st = await call("PATCH", `/admin/orders/${order.body.id}`, { status: "shipped" }, at);
check("status keeps tracking", st.body?.status === "shipped" && st.body.tracking_no === "TH123", st.body);
const pending = await call("GET", "/admin/orders?status=pending", null, at);
check("filter orders", pending.body.every((o) => o.status === "pending") && !pending.body.some((o) => o.id === order.body.id));

const form = new FormData();
form.append("file", new Blob([Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==", "base64")], { type: "image/png" }), "a.png");
const up = await (await fetch(base + "/admin/upload", { method: "POST", headers: { Authorization: `Bearer ${at}` }, body: form })).json();
check("upload image", /^\/uploads\/.+\.png$/.test(up.url), up);
const bad = new FormData();
bad.append("file", new Blob(["hi"], { type: "text/plain" }), "a.txt");
check("upload rejects non-image", (await fetch(base + "/admin/upload", { method: "POST", headers: { Authorization: `Bearer ${at}` }, body: bad })).status === 400);

const mine = await call("GET", "/orders/mine", null, tok);
check("my orders", mine.body.length === 2 && mine.body[0].customer.username === u, mine.body.length);

console.log(failed ? `\n${failed} FAILED` : "\nALL PASSED");
process.exit(failed ? 1 : 0);
