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

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _rememberEmail = false;
  bool _obscurePassword = true; // ← สถานะแสดง/ซ่อนรหัสผ่าน

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _loadSavedEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email') ?? '';
    final rememberEmail = prefs.getBool('remember_email') ?? false;

    if (rememberEmail && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberEmail = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_passwordFocus);
      });
    }
  }

  Future<void> _saveEmailPreference(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_rememberEmail) {
      await prefs.setString('saved_email', email);
      await prefs.setBool('remember_email', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.setBool('remember_email', false);
    }
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกอีเมลและรหัสผ่าน'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/auth/admin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "loginIdentifier": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
        }),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveEmailPreference(_emailController.text.trim());

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('my_token', data['token']);
        await prefs.setString('user_role', data['user']['role']);
        await prefs.setInt('user_id', data['user']['id']);
        await prefs.setString('user_name', "${data['user']['first_name']} ${data['user']['last_name']}");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ'), backgroundColor: Colors.red),
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
              const Column(
                children: [
                  Text("SMILE",
                      style: TextStyle(fontSize: 39, fontWeight: FontWeight.bold, color: Colors.blue)),
                  Text("DENTAL",
                      style: TextStyle(fontSize: 39, fontWeight: FontWeight.bold, color: Colors.lightBlue)),
                  Text("CLINIC",
                      style: TextStyle(fontSize: 39, fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
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
                    const Text('เข้าสู่ระบบ',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 30),

                    // ช่องอีเมล
                    _buildTextField(
                      label: 'อีเมล',
                      controller: _emailController,
                      focusNode: _emailFocus,
                      obscureText: false,
                      onSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
                    ),
                    const SizedBox(height: 20),

                    // ช่องรหัสผ่าน + eye icon
                    _buildTextField(
                      label: 'รหัสผ่าน',
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: _obscurePassword,
                      onSubmitted: (_) { if (!_isLoading) _login(); },
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- แถว checkbox + ลืมรหัสผ่าน ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _rememberEmail = !_rememberEmail),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: _rememberEmail,
                                  onChanged: (val) => setState(() => _rememberEmail = val ?? false),
                                  activeColor: primaryBlue,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('จดจำอีเมล',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('ลืมรหัสผ่าน ?',
                              style: TextStyle(color: Color(0xFF4A90E2), fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('เข้าสู่ระบบ',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    FocusNode? focusNode,
    ValueChanged<String>? onSubmitted,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      focusNode: focusNode,
      onSubmitted: onSubmitted,
      textInputAction: obscureText ? TextInputAction.done : TextInputAction.next,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        suffixIcon: suffixIcon,
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