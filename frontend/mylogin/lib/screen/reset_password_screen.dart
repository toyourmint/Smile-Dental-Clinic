import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'otp_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {

  final pass1 = TextEditingController();
  final pass2 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("สร้างรหัสผ่านใหม่")),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            TextField(controller: pass1, obscureText: true),
            const SizedBox(height: 12),
            TextField(controller: pass2, obscureText: true),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                if (pass1.text == pass2.text) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                }
              },
              child: const Text("ยืนยัน"),
            )
          ],
        ),
      ),
    );
  }
}
