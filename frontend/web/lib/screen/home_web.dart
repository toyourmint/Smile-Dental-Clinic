import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 📦 1. เพิ่ม import นี้
import 'package:flutter_application_1/screen/appomitment/appointment.dart';
import 'package:flutter_application_1/screen/daily/daily_queue.dart';
import 'package:flutter_application_1/screen/pateints/pateints_table.dart';
import 'package:flutter_application_1/screen/login_web.dart'; // เพื่อให้รู้จัก LoginScreen ตอนกด Logout

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _currentUserName = "กำลังโหลด..."; // 👤 ตัวแปรเก็บชื่อผู้ใช้

  // เพิ่มหน้า PatientsScreen เข้าไปใน List
  final List<Widget> _pages = [
    const DailyQueueScreen(), // หน้า 0
    const AppointmentScreen(), // หน้า 1
    const PatientsScreen(), // หน้า 2
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // 🚀 2. เรียกฟังก์ชันดึงชื่อตอนเริ่มหน้าจอ
  }

  // ฟังก์ชันดึงชื่อจากเครื่อง
  Future<void> _loadUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // ดึงค่า 'user_name' ที่เราบันทึกไว้ในหน้า Login
      _currentUserName = prefs.getString('user_name') ?? "ผู้เจ้าหน้าที่";
    });
  }

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

                // เมนูที่ 1: ตารางนัดประจำวัน
                _buildMenuItem(
                  0,
                  "ตารางนัดประจำวัน",
                  Icons.format_list_bulleted,
                ),

                // เมนูที่ 2: การนัดหมาย
                _buildMenuItem(1, "การนัดหมาย", Icons.calendar_today_outlined),

                // เมนูที่ 3: ข้อมูลผู้ป่วย
                _buildMenuItem(2, "ข้อมูลผู้ป่วย", Icons.person),

                const Spacer(),

                // --- ส่วน Profile ด้านล่าง (แก้ไขตรงนี้) ---
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
                            radius: 20,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 👤 แสดงชื่อที่ Login เข้ามา
                              Text(
                                _currentUserName, 
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              // 🏷️ แสดงตำแหน่ง "เจ้าหน้าที่ทะเบียน"
                              const Text(
                                "เจ้าหน้าที่ทะเบียน",
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
                        onPressed: () async {
                          // Logout: ล้างข้อมูลแล้วกลับไปหน้า Login
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          
                          if (!mounted) return;
                          Navigator.pushReplacement(
                            context, 
                            MaterialPageRoute(builder: (context) => const LoginScreen())
                          );
                        },
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

  // Widget สร้างเมนู (เหมือนเดิมเป๊ะ)
  Widget _buildMenuItem(int index, String title, IconData icon) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF90CAF9) : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF1565C0) : Colors.grey[700],
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black87 : Colors.grey[700],
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}