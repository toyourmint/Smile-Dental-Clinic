import 'package:flutter/material.dart';
import 'package:mylogin/services/auth_service.dart';
import 'login_screen.dart';

class CreatePasswordScreen extends StatefulWidget {
  final String email;

  const CreatePasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<CreatePasswordScreen> createState() =>
      _CreatePasswordScreenState();
}

class _CreatePasswordScreenState
    extends State<CreatePasswordScreen> {
  final passController = TextEditingController();
  final confirmController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool loading = false;

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    await AuthService.setPassword(
      email: widget.email,
      password: passController.text,
    );

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

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
              TextFormField(
                controller: passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "รหัสผ่าน",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.length < 6 ? "อย่างน้อย 6 ตัว" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "ยืนยันรหัสผ่าน",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v != passController.text
                        ? "รหัสผ่านไม่ตรงกัน"
                        : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: loading ? null : submit,
                child: const Text("ยืนยัน"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
