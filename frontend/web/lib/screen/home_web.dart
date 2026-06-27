import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/screen/appomitment/appointment.dart';
import 'package:flutter_application_1/screen/daily/daily_queue.dart';
import 'package:flutter_application_1/screen/pateints/pateints_table.dart';
import 'package:flutter_application_1/screen/login_web.dart';
import 'package:flutter_application_1/screen/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _currentUserName = "กำลังโหลด...";

  final List<Widget> _pages = [
    const DailyQueueScreen(),
    const AppointmentScreen(),
    const PatientsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserName = prefs.getString('user_name') ?? "ผู้เจ้าหน้าที่";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar
          Container(
            width: 260,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 40),

                // --- โลโก้ (ตรงกับแอป user) ---
                const Column(
                  children: [
                    Text(
                      "SMILE",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      "DENTAL",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.lightBlue,
                      ),
                    ),
                    Text(
                      "CLINIC",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),

                _buildMenuItem(0, "ตารางนัดประจำวันนี้", Icons.format_list_bulleted),
                _buildMenuItem(1, "การนัดหมาย", Icons.calendar_today_outlined),
                _buildMenuItem(2, "ข้อมูลผู้ป่วย", Icons.person),

                const Spacer(),

                // Profile + Logout
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
                              Text(
                                _currentUserName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                "เจ้าหน้าที่ทะเบียน",
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      OutlinedButton.icon(
                        onPressed: () => AuthService.logout(context),
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}