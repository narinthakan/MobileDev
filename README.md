# dssishop
# dssishop (Flutter)

แอปตัวอย่างสำหรับแสดงรายการสินค้าและเชื่อมต่อกับ PocketBase (backend) — มีหน้า Home, Product List (CRUD), และสคริปต์สำหรับสร้างข้อมูลตัวอย่าง



## การติดตั้งและรัน (Local development)

1. เข้าสู่โฟลเดอร์โปรเจกต์:

```powershell
cd d:\MobileDev\dssishop
```

2. ติดตั้ง dependencies:

```powershell
flutter pub get
```

3. ติดตั้งและรัน PocketBase (ถ้ายังไม่มี):

ดาวน์โหลดจาก https://pocketbase.io แล้วรันไฟล์ `pocketbase` (หรือ `pocketbase.exe` บน Windows):

```powershell
# ตัวอย่าง Windows
.\pocketbase.exe serve

# PocketBase จะรันที่ http://127.0.0.1:8090 ตามค่าเริ่มต้น
```

4. สร้าง collection `product` ใน PocketBase (ผ่าน Admin UI):

- เข้าไปที่ http://127.0.0.1:8090/_/ และล็อกอินเป็น admin
- สร้าง collection ชื่อ `product` และเพิ่มฟิลด์ที่ต้องการ เช่น:
	- `name` (text)
	- `price` (number หรือ text)
	- `imageUrl` (text)
	- `category` (text)

5. (เลือก) สร้างข้อมูลตัวอย่างอัตโนมัติ:

```powershell
dart run .\Scripts\generate_product.dart --count 20
```

สคริปต์จะเชื่อมต่อ PocketBase ที่ `http://127.0.0.1:8090` ตามค่าเริ่มต้น ถ้าต้องการเปลี่ยน URL หรือ credentials ให้แก้ที่สคริปต์หรือส่งผ่าน environment ตามที่สคริปต์รองรับ

6. รันแอป Flutter:

```powershell
flutter run
```

จากนั้นเปิดหน้า Home — แถบปุ่มหมวดหมู่จะสามารถเลื่อนซ้าย/ขวาได้และเลือกเพื่อกรองสินค้า

## ฟีเจอร์สำคัญ
- Home: search bar, banner carousel, ปุ่มหมวดหมู่แบบเลื่อน (scrollable), และกริดสินค้า
- Product List: หน้าจอ CRUD สำหรับสร้าง/แก้ไข/ลบสินค้า, มี realtime handling
- การลบแบบ realtime: เมื่อลบจากหน้า Home หรือ List ระบบจะส่ง event ภายในแอป (`lib/services/app_events.dart`) เพื่อให้หน้าต่างอื่นๆ อัปเดตทันที และยังเรียก PocketBase เพื่อทำการลบจริง

## คำสั่งที่ใช้บ่อย
- ติดตั้ง dependencies: `flutter pub get`
- รันแอป: `flutter run`
- รันสคริปต์สร้างข้อมูลตัวอย่าง: `dart run .\Scripts\generate_product.dart --count 20`

## Troubleshooting เบื้องต้น
- ถ้าแอปเชื่อม PocketBase ไม่ได้: ตรวจสอบว่า PocketBase รันอยู่ที่ `http://127.0.0.1:8090` หรือเปลี่ยน URL ในโค้ด (ไฟล์ที่ใช้ PocketBase คือ `lib/pages/home.dart` และ `lib/pages/products/list.dart`)
- ถ้าเจอปัญหา permission (เช่น ลบไม่ได้): ตรวจสอบกฎ collection ใน PocketBase ว่าต้องล็อกอินหรืออนุญาตให้สาธารณะลบได้
- ถ้า `flutter pub get` โต้แย้งเรื่อง dependency ให้ดูข้อความ error และปรับเวอร์ชันใน `pubspec.yaml` ตามคำแนะนำ

