import 'package:flutter/widgets.dart';

import 'l10n.dart';

/// Long policy pages. Index 0 = Thai, 1 = English, 2 = Chinese.
const legalText = <String, List<String>>{
  'terms_body': [
    '''อัปเดตล่าสุด: 30 กันยายน 2026
ร้านแต๊ะเอียสกินช็อป ("ร้าน") ให้บริการแอปและเว็บไซต์สำหรับดูราคาสินค้าดูแลผิวและสั่งซื้อ ข้อกำหนดนี้เป็นสัญญาระหว่างคุณกับร้าน

1. การยอมรับ
เมื่อสมัครสมาชิก เข้าสู่ระบบ หรือสั่งซื้อ ถือว่าคุณยอมรับข้อกำหนดนี้ นโยบายความเป็นส่วนตัว และนโยบายการสั่งซื้อ หากไม่ยอมรับ กรุณาหยุดใช้บริการ

2. บัญชีผู้ใช้
คุณต้องให้ชื่อ ชื่อผู้ใช้ และรหัสผ่านที่เป็นความจริง ชื่อผู้ใช้ใช้ตัวอักษรภาษาอังกฤษ ตัวเลข จุด หรือขีดล่าง ความยาว 3–30 ตัว รหัสผ่านอย่างน้อย 8 ตัว คุณรับผิดชอบต่อการใช้งานภายใต้บัญชีของตน และต้องแจ้งร้านหากสงสัยว่าบัญชีถูกผู้อื่นใช้ ร้านอาจระงับบัญชีที่ให้ข้อมูลเท็จ ใช้ในทางทุจริต หรือรบกวนระบบ

3. สินค้าและราคา
ราคาที่แสดงมีทั้งราคาปลีก ราคาส่งตามจำนวน และราคาสำหรับสมาชิก VIP ระบบคำนวณราคาต่อชิ้นจากจำนวนที่สั่งและสถานะสมาชิก ณ เวลาที่กดสั่งซื้อ ราคาในตะกร้าอาจเปลี่ยนหากร้านปรับราคาก่อนยืนยัน โปรโมชันที่ระบุบนสินค้าเป็นข้อความจากร้าน

4. คำสั่งซื้อ
การกดสั่งซื้อเป็นการส่งคำขอให้ร้านจัดสินค้า ไม่ใช่การขายที่สมบูรณ์จนกว่าร้านจะเปลี่ยนสถานะเป็น "ยืนยันแล้ว" คุณต้องเลือกที่อยู่จัดส่งที่บันทึกไว้ รายละเอียดที่อยู่จะถูกคัดลอกลงในคำสั่งซื้อและไม่เปลี่ยนตามการแก้ไขที่อยู่ในภายหลัง

5. ทรัพย์สินทางปัญญา
โลโก้ ชื่อร้าน ข้อความ และรูปภาพที่ร้านจัดทำ เป็นทรัพย์สินของร้าน ห้ามคัดลอกไปใช้เชิงพาณิชย์โดยไม่ได้รับอนุญาต ชื่อสินค้าของแบรนด์อื่นเป็นของเจ้าของแบรนด์นั้น

6. ข้อจำกัดความรับผิด
บริการให้ "ตามสภาพ" ร้านไม่รับผิดต่อความเสียหายทางอ้อมจากการใช้แอป เช่น อุปกรณ์ขัดข้องหรือเครือข่ายล่ม ความรับผิดรวมต่อคำสั่งซื้อหนึ่งไม่เกินมูลค่าของคำสั่งซื้อนั้น

7. การเปลี่ยนแปลง
ร้านอาจแก้ไขข้อกำหนดนี้ โดยแสดงวันที่อัปเดตในหน้านี้ การใช้บริการต่อหลังวันนั้นถือว่ายอมรับข้อกำหนดใหม่

8. กฎหมายและติดต่อ
ข้อกำหนดนี้อยู่ภายใต้กฎหมายไทย หากมีข้อพิพาทให้เจรจากับร้านก่อน ติดต่อร้านผ่านช่องทางที่ระบุในแอป''',
    '''Last updated: 30 September 2026
Tae-ia Skin Shop (the "shop") provides this app and website to browse skincare prices and place orders. These terms are an agreement between you and the shop.

1. Acceptance
Creating an account, logging in, or placing an order means you accept these terms, the privacy policy, and the orders policy. If you do not accept them, please stop using the service.

2. Accounts
You must provide a real name, username, and password. Usernames are 3–30 characters: letters, numbers, dots, or underscores. Passwords are at least 8 characters. You are responsible for activity under your account and should tell the shop if you suspect someone else is using it. The shop may suspend accounts that use false information, fraud, or interfere with the service.

3. Products and prices
Prices may be retail, wholesale by quantity, or VIP. The unit price is calculated from the quantity and your membership at the moment you place the order. A cart total can change if the shop updates a price before confirming the order. Promotion text is supplied by the shop.

4. Orders
Placing an order is a request, not a completed sale, until the shop sets the status to Confirmed. You must choose a saved shipping address. That address is copied onto the order and does not change if you later edit the address book.

5. Intellectual property
The logo, shop name, text, and images created by the shop belong to the shop. Do not copy them for commercial use without permission. Third-party brand names belong to their owners.

6. Liability
The service is provided as is. The shop is not liable for indirect loss from using the app, such as device or network failure. Total liability for one order does not exceed that order's value.

7. Changes
The shop may update these terms and will show the date on this page. Continuing to use the service after that date means you accept the new terms.

8. Law and contact
These terms follow Thai law. Please talk to the shop before any dispute. Contact details are shown in the app.''',
    '''最近更新：2026年9月30日
泰亚护肤店（“本店”）通过本应用和网站提供护肤商品的价格查询与下单。本条款是您与本店之间的协议。

1. 接受
注册、登录或下单即表示您接受本条款、隐私政策以及订购与配送政策。若不同意，请停止使用。

2. 账户
您应提供真实的姓名、用户名和密码。用户名为 3–30 位英文字母、数字、点或下划线，密码至少 8 位。您对账户下的操作负责；若怀疑账户被他人使用，请通知本店。提供虚假资料、欺诈或干扰系统的账户可能被停用。

3. 商品与价格
价格包括零售价、按数量的批发价以及 VIP 价。单价按您下单当时的数量和会员身份计算。若本店在确认前调整价格，购物车金额可能变化。促销文字由本店提供。

4. 订单
下单是向本店提出的请求，在状态变为“已确认”之前，买卖尚未完成。您必须选择已保存的收货地址。该地址会复制到订单中，之后修改地址簿不会改变已下的订单。

5. 知识产权
本店制作的标志、店名、文字和图片归本店所有，未经许可不得用于商业用途。其他品牌名称归其权利人所有。

6. 责任限制
服务按现状提供。因设备或网络故障等造成的间接损失，本店不承担责任。对单个订单的总责任不超过该订单金额。

7. 变更
本店可更新本条款，并在本页显示更新日期。在该日期之后继续使用，即表示接受新条款。

8. 法律与联系
本条款适用泰国法律。发生争议时请先与本店协商。联系方式见应用内说明。''',
  ],
  'privacy_body': [
    '''อัปเดตล่าสุด: 30 กันยายน 2026
ร้านเคารพข้อมูลส่วนบุคคลตามพระราชบัญญัติคุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562 (PDPA)

1. ข้อมูลที่เก็บ
- บัญชี: ชื่อ ชื่อผู้ใช้ เบอร์โทร รหัสผ่านที่จัดเก็บแบบเข้ารหัส (bcrypt) สิทธิ์สมาชิก และรูปโปรไฟล์
- ที่อยู่จัดส่ง: ชื่อผู้รับ เบอร์โทร ที่อยู่โดยละเอียด ตำบล/แขวง อำเภอ/เขต จังหวัด รหัสไปรษณีย์
- คำสั่งซื้อ: รายการสินค้า จำนวน ราคา ณ เวลาสั่ง หมายเหตุ ที่อยู่ที่คัดลอกไว้ สถานะ และเลขพัสดุ
- ข้อมูลในเครื่องคุณ: โทเคนเข้าสู่ระบบ ภาษาที่เลือก และธีม เก็บในเครื่องด้วย SharedPreferences ไม่ได้ส่งรหัสผ่านเดิมออกไปนอกเหนือตอนเข้าสู่ระบบหรือเปลี่ยนรหัส

2. วัตถุประสงค์
ใช้เพื่อสมัครและเข้าสู่ระบบ แสดงราคาตามสิทธิ์สมาชิก รับและจัดส่งคำสั่งซื้อ แจ้งสถานะ จัดการสินค้าโดยผู้ดูแลร้าน และปรับปรุงบริการ ไม่ใช้ข้อมูลเพื่อขายให้บุคคลภายนอก

3. การเปิดเผย
ออเดอร์ใหม่อาจถูกส่งเข้า LINE Official Account ของร้าน เพื่อให้ร้านจัดสินค้า ข้อความนั้นมีชื่อ เบอร์ และที่อยู่จัดส่ง ร้านไม่เปิดเผยข้อมูลให้ผู้โฆษณา

4. การเก็บรักษา
ข้อมูลอยู่ในฐานข้อมูลของร้านตลอดอายุบัญชี หรือจนกว่าคุณจะขอลบและไม่มีหน้าที่ตามกฎหมายที่ต้องเก็บต่อ เช่น หลักฐานการขาย รูปที่ลบจะถูกลบจากที่เก็บไฟล์

5. สิทธิของคุณ
คุณเข้าถึงและแก้ไขชื่อ ชื่อผู้ใช้ เบอร์โทร รูป และที่อยู่ได้เองในแอป คุณขอให้ลบบัญชี จำกัดการใช้ หรือขอสำเนาข้อมูลได้โดยติดต่อร้าน การถอนความยินยอมอาจทำให้สั่งซื้อต่อไม่ได้หากไม่มีที่อยู่หรือบัญชี

6. ความปลอดภัย
รหัสผ่านไม่ถูกเก็บเป็นข้อความธรรมดา การเชื่อมต่อผ่าน HTTPS เมื่อใช้งานผ่านโดเมนของร้าน คุณควรไม่ใช้รหัสผ่านซ้ำกับบริการอื่น และออกจากระบบบนเครื่องที่ใช้ร่วมกัน

7. ติดต่อ
หากต้องการใช้สิทธิเกี่ยวกับข้อมูลส่วนบุคคล ติดต่อร้านผ่านช่องทางในหน้าเกี่ยวกับแอป''',
    '''Last updated: 30 September 2026
The shop handles personal data under Thailand's Personal Data Protection Act B.E. 2562 (PDPA).

1. Data we keep
- Account: name, username, phone, a bcrypt password hash, membership role, and profile photo.
- Addresses: recipient, phone, street address, subdistrict, district, province, and postal code.
- Orders: items, quantities, the price at order time, note, a copy of the address, status, and tracking number.
- On your device: login token, language, and theme, stored with SharedPreferences. Your password is sent only when you log in or change it.

2. Why
To register and log in, show prices for your membership, take and ship orders, update order status, let staff manage the catalog, and run the service. We do not sell your data.

3. Sharing
A new order may be pushed to the shop's LINE Official Account so staff can pack it. That message includes your name, phone, and shipping address. We do not share data with advertisers.

4. Retention
Data stays in the shop database for the life of the account, or until you ask for deletion and no legal duty requires us to keep it, such as a sales record. Removed photos are deleted from file storage.

5. Your rights
You can view and edit your name, username, phone, photo, and addresses in the app. You may ask the shop to delete the account, limit processing, or give you a copy. Withdrawing consent may mean you cannot order if you have no account or address.

6. Security
Passwords are not stored in plain text. The public site is served over HTTPS. Do not reuse passwords, and log out on shared devices.

7. Contact
To use your privacy rights, contact the shop through the details on the About page.''',
    '''最近更新：2026年9月30日
本店依照泰国《个人数据保护法》（B.E. 2562，PDPA）处理个人资料。

1. 我们保存的资料
- 账户：姓名、用户名、电话、以 bcrypt 加密的密码、会员身份、头像。
- 地址：收件人、电话、详细地址、街道/乡、区/县、省/府、邮政编码。
- 订单：商品、数量、下单时的价格、备注、地址副本、状态和运单号。
- 在您的设备上：登录令牌、语言和主题，使用 SharedPreferences 保存。密码只在登录或修改时发送。

2. 用途
用于注册和登录、按会员身份显示价格、接收和配送订单、更新订单状态、供店员管理商品以及维持服务。我们不出售您的资料。

3. 共享
新订单可能发送到本店的 LINE 官方账号，以便打包。该消息包含姓名、电话和收货地址。我们不向广告商提供资料。

4. 保存期限
资料在账户存续期间保存在本店数据库中，或直到您要求删除且法律不再要求保留（例如销售凭证）。删除的图片会从文件存储中移除。

5. 您的权利
您可在应用中查看并修改姓名、用户名、电话、头像和地址。您也可以要求本店删除账户、限制处理或提供副本。撤回同意后，若没有账户或地址，可能无法继续下单。

6. 安全
密码不以明文保存。通过本店域名访问时使用 HTTPS。请勿重复使用密码，并在共用设备上退出登录。

7. 联系
如需行使隐私权利，请通过“关于应用”页面中的方式联系本店。''',
  ],
  'purchase_body': [
    '''อัปเดตล่าสุด: 30 กันยายน 2026

1. ราคา
ราคาต่อชิ้นเป็นราคาต่ำสุดที่คุณมีสิทธิ์ ณ จำนวนที่สั่ง ได้แก่ ราคาปลีก ราคา VIP (ถ้ามีและคุณเป็นสมาชิก VIP หรือผู้ดูแล) และราคาส่งที่จำนวนถึงขั้นต่ำ ระบบคำนวณให้ ไม่ใช้ตัวเลขจากเครื่องคุณ

2. การสั่งซื้อ
ต้องเข้าสู่ระบบและเลือกที่อยู่จัดส่งที่บันทึกไว้ จึงจะสั่งได้ ที่อยู่ประกอบด้วยชื่อผู้รับ เบอร์โทร ที่อยู่โดยละเอียด ตำบลหรือแขวง อำเภอหรือเขต จังหวัด และรหัสไปรษณีย์ ผู้ดูแลเห็นรายละเอียดนี้ในคำสั่งซื้อทันที คำสั่งซื้อเริ่มที่สถานะ "รอยืนยัน"

3. การยืนยัน การจัดส่ง และเลขพัสดุ
ร้านตรวจสินค้าและเปลี่ยนสถานะเป็นยืนยันแล้ว จัดส่งแล้ว หรือยกเลิก เมื่อจัดส่ง ร้านใส่เลขพัสดุให้คุณเห็นในออเดอร์ของฉัน ระยะเวลาขึ้นกับขนส่งและที่อยู่

4. การชำระเงิน
วิธีชำระเป็นไปตามที่ร้านแจ้งหลังยืนยันออเดอร์ แอปนี้บันทึกคำสั่งซื้อ ไม่ได้ตัดบัตรในแอป

5. การยกเลิก
ก่อนร้านยืนยัน คุณขอให้ยกเลิกได้โดยติดต่อร้าน หลังจัดส่งแล้ว การยกเลิกขึ้นกับสินค้าที่ส่งออกไปแล้ว

6. สินค้าชำรุดและการคืน
สินค้าดูแลผิวที่เปิดผนึกแล้วไม่รับคืนหรือเปลี่ยน เพื่อสุขอนามัย เว้นแต่สินค้าชำรุด ผิดรายการ หรือเสียหายจากการขนส่ง ให้แจ้งร้านภายใน 7 วันนับจากได้รับ พร้อมรูปและเลขออเดอร์ ร้านจะเปลี่ยนสินค้าหรือคืนตามที่ตกลง

7. ที่อยู่ผิด
คุณรับผิดชอบความถูกต้องของที่อยู่ที่เลือกตอนสั่ง ร้านจัดส่งตามที่อยู่ที่บันทึกในคำสั่งซื้อ''',
    '''Last updated: 30 September 2026

1. Prices
The unit price is the lowest price you qualify for at that quantity: retail, VIP (if set and you are VIP or staff), and wholesale tiers you have reached. The server calculates it. The app does not choose the price.

2. Placing an order
You must be logged in and pick a saved address. An address has a recipient, phone, street details, subdistrict, district, province, and postal code. Staff see the full address on the order immediately. New orders start as Pending.

3. Confirmation, shipping, tracking
The shop checks stock and sets the status to Confirmed, Shipped, or Cancelled. When it ships, the tracking number appears on My orders. Timing depends on the carrier and the address.

4. Payment
Payment follows the method the shop tells you after confirming. This app records the order. It does not charge a card inside the app.

5. Cancellation
Before the shop confirms, ask the shop to cancel. After shipping, cancellation depends on goods already handed to the carrier.

6. Defects and returns
Opened skincare cannot be returned or exchanged, for hygiene, unless it is defective, wrong, or damaged in transit. Contact the shop within 7 days of delivery with photos and the order number. The shop will replace the item or refund as agreed.

7. Wrong address
You are responsible for the address you select. The shop ships to the address stored on the order.''',
    '''最近更新：2026年9月30日

1. 价格
单价是您在该数量下可享受的最低价：零售价、VIP 价（若已设置且您是 VIP 或店员）以及已达到的批发档。由服务器计算，不采用应用自行填写的价格。

2. 下单
必须登录并选择已保存的地址。地址包括收件人、电话、详细地址、街道/乡、区/县、省/府和邮政编码。店员会立刻在订单中看到完整地址。新订单状态为“待确认”。

3. 确认、配送与运单
本店核对商品后，将状态改为已确认、已发货或已取消。发货后，运单号显示在“我的订单”。时间取决于承运商和地址。

4. 付款
付款方式以本店确认订单后的通知为准。本应用只记录订单，不在应用内扣款。

5. 取消
本店确认前，可联系本店取消。发货后是否取消，取决于货物是否已交给承运商。

6. 瑕疵与退货
已拆封的护肤品因卫生原因不予退换，除非商品瑕疵、发错或运输损坏。请在签收后 7 日内联系本店，并提供照片和订单号。本店将按约定换货或退款。

7. 地址错误
您须保证下单时选择的地址正确。本店按订单中保存的地址发货。''',
  ],
  'licenses_body': [
    '''แอปพลิเคชันร้านแต๊ะเอียสกินช็อป เวอร์ชัน 1.0.0
สงวนลิขสิทธิ์ © 2026 ร้านแต๊ะเอียสกินช็อป
ตัวแอป โลโก้ ข้อความนโยบาย และข้อมูลสินค้าในร้าน เป็นทรัพย์สินของร้าน ห้ามทำซ้ำ ดัดแปลง หรือให้บริการต่อโดยไม่ได้รับอนุญาตเป็นลายลักษณ์อักษร

ซอฟต์แวร์โอเพนซอร์สที่แอปใช้
แอปสร้างด้วย Flutter และไลบรารีต่อไปนี้ แต่ละรายการอยู่ภายใต้สัญญาอนุญาตของตนเอง ข้อความสัญญาฉบับเต็มอยู่กับซอร์สของไลบรารีนั้น

- Flutter, Dart SDK — BSD 3-Clause — Google / Dart project
- http, http_parser — BSD 3-Clause — Dart team
- go_router — BSD 3-Clause — Flutter team
- flutter_riverpod, riverpod — MIT — Remi Rousselet
- cached_network_image, flutter_cache_manager — MIT — Baseflow
- image_picker — Apache-2.0 / BSD — Flutter team
- shared_preferences — BSD 3-Clause — Flutter team
- google_fonts — Apache-2.0 — Flutter team (ฟอนต์ Prompt และ Noto Sans SC อยู่ภายใต้สัญญาของเจ้าของฟอนต์)
- url_launcher — BSD 3-Clause — Flutter team
- intl — BSD 3-Clause — Dart team
- web_socket_channel — BSD 3-Clause — Dart team
- Flutter SDK packages (material, widgets) — BSD 3-Clause

ฝั่งเซิร์ฟเวอร์
- Node.js — MIT
- Fastify และ @fastify/jwt, @fastify/multipart, @fastify/websocket — MIT
- pg — MIT
- zod — MIT
- bcryptjs — MIT
- PostgreSQL — PostgreSQL License
- nginx — BSD 2-Clause

สัญญาอนุญาตแบบ BSD และ MIT อนุญาตให้ใช้ แก้ไข และเผยแพร่ได้ โดยต้องคงข้อความลิขสิทธิ์และคำปฏิเสธความรับผิดไว้ สัญญา Apache-2.0 เพิ่มเงื่อนไขเรื่องสิทธิบัตรและการระบุการแก้ไข ร้านไม่ได้แก้ไขไลบรารีเหล่านี้เพื่อเปลี่ยนเงื่อนไขสัญญา

ฟอนต์
ฟอนต์ Prompt ออกแบบโดย Cadson Demak ใช้ผ่าน Google Fonts ฟอนต์ Noto Sans SC เป็นส่วนหนึ่งของโครงการ Noto โดย Google ใช้สำหรับตัวอักษรจีน''',
    '''Tae-ia Skin Shop application, version 1.0.0
Copyright © 2026 Tae-ia Skin Shop. All rights reserved.
The app, logo, policy text, and the shop's catalog content belong to the shop. Do not copy, modify, or resell them without written permission.

Open-source software used by the app
The app is built with Flutter and the libraries below. Each keeps its own license. The full text ships with that library's source.

- Flutter, Dart SDK — BSD 3-Clause — Google / the Dart project
- http, http_parser — BSD 3-Clause — the Dart team
- go_router — BSD 3-Clause — the Flutter team
- flutter_riverpod, riverpod — MIT — Remi Rousselet
- cached_network_image, flutter_cache_manager — MIT — Baseflow
- image_picker — Apache-2.0 / BSD — the Flutter team
- shared_preferences — BSD 3-Clause — the Flutter team
- google_fonts — Apache-2.0 — the Flutter team (Prompt and Noto Sans SC follow their own font licenses)
- url_launcher — BSD 3-Clause — the Flutter team
- intl — BSD 3-Clause — the Dart team
- web_socket_channel — BSD 3-Clause — the Dart team
- Flutter SDK packages (material, widgets) — BSD 3-Clause

Server
- Node.js — MIT
- Fastify and @fastify/jwt, @fastify/multipart, @fastify/websocket — MIT
- pg — MIT
- zod — MIT
- bcryptjs — MIT
- PostgreSQL — PostgreSQL License
- nginx — BSD 2-Clause

BSD and MIT licenses allow use, modification, and distribution if the copyright notice and disclaimer stay intact. Apache-2.0 adds patent terms and a notice when you modify the code. The shop does not change these libraries' license terms.

Fonts
Prompt was designed by Cadson Demak and is loaded through Google Fonts. Noto Sans SC is part of Google's Noto project and is used for Chinese characters.''',
    '''泰亚护肤店应用，版本 1.0.0
版权所有 © 2026 泰亚护肤店
本应用、标志、政策文本以及店内商品资料归本店所有。未经书面许可，不得复制、修改或转售。

应用使用的开源软件
本应用使用 Flutter 及下列库。各库保留其自身许可，全文见该库源代码。

- Flutter、Dart SDK — BSD 3-Clause — Google / Dart 项目
- http、http_parser — BSD 3-Clause — Dart 团队
- go_router — BSD 3-Clause — Flutter 团队
- flutter_riverpod、riverpod — MIT — Remi Rousselet
- cached_network_image、flutter_cache_manager — MIT — Baseflow
- image_picker — Apache-2.0 / BSD — Flutter 团队
- shared_preferences — BSD 3-Clause — Flutter 团队
- google_fonts — Apache-2.0 — Flutter 团队（Prompt 与 Noto Sans SC 另有字体许可）
- url_launcher — BSD 3-Clause — Flutter 团队
- intl — BSD 3-Clause — Dart 团队
- web_socket_channel — BSD 3-Clause — Dart 团队
- Flutter SDK（material、widgets）— BSD 3-Clause

服务器
- Node.js — MIT
- Fastify 以及 @fastify/jwt、@fastify/multipart、@fastify/websocket — MIT
- pg — MIT
- zod — MIT
- bcryptjs — MIT
- PostgreSQL — PostgreSQL License
- nginx — BSD 2-Clause

BSD 与 MIT 允许使用、修改和分发，但须保留版权声明和免责声明。Apache-2.0 另有专利条款，并要求在修改代码时注明。本店不改变这些库的许可条件。

字体
Prompt 由 Cadson Demak 设计，通过 Google Fonts 加载。Noto Sans SC 属于 Google 的 Noto 项目，用于显示中文。''',
  ],
  'about_body': [
    '''ร้านแต๊ะเอียสกินช็อป
ดูแลผิวสวย ในแบบที่เป็นคุณ

แอปนี้ใช้ดูราคาสินค้าดูแลผิวทั้งราคาปลีก ราคาส่ง และราคา VIP สมัครสมาชิกเพื่อสั่งซื้อ บันทึกที่อยู่ได้หลายแห่ง และติดตามสถานะออเดอร์ได้แบบเรียลไทม์โดยไม่ต้องรีเฟรชหน้า

เวอร์ชัน 1.0.0
ภาษาที่รองรับ: ไทย อังกฤษ จีน
ธีม: สว่าง มืด หรือตามระบบ

ข้อมูลร้านและช่องทางติดต่อให้ดูจากบัญชี LINE ของร้านที่ปุ่ม "ส่งทาง LINE" ในหน้าออเดอร์ หากต้องการใช้สิทธิเกี่ยวกับข้อมูลส่วนบุคคลหรือสอบถามคำสั่งซื้อ ให้ติดต่อร้านผ่านช่องทางนั้นโดยแจ้งเลขออเดอร์และชื่อผู้ใช้''',
    '''Tae-ia Skin Shop
Skincare, in your own way.

This app shows retail, wholesale, and VIP prices. Sign up to order, save more than one address, and follow order status in real time without refreshing the page.

Version 1.0.0
Languages: Thai, English, and Chinese
Themes: light, dark, or match the system

Shop contact details are on the shop's LINE account, opened by Send via LINE on an order. For a privacy request or a question about an order, contact the shop there and include the order number and your username.''',
    '''泰亚护肤店
以适合你的方式护理肌肤。

本应用显示零售价、批发价和 VIP 价。注册后可下单、保存多个地址，并实时查看订单状态，无需刷新页面。

版本 1.0.0
语言：泰语、英语、中文
主题：浅色、深色或跟随系统

店铺联系方式见店铺的 LINE 账号，可在订单页点“通过 LINE 发送”打开。如需行使隐私权利或询问订单，请通过该方式联系，并注明订单号和用户名。''',
  ],
};

String legal(BuildContext context, String key) {
  final i = switch (L10nScope.of(context)) { 'en' => 1, 'zh' => 2, _ => 0 };
  return legalText[key]?[i] ?? key;
}
