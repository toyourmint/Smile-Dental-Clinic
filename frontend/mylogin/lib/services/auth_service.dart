import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  /// Android Emulator → 10.0.2.2
  static const String baseUrl = 'http://10.0.2.2:3000/api/auth';

  static const _headers = {
    'Content-Type': 'application/json',
  };

  /// helper ลดโค้ดซ้ำ
  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );

    return {
      'statusCode': res.statusCode,
      'body': jsonDecode(res.body),
    };
  }

  // =========================
  // LOGIN
  // =========================
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _post('/login', {
      'loginIdentifier': email,
      'password': password,
    });
  }

  // =========================
  // REGISTER
  // =========================
  static Future<Map<String, dynamic>> register(
      Map<String, dynamic> data) {
    return _post('/register', data);
  }

  // =========================
  // REQUEST OTP (Forgot Password)
  // ใช้กับ ForgetEmailScreen
  // =========================
  static Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) {
    return _post('/forgot-password', {
      'email': email,
    });
  }

  // =========================
  // VERIFY OTP
  // ใช้กับ OTPScreen
  // =========================
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) {
    return _post('/verify-otp', {
      'email': email,
      'otp': otp,
    });
  }

  // =========================
  // RESEND OTP
  // ใช้กับปุ่ม "ส่งอีกครั้ง"
  // =========================
  static Future<Map<String, dynamic>> resendOtp({
    required String email,
  }) {
    return _post('/resend-otp', {
      'email': email,
    });
  }

  // =========================
  // SET PASSWORD
  // ใช้กับ CreatePasswordScreen
  // =========================
  static Future<Map<String, dynamic>> setPassword({
    required String email,
    required String password,
    required String confirmPassword,
    required String otp,
  }) {
    return _post('/set-password', {
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
      'otp': otp,
    });
  }
}
