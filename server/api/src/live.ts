import websocket from "@fastify/websocket";
import type { FastifyInstance } from "fastify";
import type { WebSocket } from "ws";

export type Topic = "products" | "categories" | "orders" | "users" | "addresses";

const clients = new Set<WebSocket>();

/** Tells every connected client which data changed; clients refetch it with their own auth. */
export function publish(...topics: Topic[]) {
  for (const topic of topics) {
    const msg = JSON.stringify({ topic });
    for (const ws of clients) if (ws.readyState === ws.OPEN) ws.send(msg);
  }
}

export async function liveRoutes(app: FastifyInstance) {
  await app.register(websocket);

  // Cloudflare drops idle websockets after ~100s
  const ping = setInterval(() => {
    for (const ws of clients) if (ws.readyState === ws.OPEN) ws.ping();
  }, 30_000);
  app.addHook("onClose", async () => clearInterval(ping));

  app.get("/live", { websocket: true }, (ws) => {
    clients.add(ws);
    ws.on("close", () => clients.delete(ws));
    ws.on("error", () => clients.delete(ws));
  });
}
