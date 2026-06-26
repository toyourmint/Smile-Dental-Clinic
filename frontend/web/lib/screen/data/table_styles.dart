// table_styles.dart
// ไฟล์นี้เก็บค่าคงที่ด้าน typography สำหรับตารางทั้ง 3 หน้า
// วางไว้ที่ lib/screen/data/table_styles.dart (หรือ shared/)

import 'package:flutter/material.dart';

class TableStyles {
  TableStyles._(); // ป้องกันการสร้าง instance

  // ─── Avatar ───────────────────────────────────────────────
  static const double avatarRadius = 20.0;

  // ─── ชื่อผู้ป่วย (บรรทัดแรก) ──────────────────────────────
  static const TextStyle patientName = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Color(0xFF111827),
  );

  // ─── รหัส HN (บรรทัดสอง) ─────────────────────────────────
  static const TextStyle patientHn = TextStyle(
    fontSize: 11,
    color: Color(0xFF1976D2),
    fontWeight: FontWeight.w600,
  );

  // ─── ข้อมูลทั่วไปในเซลล์ (วันที่ เวลา เบอร์ ฯลฯ) ──────────
  static const TextStyle cellBody = TextStyle(
    fontSize: 13,
    color: Color(0xFF374151),
  );

  // ─── ข้อมูลรอง / สีเทา (แพทย์ ประเภทการรักษา) ────────────
  static const TextStyle cellMuted = TextStyle(
    fontSize: 13,
    color: Color(0xFF6B7280),
  );

  // ─── หัวคอลัมน์ตาราง ──────────────────────────────────────
  static const TextStyle columnHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Color(0xFF111827),
  );
}