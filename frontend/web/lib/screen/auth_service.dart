import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/screen/login_web.dart';

class AuthService {
  static bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
      );

      final exp = payload['exp'];
      if (exp == null) return false;

      return DateTime.now().millisecondsSinceEpoch / 1000 > exp;
    } catch (_) {
      return true;
    }
  }

  static Future<String?> getValidToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('my_token');

    if (token == null || token.isEmpty) return null;
    if (isTokenExpired(token)) return null;

    return token;
  }

  static Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('my_token');

    if (token != null && token.isNotEmpty) {
      try {
        await http.post(
          Uri.parse('http://localhost:3000/api/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (_) {}
    }

    // ลบเฉพาะ session ไม่ลบ saved_email และ remember_email
    await prefs.remove('my_token');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
    await prefs.remove('user_name');

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}