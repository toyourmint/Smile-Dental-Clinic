# 🦷 Smile Dental Clinic
เว็บไซต์ระบบจัดการคลินิคทันตกรรม โปรเจคนี้เป็นส่วนหนึ่งของรายวิชา 90642172 Team-Project 2

---

## 👥 สมาชิกในกลุ่ม

| ชื่อ | รหัสนักศึกษา |
|------|--------|
| นายจิรวัฒน์ อินทนะนก | 67010137 |
| นางสาวณปภัช พรรณศิลป์ | 67010253 |
| นางสาวปัณฑ์ชนิต ประจักษานนท์ | 67010554 |
| นางสาวอันนา สิงห์สถิตย์ | 67011043 |
| นางสาวญาดาวดี กลิ่นสมิทธิ์ | 67011430 |

---

## 📁 โครงสร้างโปรเจค
```
smile-dental-clinic/
├── backend/              → Node.js + Express API
├── database/             → SQL migration files
├── frontend/
│   ├── mylogin/          → Flutter App (ผู้ป่วย)
│   └── web/              → Flutter Web (บุคลากร/Admin)
├── docker-compose.yml
└── README.md
```
---

## ⚙️ สิ่งที่ต้องติดตั้งก่อน

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.x ขึ้นไป)
- [Android Studio](https://developer.android.com/studio)
- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [Node.js](https://nodejs.org/) (version 18 ขึ้นไป)

---

## 🚀 วิธีเปิดโปรเจค

### 1. เปิด Backend + Database

```bash
cd backend
docker-compose up
```

รอจนเห็น Backend server is running at http://localhost:3000

---

### 2. เปิด Flutter App (ผู้ป่วย) ด้วย Android Studio

1. เปิด **Android Studio**
2. กด **Open** → เลือกโฟลเดอร์ frontend/mylogin/
3. รอ Android Studio โหลด dependencies จนเสร็จ
4. เปิด **Device Manager** (มุมขวาบน) → กด **▶ Start** เพื่อเปิด Emulator
5. รอ Emulator เปิดขึ้นมาจนเห็น Android home screen
6. กดปุ่ม **▶ Run** (Shift + F10) หรือไปที่ Run → Run 'main.dart'
7. รอ build เสร็จ App จะเปิดขึ้นบน Emulator อัตโนมัติ

> **หมายเหตุ:** ถ้ายังไม่มี Emulator ให้กด **Device Manager → Create Device** แล้วเลือก Pixel 6 หรือรุ่นใดก็ได้ → เลือก Android API 33 ขึ้นไป

---

### 3. เปิด Flutter Web (Admin) ด้วย Terminal

> ```bash
> cd frontend/web
> flutter run -d chrome
> ```

---

## 👤 บัญชีทดสอบ

| Role | Email | Password |
|---|---|---|
| Admin | Napapat@gmail.com | admin1234 |
| ผู้ป่วย | napapat0564@gmail.com | user1234 |

---

## 🛠️ Tech Stack

| ส่วน | เทคโนโลยี |
|---|---|
| Mobile App | Flutter |
| Web Admin | Flutter Web |
| Backend | Node.js + Express |
| Database | MySQL 8 |
| Authentication | JWT + OTP |
| Container | Docker |

---

## 🎯 ฟังก์ชันหลักของระบบ

### 1. 


### 2. 


### 3. 


### 4. 
