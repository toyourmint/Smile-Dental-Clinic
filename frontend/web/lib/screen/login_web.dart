import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/screen/home_web.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // เพิ่มตัวแปรเช็คสถานะกำลังโหลด
  bool _isLoading = false;

  // ฟังก์ชัน Login เชื่อมต่อ Backend
  Future<void> _login() async {
    // 1. ตรวจสอบข้อมูลว่าง
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกอีเมลและรหัสผ่าน'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. ยิง API ไปที่ Backend
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          // Backend ของคุณใช้ชื่อตัวแปร loginIdentifier รับค่า email หรือ phone
          "loginIdentifier": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
        }),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      // 3. เช็คผลลัพธ์
      if (response.statusCode == 200) {
        // --- Login สำเร็จ ---
        
        // บันทึก Token และข้อมูลผู้ใช้ลงเครื่อง
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('my_token', data['token']);
        await prefs.setString('user_role', data['user']['role']);
        await prefs.setInt('user_id', data['user']['id']);
        await prefs.setString('user_name', "${data['user']['first_name']} ${data['user']['last_name']}");

        // ไปหน้า Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // --- Login ไม่สำเร็จ ---
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ'), 
            backgroundColor: Colors.red
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                      label: 'อีเมล หรือ เบอร์โทรศัพท์', // ปรับ label ให้สื่อความหมายตรง backend
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
                        // ถ้ากำลังโหลด ให้ปิดปุ่มกด
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const SizedBox(
                              width: 24, 
                              height: 24, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                          : const Text(
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        floatingLabelBehavior: FloatingLabelBehavior.always, 
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400), 
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0062E0), width: 1.5),
        ),
      ),
    );
  }
}