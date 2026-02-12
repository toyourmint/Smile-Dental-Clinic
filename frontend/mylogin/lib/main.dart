import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:mylogin/screen/splash_screen.dart'; // Import หน้า Splash เข้ามา

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dental Queue App',
      
      // ตั้งค่า Theme และ Font (อันนี้ดีแล้วครับ เก็บไว้)
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent,
        textTheme: GoogleFonts.kanitTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      
      // จุดสำคัญ: ให้เริ่มที่ SplashScreen ก่อน เหมือนโค้ดเก่า
      home: const SplashScreen(), 
    );
  }
}