"""Import products (with embedded images) from an Excel sheet via the admin API.

Columns: ลำดับ | รูปภาพ | ชื่อสินค้า | ราคา (บาท) | โปรโมชั่น | หมวดหมู่ | รายละเอียดสินค้า
Category "ผิวหน้า - เจล" is stored as "ผิวหน้า". Products whose name already exists are skipped.

pip install openpyxl
python import_products.py products.xlsx --api https://chakkrit.itdev.in.th/api --user admin --password ...
"""
import argparse
import json
import sys
import urllib.error
import urllib.request
import uuid

import openpyxl

sys.stdout.reconfigure(encoding="utf-8")


class Api:
    def __init__(self, base):
        self.base = base.rstrip("/")
        self.token = None

    def _send(self, method, path, data=None, content_type="application/json"):
        headers = {"Content-Type": content_type} if data is not None else {}
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        req = urllib.request.Request(self.base + path, data=data, method=method, headers=headers)
        try:
            with urllib.request.urlopen(req) as r:
                return json.loads(r.read())
        except urllib.error.HTTPError as e:
            raise SystemExit(f"{method} {path} -> {e.code} {e.read().decode()}")

    def call(self, method, path, body=None):
        return self._send(method, path, None if body is None else json.dumps(body).encode())

    def upload(self, data: bytes, ext: str):
        boundary = uuid.uuid4().hex
        mime = "image/jpeg" if ext in ("jpg", "jpeg") else f"image/{ext}"
        body = (
            f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="img.{ext}"\r\n'
            f"Content-Type: {mime}\r\n\r\n"
        ).encode() + data + f"\r\n--{boundary}--\r\n".encode()
        return self._send("POST", "/admin/upload", body, f"multipart/form-data; boundary={boundary}")["url"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("xlsx")
    ap.add_argument("--api", default="http://localhost:8080/api")
    ap.add_argument("--user", required=True)
    ap.add_argument("--password", required=True)
    args = ap.parse_args()

    ws = openpyxl.load_workbook(args.xlsx).active
    images = {img.anchor._from.row + 1: (img._data(), img.format or "png") for img in ws._images}

    api = Api(args.api)
    api.token = api.call("POST", "/auth/login", {"username": args.user, "password": args.password})["token"]

    categories = {c["name"]: c["id"] for c in api.call("GET", "/categories")}
    existing = {p["name"] for p in api.call("GET", "/products")}
    added = skipped = 0

    for row in ws.iter_rows(min_row=2):
        _, _, name, price, promo, cat, desc = (c.value for c in row[:7])
        if not name or price is None:
            continue
        name = str(name).strip()
        if name in existing:
            print(f"skip  {name} (มีอยู่แล้ว)")
            skipped += 1
            continue

        main_cat = str(cat).split(" - ")[0].strip() if cat else None
        if main_cat and main_cat not in categories:
            categories[main_cat] = api.call("POST", "/admin/categories", {"name": main_cat, "sort": len(categories) + 1})["id"]

        image_url = None
        if row[0].row in images:
            data, ext = images[row[0].row]
            image_url = api.upload(data, ext.lower())

        api.call("POST", "/admin/products", {
            "name": name,
            "category_id": categories.get(main_cat),
            "image_url": image_url,
            "retail_price": float(price),
            "promotion": str(promo).strip() if promo else None,
            "description": str(desc).strip() if desc else None,
            "active": True,
            "price_tiers": [],
        })
        existing.add(name)
        added += 1
        print(f"added {name} ฿{price}{' [' + str(promo) + ']' if promo else ''}{'' if image_url else ' (ไม่มีรูป)'}")

    print(f"\nเพิ่ม {added} รายการ, ข้าม {skipped} รายการ")


if __name__ == "__main__":
    main()
