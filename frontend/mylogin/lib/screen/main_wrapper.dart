import 'package:flutter/material.dart';
// Import หน้าจอต่างๆ
import 'package:mylogin/screen/home_screen.dart';
// Import Component เมนูบาร์ที่เราแยกไฟล์ไว้
import 'package:mylogin/widget/custom_bottom_nav.dart'; 

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // รายการหน้าจอทั้งหมด
  final List<Widget> _screens = [
    const HomeScreen(),
    const Center(child: Text("หน้าปฏิทินนัดหมาย")), // เดี๋ยวเราจะมาแก้ตรงนี้ต่อ
    const Center(child: Text("หน้าข้อความ")),
    const Center(child: Text("หน้าโปรไฟล์")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ส่วนเนื้อหาที่จะเปลี่ยนไปตามการกดเมนู
      body: _screens[_selectedIndex],

      // ตรงนี้เรียกใช้ Widget ที่เราสร้างแยกไว้ สั้นลงและสะอาดตามาก!
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}