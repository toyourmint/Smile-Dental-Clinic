import 'package:flutter/material.dart';
import 'package:mylogin/screen/register_screen.dart';
import 'package:mylogin/widget/logo.dart';
import 'package:mylogin/services/auth_service.dart';
import 'package:mylogin/screen/main_wrapper.dart'; 
import 'forget_email_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  /// =============================
  /// LOGIN FUNCTION
  /// =============================
  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    /// เช็คข้อมูลก่อนยิง API
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบ")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (result['statusCode'] == 200) {
        /// สำเร็จ → ไปหน้า Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainWrapper(
            userName: result['body']['user']['first_name'],
            userId: result['body']['user']['id'],      // ⭐ สำคัญ
          ),

          ),
        );

      } else {
        /// error จาก backend
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['body']['message'] ?? "เข้าสู่ระบบไม่สำเร็จ",
            ),
          ),
        );
      }
    } catch (e, stack) {
      /// log ไว้ debug (ไม่โชว์ user)
      debugPrint("LOGIN ERROR: $e");
      debugPrintStack(stackTrace: stack);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เชื่อมต่อเซิร์ฟเวอร์ไม่ได้")),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// =============================
  /// DISPOSE
  /// =============================
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// =============================
  /// UI
  /// =============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              const SizedBox(height: 10),

              /// LOGO
              const Center(child: LogoWidget()),

              const SizedBox(height: 60),

              const Text(
                "เข้าสู่ระบบ",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              /// ================= EMAIL =================
              const Text("อีเมล"),
              const SizedBox(height: 6),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: "name@gmail.com",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// ================= PASSWORD =================
              const Text("รหัสผ่าน"),
              const SizedBox(height: 6),

              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(), // 🔥 กด Enter แล้ว login ได้
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              /// ================= FORGOT PASSWORD =================
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgetEmailScreen(),
                      ),
                    );
                  },
                  child: const Text("ลืมรหัสผ่าน ?"),
                ),
              ),

              const SizedBox(height: 10),

              /// ================= LOGIN BUTTON =================
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "เข้าสู่ระบบ",
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              /// ================= REGISTER =================
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("ยังไม่มีบัญชี ? "),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text("ลงทะเบียน"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
