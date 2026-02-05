import 'package:flutter/material.dart';
import 'package:mylogin/widget/logo.dart';
import 'otp_screen.dart';
import 'login_screen.dart';

class ForgetEmailScreen extends StatelessWidget {
  const ForgetEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("ลืมรหัสผ่าน")),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Center(child: LogoWidget()),

            const SizedBox(height: 60),

            /// ===============================
            /// Email input
            /// ===============================
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "กรอกอีเมลเพื่อรับรหัส OTP",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            /// ===============================
            /// ปุ่มรับ OTP
            /// ===============================
            ElevatedButton(
              onPressed: () {
                final email = controller.text.trim();

                /// ❌ ถ้าว่าง
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("กรุณากรอกอีเมลก่อน"),
                    ),
                  );
                  return;
                }

                /// ✅ ถ้ามี email ค่อยไปหน้า OTP
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OTPScreen(
                      isReset: true,
                      email: email,
                    ),
                  ),
                );
              },
              child: const Text("รับ OTP"),
            ),

            const SizedBox(height: 20),

            /// ===============================
            /// กลับหน้า login
            /// ===============================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("มีบัญชีอยู่แล้ว ? "),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text("เข้าสู่ระบบ"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
