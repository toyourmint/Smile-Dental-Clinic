import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:mylogin/services/auth_service.dart';

class CreatePasswordScreen extends StatefulWidget {
  final String? email; // ✅ เพิ่มรับ email จาก OTP
  final String otp; // ✅ เพิ่ม otp

  const CreatePasswordScreen({
    super.key,
    this.email,
    required this.otp,
  });

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final passController = TextEditingController();
  final confirmController = TextEditingController();

  bool obscure1 = true;
  bool obscure2 = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  /// =========================
  /// SUBMIT PASSWORD
  /// =========================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      /// 🔥 ส่ง backend
      final result = await AuthService.setPassword(
        email: widget.email!, // ตอนนี้ต้องไม่เป็น null
        password: passController.text.trim(),
        confirmPassword: confirmController.text.trim(),
        otp: widget.otp,
      );


      if (!mounted) return;

      if (result['statusCode'] == 200) {
        /// กลับ Login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['body']['message'] ?? "เกิดข้อผิดพลาด")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เชื่อมต่อเซิร์ฟเวอร์ไม่ได้")),
      );
    }

    setState(() => _isLoading = false);
  }

  /// =========================
  /// UI
  /// =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("สร้างรหัสผ่าน")),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Form(
          key: _formKey,

          child: Column(
            children: [

              /// Password
              TextFormField(
                controller: passController,
                obscureText: obscure1,
                decoration: InputDecoration(
                  labelText: "รหัสผ่าน",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure1 ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => obscure1 = !obscure1);
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return "รหัสผ่านอย่างน้อย 6 ตัว";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// Confirm Password
              TextFormField(
                controller: confirmController,
                obscureText: obscure2,
                decoration: InputDecoration(
                  labelText: "ยืนยันรหัสผ่าน",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure2 ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => obscure2 = !obscure2);
                    },
                  ),
                ),
                validator: (value) {
                  if (value != passController.text) {
                    return "รหัสผ่านไม่ตรงกัน";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              /// Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("ยืนยัน"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
