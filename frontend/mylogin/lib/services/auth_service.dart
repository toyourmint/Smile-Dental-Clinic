import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  /// ⚠️ Android Emulator ใช้ 10.0.2.2
  /// ถ้าเป็นเครื่องจริง → ใช้ IP เครื่อง backend
  static const String baseUrl = 'http://10.0.2.2:3000/api/auth';

  // =========================
  // LOGIN
  // =========================
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'loginIdentifier': email,
        'password': password,
      }),
    );

    return {
      'statusCode': res.statusCode,
      'body': jsonDecode(res.body),
    };
  }

  // =========================
  // REGISTER
  // =========================
  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> data,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    return {
      'statusCode': res.statusCode,
      'body': jsonDecode(res.body),
    };
  }

  // =========================
  // VERIFY OTP
  // =========================
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
      }),
    );

    return {
      'statusCode': res.statusCode,
      'body': jsonDecode(res.body),
    };
  }

  // =========================
  // FORGOT PASSWORD (REQUEST OTP)
  // =========================
  static Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
      }),
    );

    return {
      'statusCode': res.statusCode,
      'body': jsonDecode(res.body),
    };
  }

  // =========================
  // SET PASSWORD (REGISTER + RESET)
  // =========================
  static Future<Map<String, dynamic>> setPassword({
    required String email,
    required String password,
    required String confirmPassword,
    required String otp,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/set-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'otp': otp,
      }),
    );

    return {
      'statusCode': res.statusCode,
      'body': jsonDecode(res.body),
    };
  }
}
