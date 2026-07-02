import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../screen/appointment_modal.dart';

class AppointmentService {
  static const String baseUrl = "http://172.20.10.6:3000";

  /// 🔐 helper ดึง token + header
  static Future<Map<String, String>> _authHeader() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('my_token');

    if (token == null || token.isEmpty) {
      throw Exception("Session expired");
    }

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  /// ==============================
  /// 📅 ดึงรายการนัดหมาย
  /// ==============================
  static Future<List<AppointmentModel>> fetchAppointments() async {
    final headers = await _authHeader();

    final response = await http.get(
      Uri.parse("$baseUrl/api/apm/my"), // ⭐ เปลี่ยนตรงนี้
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List list = data['appointments'] ?? [];
      return list.map((e) => AppointmentModel.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception("Session expired");
    } else {
      throw Exception("โหลดข้อมูลนัดหมายไม่สำเร็จ");
    }
  }

  /// ==============================
  /// 🦷 จองคิว
  /// ==============================
  static Future<bool> bookAppointment({
    required String date,
    required String time,
    
    String reason = "",
    String notes = "",
  }) async {
    final headers = await _authHeader();

    final response = await http.post(
      Uri.parse("$baseUrl/api/apm/apmUser"),
      headers: headers,
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
    final headers = await _authHeader();

    final response = await http.put(
      Uri.parse("$baseUrl/api/apm/cancel/$id"),
      headers: headers,
    );

    return response.statusCode == 200;
  }

  /// ==============================
  /// ⏰ ดึงเวลาว่าง
  /// ==============================
  static Future<List<Slot>> getAvailableSlots(DateTime date) async {
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final headers = await _authHeader();

    final response = await http.get(
      Uri.parse("$baseUrl/api/apm/slots?date=$formattedDate"),
      headers: headers,
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

  static Future<Map<String, dynamic>?> getMyQueue() async {
    final prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('user_id');

    if (userId == null) {
      throw Exception("User not found");
    }

    final headers = await _authHeader();

    final res = await http.get(
      Uri.parse('$baseUrl/api/queue/my/$userId'),
      headers: {
        ...headers,
        "Cache-Control": "no-cache",   // ⭐ ป้องกัน cache
      },
    );

    if (res.statusCode == 200) {

      // ⭐ debug response
      print("QUEUE API RAW => ${res.body}");

      if (res.body.isEmpty || res.body == "null") {
        return null;
      }

      final data = json.decode(res.body) as Map<String, dynamic>;


      // ⭐ กัน backend ส่ง {} กลับมา
      if (data == null || data is! Map || data.isEmpty) {
        return null;
      }

      // ⭐ กันสถานะที่ไม่ต้องแสดง
      final status = data['status'];

      if (status != 'waiting' && status != 'in_room') {
        return null;
      }

      return data;
    }

    throw Exception('โหลดคิวไม่สำเร็จ');
  }




  /// ==============================
  /// 🔢 คิวปัจจุบัน
  /// ==============================
  static Future<Map<String, dynamic>> getCurrentQueueFromClinic() async {
    final response =
        await http.get(Uri.parse("$baseUrl/api/queue/room"));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {};
    }
  }



  /// ==============================
  /// 🔁 เลื่อนนัด
  /// ==============================
  static Future<bool> rescheduleAppointment({
    required String id,
    required String date,
    required String time,
  }) async {
    final headers = await _authHeader();

    final response = await http.put(
      Uri.parse("$baseUrl/api/apm/reschedule/$id"),
      headers: headers,
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
