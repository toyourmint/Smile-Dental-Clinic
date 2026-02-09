import 'package:flutter/material.dart';
import 'package:mylogin/widget/logo.dart';
import 'package:mylogin/services/auth_service.dart';
import 'otp_screen.dart';
import 'login_screen.dart';

class ForgetEmailScreen extends StatefulWidget {
  const ForgetEmailScreen({super.key});

  @override
  State<ForgetEmailScreen> createState() => _ForgetEmailScreenState();
}

class _ForgetEmailScreenState extends State<ForgetEmailScreen> {
  final controller = TextEditingController();
  bool _isLoading = false;

  /// ===============================
  /// BACKEND (แบบโค้ด 2)
  /// ===============================
  Future<void> _requestOtp() async {
    final email = controller.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกอีเมลก่อน")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.requestPasswordReset(
        email: email,
      );

      if (!mounted) return;

      if (result['statusCode'] == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OTPScreen(
              email: email,
              isReset: true,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['body']['message'] ?? "เกิดข้อผิดพลาด",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เชื่อมต่อเซิร์ฟเวอร์ไม่ได้")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// ===============================
  /// UI (แบบโค้ดแรก)
  /// ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ลืมรหัสผ่าน")),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// Logo
            const Center(child: LogoWidget()),

            const SizedBox(height: 60),

            /// Email input
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "กรอกอีเมลเพื่อรับรหัส OTP",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            /// ปุ่มรับ OTP + loading
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _requestOtp,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("รับ OTP"),
              ),
            ),

            const SizedBox(height: 20),

            /// กลับหน้า login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("มีบัญชีอยู่แล้ว ? "),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
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
