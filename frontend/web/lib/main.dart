import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/login_web.dart';
import 'package:flutter_application_1/screen/home_web.dart'; // import หน้า Home มาด้วย
import 'package:flutter_application_1/screen/auth_service.dart'; // import AuthService มาใช้เช็ค token

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smile Dental Clinic',
      theme: ThemeData(
        fontFamily: 'Sans-serif',
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // ใช้ FutureBuilder เช็คสถานะตรงนี้เลย
      home: FutureBuilder<String?>(
        future: AuthService.getValidToken(),
        builder: (context, snapshot) {
          // ถ้ากำลังโหลดให้โชว์หน้าจอว่างๆ หรือ CircularProgressIndicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // ถ้ามี Token (snapshot.data != null) ให้ไปหน้า Home
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          }
          
          // ถ้าไม่มี Token หรือหมดอายุ ให้ไปหน้า Login
          return const LoginScreen();
        },
      ),
    );
  }
}