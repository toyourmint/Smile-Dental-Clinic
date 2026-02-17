import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/home_web.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // สีหลัก
    const Color primaryBlue = Color(0xFF0062E0);
    const Color bgLightBlue = Color(0xFFEAF6FF);

    return Scaffold(
      backgroundColor: bgLightBlue,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- โลโก้ ---
              const Text(
                'SMILE\nDENTAL\nCLINIC',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 40),

              // --- กล่อง Login ---
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 30),

                    _buildTextField(
                      label: 'อีเมล', // ในรูปเป็น text ธรรมดา
                      controller: _emailController,
                      obscureText: false,
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      label: 'รหัสผ่าน',
                      controller: _passwordController,
                      obscureText: true,
                    ),
                    
                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'ลืมรหัสผ่าน ?',
                          style: TextStyle(
                            color: Color(0xFF4A90E2),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: ใส่ Logic การ Login ตรงนี้
                          print("Email: ${_emailController.text}");
                          print("Password: ${_passwordController.text}");
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'เข้าสู่ระบบ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

// แก้ไขฟังก์ชันนี้ในไฟล์ login_screen.dart
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
  }) {
    // ลบ Column และ Text ที่แยกออกมาทิ้งไป
    // เหลือไว้แค่ TextField ตัวเดียว
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      decoration: InputDecoration(
        // 1. ใส่ Label ที่นี่
        labelText: label, 
        // 2. ตั้งค่าสไตล์ให้ Label เป็นสีเทา
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        // 3. คำสั่งสำคัญ! บังคับให้ Label ลอยอยู่บนเส้นขอบตลอดเวลา
        floatingLabelBehavior: FloatingLabelBehavior.always, 
        
        // ปรับระยะห่างภายในนิดหน่อยให้สวยงาม
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          // ปรับสีเส้นขอบให้เข้มขึ้นนิดนึงเพื่อให้เห็นชัดตอน Label ทับ
          borderSide: BorderSide(color: Colors.grey.shade400), 
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          // เพิ่มความหนาเส้นตอนกดเล็กน้อย
          borderSide: const BorderSide(color: Color(0xFF0062E0), width: 1.5),
        ),
      ),
    );
  }
}