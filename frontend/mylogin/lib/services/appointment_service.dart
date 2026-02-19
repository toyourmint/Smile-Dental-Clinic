import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../screen/appointment_modal.dart';

class AppointmentService {
  static const String baseUrl = "http://10.0.2.2:3000";

  /// ==============================
  /// 📅 ดึงรายการนัดหมาย
  /// ==============================
  static Future<List<AppointmentModel>> fetchAppointments() async {
    final response =
        await http.get(Uri.parse("$baseUrl/api/apm/all"));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List list = data['appointments'] ?? [];

      return list.map((e) => AppointmentModel.fromJson(e)).toList();
    } else {
      throw Exception("โหลดข้อมูลนัดหมายไม่สำเร็จ");
    }
  }

  /// ==============================
  /// 🦷 จองคิว (ใช้ JWT Token)
  /// ==============================
  static Future<bool> bookAppointment({
    required String date,
    required String time,
    String reason = "",
    String notes = "",
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('my_token');

    if (token == null) {
      throw Exception("Token not found");
    }

    final response = await http.post(
      Uri.parse("$baseUrl/api/apm/apmUser"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "appointment_date": date,
        "appointment_time": time,
        "reason": reason,
        "notes": notes,
      }),
    );

    final data = json.decode(response.body);
    return response.statusCode == 201 && data['success'] == true;
  }

  /// ==============================
  /// ❌ ยกเลิกนัดหมาย
  /// ==============================
  static Future<bool> cancelAppointment(String id) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/apm/cancel/$id"),
    );

    return response.statusCode == 200;
  }

  /// ==============================
  /// ⏰ ดึงเวลาว่าง
  /// ==============================
  static Future<List<Slot>> getAvailableSlots(DateTime date) async {
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final response = await http.get(
      Uri.parse("$baseUrl/api/apm/slots?date=$formattedDate"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      return (data['slots'] as List)
          .map((e) => Slot.fromJson(e))
          .toList();
    } else {
      throw Exception("โหลดเวลาว่างไม่สำเร็จ");
    }
  }

  /// ==============================
  /// 🔢 คิวปัจจุบัน
  /// ==============================
  static Future<String> getCurrentQueueFromClinic() async {
    final response =
        await http.get(Uri.parse("$baseUrl/api/queue/room"));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['current_A'] ?? '-';
    } else {
      return '-';
    }
  }
  static Future<bool> rescheduleAppointment({
    required String id,
    required String date,
    required String time,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/apm/reschedule/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "appointment_date": date,
        "appointment_time": time,
      }),
    );

    return response.statusCode == 200;
  }

}

/// ==============================
/// Slot Model
/// ==============================
class Slot {
  final String time;
  final bool isFull;

  Slot({required this.time, required this.isFull});

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      time: json['time'],
      isFull: json['isFull'] ?? false,
    );
  }
}
