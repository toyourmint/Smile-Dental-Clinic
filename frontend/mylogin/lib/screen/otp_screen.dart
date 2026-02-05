import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mylogin/services/auth_service.dart';
import 'package:mylogin/widget/logo.dart';
import 'create_password_screen.dart';

class OTPScreen extends StatefulWidget {
  final bool isReset;
  final String email; // ✅ บังคับต้องมี email

  const OTPScreen({
    super.key,
    this.isReset = false,
    required this.email,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  /// controllers OTP 6 ช่อง
  final List<TextEditingController> controllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> focusNodes =
      List.generate(6, (_) => FocusNode());

  bool _isLoading = false;

  /// ================================
  /// ⏰ Countdown 5 นาที
  /// ================================
  int seconds = 300;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    seconds = 300;
    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (seconds == 0) {
        timer?.cancel();
      } else {
        setState(() => seconds--);
      }
    });
  }

  String get timeText {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  /// ================================
  /// รวม OTP
  /// ================================
  String get otp => controllers.map((e) => e.text).join();

  /// ================================
  /// verify OTP
  /// ================================
  Future<void> _verifyOtp() async {
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอก OTP ให้ครบ 6 หลัก")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.verifyOtp(
        email: widget.email,
        otp: otp,
      );

      if (!mounted) return;

      if (result['statusCode'] == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CreatePasswordScreen(email: widget.email),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP ไม่ถูกต้อง")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เชื่อมต่อเซิร์ฟเวอร์ไม่ได้")),
      );
    }

    setState(() => _isLoading = false);
  }

  /// ================================
  /// resend OTP
  /// ================================
  Future<void> _resendOtp() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.resendOtp(email: widget.email);

      startTimer(); // รีเซ็ตเวลา

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ส่ง OTP ใหม่แล้ว")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ส่ง OTP ไม่สำเร็จ")),
      );
    }

    setState(() => _isLoading = false);
  }

  /// ================================
  /// ช่อง OTP 1 ช่อง
  /// ================================
  Widget buildOtpBox(int index) {
    return SizedBox(
      width: 45,
      child: TextField(
        controller: controllers[index],
        focusNode: focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 22),
        decoration: const InputDecoration(
          counterText: "",
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            focusNodes[index + 1].requestFocus();
          }
          if (value.isEmpty && index > 0) {
            focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  /// ================================
  /// dispose
  /// ================================
  @override
  void dispose() {
    timer?.cancel();

    for (var c in controllers) {
      c.dispose();
    }
    for (var f in focusNodes) {
      f.dispose();
    }

    super.dispose();
  }

  /// ================================
  /// UI
  /// ================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OTP")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Center(child: LogoWidget()),

            const SizedBox(height: 40),

            const Text(
              "ยืนยันรหัสผ่านที่ได้รับในอีเมลที่ลงทะเบียนไว้",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            /// email
            Text(
              widget.email,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            /// OTP 6 ช่อง
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, buildOtpBox),
            ),

            const SizedBox(height: 10),

            /// timer
            Text(
              timeText,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            /// ปุ่มยืนยัน
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("ยืนยัน"),
              ),
            ),

            const SizedBox(height: 16),

            /// resend
            seconds == 0
    ? RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14),
          children: [
            const TextSpan(
              text: "ไม่ได้รับ OTP ? ",
              style: TextStyle(color: Colors.grey),
            ),
            WidgetSpan(
              child: GestureDetector(
                onTap: _isLoading ? null : _resendOtp,
                child: const Text(
                  "ส่งอีกครั้ง",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      )
    : Text(
        "ส่งใหม่ได้ใน $timeText",
        style: const TextStyle(color: Colors.grey),
      ),

          ],
        ),
      ),
    );
  }
}
