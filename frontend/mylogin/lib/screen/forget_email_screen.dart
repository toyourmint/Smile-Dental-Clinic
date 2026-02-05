import 'package:flutter/material.dart';
import 'package:mylogin/services/auth_service.dart';
import 'otp_screen.dart';

class ForgetEmailScreen extends StatefulWidget {
  const ForgetEmailScreen({super.key});

  @override
  State<ForgetEmailScreen> createState() => _ForgetEmailScreenState();
}

class _ForgetEmailScreenState extends State<ForgetEmailScreen> {
  final controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _requestOtp() async {
    final email = controller.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกอีเมล")),
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
            content: Text(result['body']['message'] ?? "เกิดข้อผิดพลาด"),
          ),
        );
      }
    } catch (e, stack) {
      print("FORGOT PASSWORD ERROR: $e");
      print(stack);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ลืมรหัสผ่าน")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "อีเมล",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
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
          ],
        ),
      ),
    );
  }
}
