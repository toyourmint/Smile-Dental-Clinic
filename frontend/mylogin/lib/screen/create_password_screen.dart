import 'package:flutter/material.dart';
import 'package:mylogin/services/auth_service.dart';
import 'package:mylogin/widget/logo.dart';
import 'login_screen.dart';

class CreatePasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const CreatePasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<CreatePasswordScreen> createState() => CreatePasswordScreenState();
}

class CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final passController = TextEditingController();
  final confirmController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  // ✅ เพิ่มตัวแปรเปิด/ปิดตา
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  /// =========================
  /// SUBMIT
  /// =========================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.setPassword(
        email: widget.email,
        password: passController.text.trim(),
        confirmPassword: confirmController.text.trim(),
        otp: widget.otp,
      );

      if (!mounted) return;

      if (result['statusCode'] == 200) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['body']['message'] ?? "เกิดข้อผิดพลาด"),
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
              const Center(child: LogoWidget()),
              const SizedBox(height: 30),

              /// =========================
              /// Password
              /// =========================
              TextFormField(
                controller: passController,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: "รหัสผ่าน",
                  border: const OutlineInputBorder(),

                  // ✅ ปุ่มตา
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePass = !_obscurePass;
                      });
                    },
                  ),
                ),
                validator: (v) =>
                    v!.length < 6 ? "อย่างน้อย 6 ตัวอักษร" : null,
              ),

              const SizedBox(height: 16),

              /// =========================
              /// Confirm
              /// =========================
              TextFormField(
                controller: confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: "ยืนยันรหัสผ่าน",
                  border: const OutlineInputBorder(),

                  // ✅ ปุ่มตา
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                  ),
                ),
                validator: (v) =>
                    v != passController.text ? "รหัสผ่านไม่ตรงกัน" : null,
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
