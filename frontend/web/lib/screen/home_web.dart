import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/appomitment/appointment.dart';
import 'package:flutter_application_1/screen/daily/daily_queue.dart';
import 'package:flutter_application_1/screen/pateints/pateints_table.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // เพิ่มหน้า PatientsScreen เข้าไปใน List
  final List<Widget> _pages = [
    const DailyQueueScreen(), // หน้า 0
    const AppointmentScreen(), // หน้า 1
    const PatientsScreen(), // หน้า 2 (ใส่ Widget จริงแทนที่บรรทัดนี้ได้เลย)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar (โครงสร้างเดิม)
          Container(
            width: 260,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'SMILE\nDENTAL\nCLINIC',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF0062E0),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 50),

                // เมนูที่ 1: ตารางนัดประจำวัน (ไอคอน List)
                _buildMenuItem(
                  0,
                  "ตารางนัดประจำวัน",
                  Icons.format_list_bulleted,
                ),

                // เมนูที่ 2: การนัดหมาย (ไอคอนปฏิทิน)
                _buildMenuItem(1, "การนัดหมาย", Icons.calendar_today_outlined),

                // --- เมนูที่ 3: ข้อมูลผู้ป่วย (เพิ่มใหม่ตามรูป) ---
                _buildMenuItem(2, "ข้อมูลผู้ป่วย", Icons.person),

                // ---------------------------------------------
                const Spacer(),

                // ส่วน Profile ด้านล่าง (เหมือนเดิม)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.black12)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            child: const CircleAvatar(
                              backgroundColor: Colors.grey,
                              radius: 20,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            radius: 20,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "นายสี่ ห้า",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "จนท.ทะเบียน",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/'),
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text("ออกจากระบบ"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black54,
                          minimumSize: const Size(double.infinity, 36),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content Area
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }

  // Widget สร้างเมนู (ปรับให้เหมือนรูปต้นฉบับ: แคปซูลสีฟ้า/เทา)
  Widget _buildMenuItem(int index, String title, IconData icon) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          // ถ้าเลือก: สีฟ้าอ่อน (เหมือนในรูป), ถ้าไม่เลือก: สีเทา
          color: isSelected ? const Color(0xFF90CAF9) : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              // ถ้าเลือก: สีน้ำเงินเข้ม, ถ้าไม่เลือก: สีเทาเข้ม
              color: isSelected ? const Color(0xFF1565C0) : Colors.grey[700],
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                // ถ้าเลือก: สีดำ/เทาเข้ม, ถ้าไม่เลือก: สีเทาเข้ม
                color: isSelected ? Colors.black87 : Colors.grey[700],
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal, // ตัวหนาเมื่อเลือก
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
