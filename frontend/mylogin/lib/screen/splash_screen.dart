import 'package:flutter/material.dart';
import 'logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FF),

      body: Stack(
        children: [

          /// โลโก้ (เรียกใช้จากไฟล์ logo.dart)
          const Positioned(
            top: 40,
            left: 20,
            child: LogoWidget(),
          ),

          /// ข้อความกลางจอ
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "SMILE",
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                ),
                SizedBox(height: 8),
                Text(
                  "DENTAL",
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightBlue),
                ),
                SizedBox(height: 8),
                Text(
                  "CLINIC",
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
