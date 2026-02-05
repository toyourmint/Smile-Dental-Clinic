import 'package:flutter/material.dart';
import 'package:mylogin/services/auth_service.dart';
import 'create_password_screen.dart';

class OTPScreen extends StatefulWidget {
  final bool isReset;
  final String? email; // ✅ รับ email จาก Register

  const OTPScreen({
    super.key,
    this.isReset = false,
    this.email,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {

  final List<TextEditingController> controllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> focusNodes =
      List.generate(6, (_) => FocusNode());

  bool _isLoading = false;

  /// =============================
  /// รวม OTP
  /// =============================
  String get otp =>
      controllers.map((e) => e.text).join();

  /// =============================
  /// verify OTP
  /// =============================
  Future<void> _verifyOtp() async {
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอก OTP ให้ครบ 6 หลัก")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      /// 🔥 เรียก backend
      final result = await AuthService.verifyOtp(
        email: widget.email,
        otp: otp,
      );

      if (!mounted) return;

      if (result['statusCode'] == 200) {
        if (widget.isReset) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CreatePasswordScreen(email: widget.email),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CreatePasswordScreen(email: widget.email),
            ),
          );
        }
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

  /// =============================
  /// ช่อง OTP 1 ช่อง
  /// =============================
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
          /// ไปช่องถัดไป
          if (value.isNotEmpty && index < 5) {
            focusNodes[index + 1].requestFocus();
          }

          /// ลบแล้วถอยกลับ
          if (value.isEmpty && index > 0) {
            focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  /// =============================
  /// dispose
  /// =============================
  @override
  void dispose() {
    for (var c in controllers) {
      c.dispose();
    }
    for (var f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  /// =============================
  /// UI
  /// =============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ยืนยัน OTP")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "กรอกรหัส OTP 6 หลัก",
              style: TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 8),

            /// แสดง email
            if (widget.email != null)
              Text(
                widget.email!,
                style: const TextStyle(color: Colors.grey),
              ),

            const SizedBox(height: 30),

            /// OTP 6 ช่อง
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, buildOtpBox),
            ),

            const SizedBox(height: 30),

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
          ],
        ),
      ),
    );
  }
}
