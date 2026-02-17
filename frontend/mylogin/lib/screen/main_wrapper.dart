import 'package:flutter/material.dart';
import 'package:mylogin/screen/calendar_screen.dart';
import 'package:mylogin/screen/home_screen.dart';
import 'package:mylogin/widget/custom_bottom_nav.dart';
import 'notification_screen_mock.dart';
import 'profile_screen.dart';

class MainWrapper extends StatefulWidget {
  final String userName;
  final int userId; // ตัวแปรนี้ปล่อยทิ้งไว้แบบนี้ได้เลยครับ เผื่อหน้าอื่นต้องใช้

  const MainWrapper({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    
    _screens = [
      HomeScreen(userName: widget.userName),
      const CalendarScreen(), // ใส่ const ได้เลยถ้าหน้านั้นไม่มีการส่งค่า
      const NotificationScreenMock(),
      
      // 🌟 แก้ตรงนี้! เอา userId ออกให้เหลือแค่นี้ 
      // (ใส่ const เพิ่มเข้าไปด้วยเพื่อประสิทธิภาพที่ดีขึ้น)
      const ProfileScreen(), 
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