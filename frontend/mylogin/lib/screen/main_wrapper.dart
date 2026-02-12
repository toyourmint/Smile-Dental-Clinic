import 'package:flutter/material.dart';
import 'package:mylogin/screen/calendar_screen.dart';
import 'package:mylogin/screen/home_screen.dart';
import 'package:mylogin/widget/custom_bottom_nav.dart';
import 'notification_screen_mock.dart';
import 'profile_screen.dart';

class MainWrapper extends StatefulWidget {
  final String userName; // 1. เพิ่มตัวแปรรับชื่อ

  // 2. เพิ่ม required this.userName ใน constructor
  const MainWrapper({super.key, required this.userName});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // 3. เปลี่ยน List เป็น late final เพื่อให้รอรับค่า widget.userName ได้
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // 4. กำหนดค่าใน initState เพื่อดึงชื่อที่ส่งเข้ามาไปใช้
    _screens = [
      HomeScreen(userName: widget.userName), // ส่งชื่อต่อไปให้ Home
      CalendarScreen(), 
      NotificationScreenMock(),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
