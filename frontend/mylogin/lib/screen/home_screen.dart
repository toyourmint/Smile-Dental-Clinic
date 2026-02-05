// ยังไม่ได้ทำครับ
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        title: const Text("Home"),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          "ยินดีต้อนรับเข้าสู่ระบบ 🎉",
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
