import 'package:flutter/material.dart';
import 'otp_screen.dart';

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

            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "อีเมล",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OTPScreen(isReset: true),
                  ),
                );
              },
              child: const Text("รับ OTP"),
            )
          ],
        ),
      ),
    );
  }
}
