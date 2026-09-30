import { randomUUID } from "node:crypto";
import { createWriteStream } from "node:fs";
import { mkdir, unlink } from "node:fs/promises";
import path from "node:path";
import { pipeline } from "node:stream/promises";
import type { FastifyRequest } from "fastify";

export const uploadDir = process.env.UPLOAD_DIR ?? "./uploads";

const imageTypes: Record<string, string> = { "image/jpeg": "jpg", "image/png": "png", "image/webp": "webp" };

const fail = (statusCode: number, message: string) => Object.assign(new Error(message), { statusCode });

/** Saves the multipart `file` field (jpg/png/webp, max 5MB) and returns its public path. */
export async function saveImageUpload(req: FastifyRequest) {
  const file = await req.file({ limits: { fileSize: 5 * 1024 * 1024 } });
  if (!file) throw fail(400, "no file");
  const ext = imageTypes[file.mimetype];
  if (!ext) throw fail(400, "รองรับเฉพาะ jpg, png, webp");
  await mkdir(uploadDir, { recursive: true });
  const name = `${randomUUID()}.${ext}`;
  const dest = path.join(uploadDir, name);
  await pipeline(file.file, createWriteStream(dest));
  if (file.file.truncated) {
    await unlink(dest);
    throw fail(413, "ไฟล์ใหญ่เกิน 5MB");
  }
  return `/uploads/${name}`;
}

export async function deleteUpload(url: string | null | undefined) {
  if (url?.startsWith("/uploads/")) await unlink(path.join(uploadDir, path.basename(url))).catch(() => {});
}
