# เช็คราคาสินค้า (Flutter + Node API + PostgreSQL)

- `price_app/` - แอป Flutter (Android / iOS / Web)
- `server/api/` - Node.js (Fastify) API: สมาชิก JWT, สินค้า, ออเดอร์, หลังร้าน, อัปโหลดรูป, แจ้ง LINE
- `server/db/` - SQL schema (`001_init.sql`) และข้อมูลตัวอย่าง (`002_seed.sql`) รันอัตโนมัติตอน API เริ่ม
- `install.sh` - ติดตั้งบน TurnKey Node.js / Debian โดยไม่ใช้ Docker
- `index.html` - ต้นแบบเดิม (ไม่ใช้แล้ว)

```
เบราว์เซอร์ -> nginx -> /api -> Node API -> PostgreSQL
                     -> /uploads (รูปสินค้า)
                     -> ไฟล์เว็บ Flutter
```

## Deploy บน TurnKey Node.js (Debian 13)

เครื่อง TurnKey มี Node.js 20, nginx และหน้าตัวอย่างที่พอร์ต 80 อยู่แล้ว สคริปต์ไม่ทับ Node ของเครื่อง แต่ติดตั้ง Node.js 24 ที่ `/opt/node` เพิ่ม PostgreSQL แล้ว build หน้าเว็บให้เอง จากนั้นให้ร้านใช้พอร์ต 80 แทนหน้าตัวอย่าง Webmin ยังอยู่ที่พอร์ต 12321

โคลนไว้ที่ `/var/www` ได้ สคริปต์จะไม่เขียนหน้าเว็บทับโฟลเดอร์ที่โคลน

```bash
cd /var/www
git clone https://github.com/chakkrit4456/skin-care-shop.git
cd skin-care-shop
./install.sh
```

สคริปต์ถามว่าจะเปลี่ยนรหัสแอดมินหรือไม่ เปิด `http://<ip-เซิร์ฟเวอร์>/` (พอร์ตตามที่ตอบตอนติดตั้ง ค่าเริ่มต้นคือ 80)

ถ้าใช้ Cloudflare Tunnel ให้ตอบ yes แล้วตั้ง public hostname ชี้มาที่ `HTTP` `http://127.0.0.1:<พอร์ตเว็บ>`

### อัปเดตเวอร์ชัน

```bash
git pull && ./install.sh
```

### Backup (ใส่ใน crontab)

```bash
0 3 * * * runuser -u postgres -- pg_dump price | gzip > /backup/price-$(date +\%F).sql.gz
0 3 * * * tar czf /backup/uploads-$(date +\%F).tgz -C /var/lib/price-app uploads
```

## แจ้งเตือน LINE

1. LINE Developers > สร้าง Messaging API channel > ออก Channel access token
2. เชิญบอทเข้ากลุ่มร้าน แล้วหา group ID (หรือใช้ user ID ของเจ้าของร้าน)
3. ใส่ `LINE_CHANNEL_ACCESS_TOKEN`, `LINE_TARGET_ID` ใน `/etc/price-app.env` แล้ว `systemctl restart price-api`

ปุ่ม "ส่งทาง LINE" ฝั่งลูกค้าแสดงเมื่อใส่ `LINE_OA_ID` (ต้อง build web ใหม่)

## พัฒนาบนเครื่อง

```powershell
cd server
copy .env.example .env
cd api
npm install
npm start
```

API อ่าน `server/.env` เอง และฟังที่ `127.0.0.1:3000` รูปสินค้าบนเซิร์ฟเวอร์จริงเสิร์ฟโดย nginx

แอปมือถือ (ต้องติดตั้ง Flutter):

```powershell
cd price_app
flutter create . --platforms=android,ios,web --org com.yourshop   # ครั้งแรก
copy env.example.json env.json
flutter pub get
flutter test
flutter run --dart-define-from-file=env.json
flutter build appbundle --release --dart-define-from-file=env.json   # Play Store
flutter build ipa --release --dart-define-from-file=env.json         # App Store (Mac)
```

iOS: เพิ่ม `NSPhotoLibraryUsageDescription` ใน `ios/Runner/Info.plist` สำหรับเลือกรูปสินค้า

## API

| Method | Path | สิทธิ์ |
|---|---|---|
| POST | `/auth/register`, `/auth/login` | ทุกคน |
| GET | `/me`, `/orders/mine` | สมาชิก |
| GET | `/categories`, `/products` | ทุกคน |
| POST | `/orders` `{items:[{product_id,qty}], note}` | สมาชิก |
| POST/PUT/DELETE | `/admin/products[/:id]`, `/admin/categories[/:id]` | แอดมิน |
| POST | `/admin/upload` (multipart `file`, ≤5MB jpg/png/webp) | แอดมิน |
| GET/PATCH | `/admin/orders[/:id]`, `/admin/users[/:id]` | แอดมิน |

## กติกาการคิดราคา

ราคาต่อชิ้น = ราคาต่ำสุดในเรทที่จำนวนถึงขั้นต่ำ (ปลีก, ราคา VIP, เรทส่งทุกคน, เรทส่ง VIP) - โค้ดใน `price_app/lib/core/pricing.dart` และ SQL `unit_price()` ใน `server/db/001_init.sql` ต้องตรงกัน ราคาในออเดอร์คำนวณใหม่บนเซิร์ฟเวอร์เสมอ
