import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/login_web.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // ปิดป้าย Debug มุมขวาบน
      title: 'Smile Dental Clinic',
      theme: ThemeData(
        fontFamily: 'Sans-serif', // หรือชื่อฟอนต์ที่คุณลงไว้
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // เรียกใช้หน้า LoginScreen ที่แยกไว้
      home: const LoginScreen(),
    );
  }
}