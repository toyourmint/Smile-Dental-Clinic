import 'package:flutter/material.dart';
import 'reset_password_screen.dart';
import 'create_password_screen.dart';

class OTPScreen extends StatelessWidget {
  final bool isReset;

  const OTPScreen({super.key, this.isReset = false});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("OTP")),

      body: Center(
        child: ElevatedButton(
          child: const Text("ยืนยัน OTP"),
          onPressed: () {

            if (isReset) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const ResetPasswordScreen(),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreatePasswordScreen(),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
