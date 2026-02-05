import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/auth';

  /// ================= LOGIN =================
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'loginIdentifier': email,
        'password': password,
      }),
    );

    return {
      'statusCode': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }

  /// ================= REGISTER =================
  static Future<Map<String, dynamic>> register(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    return {
      'statusCode': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }

  /// ================= SEND OTP =================
  static Future<Map<String, dynamic>> sendOtp({
    required String email,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/send-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    return {
      "statusCode": res.statusCode,
      "body": jsonDecode(res.body),
    };
  }

  /// ================= VERIFY OTP =================
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "otp": otp,
      }),
    );

    return {
      "statusCode": res.statusCode,
      "body": jsonDecode(res.body),
    };
  }

  /// ================= SET PASSWORD =================
  static Future<Map<String, dynamic>> setPassword({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/set-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    return {
      "statusCode": res.statusCode,
      "body": jsonDecode(res.body),
    };
  }
  static Future<void> resendOtp({
  required String email,
}) async {
  await http.post(
    Uri.parse("$baseUrl/resend-otp"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"email": email}),
  );
}

}
