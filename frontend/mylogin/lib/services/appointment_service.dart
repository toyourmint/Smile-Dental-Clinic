//import 'dart:convert';
import 'dart:async';
//import 'dart:math';
//import 'package:http/http.dart' as http;
import 'package:mylogin/screen/appointment_modal.dart'; // เช็คชื่อไฟล์ให้ตรง (modal หรือ model)

class AppointmentService {
  
  // URL ของ Backend (เปลี่ยนตามจริง)
  static const String baseUrl = "http://192.168.1.X:3000/api";

  // =========================
  // 1. จำลองการดึงรอบเวลาว่าง (Mock Get Slots)
  // =========================
  static Future<List<String>> getAvailableSlots(DateTime date) async {
    // --- โค้ดต่อ Backend จริง ---
    /*
    String dateStr = "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
    try {
      final response = await http.get(Uri.parse('$baseUrl/slots?date=$dateStr'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['slots']);
      } else {
        throw Exception('Failed to load slots');
      }
    } catch (e) {
      print("API Error: $e");
      return [];
    }
    */
    
    // --- Mock Up ---
    await Future.delayed(const Duration(seconds: 1));

    // วันเสาร์-อาทิตย์ ร้านปิด
    if (date.weekday == 6 || date.weekday == 7) {
      return []; 
    }

    // เวลาทำการปกติ
    return [
      "09:00", "10:00", "11:00", 
      "13:00", "14:00", "15:00", 
      "16:00", "17:00",
    ];
  }

  // =========================
  // 2. ดึงเวลาที่ "ถูกจองแล้ว" (Get Booked Slots)
  // =========================
  static Future<List<dynamic>> getBookedSlots(DateTime date) async {
    // --- โค้ดต่อ Backend จริง ---
    /*
    try {
      final response = await http.get(Uri.parse('$baseUrl/booked?date=$date'));
      if (response.statusCode == 200) {
         final data = jsonDecode(response.body);
         return List<String>.from(data['bookedTimes']);
      }
      return [];
    } catch (e) { return []; }
    */

    // --- Mock Up ---
    await Future.delayed(const Duration(milliseconds: 500));

    final booked = myAppointments.where((appt) {
      return appt.date.year == date.year && 
             appt.date.month == date.month && 
             appt.date.day == date.day;
    }).map((appt) => appt.time).toList();

    return booked;
  }

  // =========================
  // จำลองดึงคิวปัจจุบันหน้าร้าน (Current Queue)
  // =========================
  static Future<int> getCurrentQueueFromClinic() async {
    // --- โค้ดต่อ Backend จริง ---
    /*
    try {
      final response = await http.get(Uri.parse('$baseUrl/queue/current'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['currentQueue'];
      }
    } catch (e) { print(e); }
    */

    // --- Mock Up ---
    await Future.delayed(const Duration(milliseconds: 500));
    return 5; 
  }

  // =========================
  // 3. จำลองการจองคิว (แก้ไขให้ Gen เลขคิว)
  // =========================
  static Future<Map<String, dynamic>> bookQueue({
    required String serviceName,
    required DateTime date,
    required String time,
    String? userId,
  }) async {
    // --- โค้ดต่อ Backend จริง ---
    /*
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/appointments'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId ?? currentUser.id,
          "service": serviceName,
          "date": date.toIso8601String(),
          "time": time,
        }),
      );

      if (response.statusCode == 201) {
        final newBookingJson = jsonDecode(response.body);
        myAppointments.add(AppointmentModel.fromJson(newBookingJson));
        return {'statusCode': 200, 'body': {'message': 'Success'}};
      } else {
        return {'statusCode': 400, 'body': {'message': 'Booking Failed'}};
      }
    } catch (e) {
      return {'statusCode': 500, 'body': {'message': 'Server Error $e'}};
    }
    */

    // --- Mock Up ---
    await Future.delayed(const Duration(seconds: 2));

    int newQueueNumber = 100 + myAppointments.length + 1;
    List<String> nameParts = currentUser.name.split(' ');
    String fName = nameParts.isNotEmpty ? nameParts[0] : "ไม่ระบุ";
    String lName = nameParts.length > 1 ? nameParts[1] : "";

    myAppointments.add(AppointmentModel(
      serviceName: serviceName,
      date: date,
      time: time,
      doctorName: "Dr. Joseph Brostito",
      queueNumber: newQueueNumber,
      firstName: fName, // ส่งชื่อจริงไปเก็บ
      lastName: lName,  // ส่งนามสกุลจริงไปเก็บ
    ));

    return {
      'statusCode': 200,
      'body': {'message': 'จองคิวสำเร็จ'}
    };
  }

  // =========================================================
  // 5. ยกเลิกนัดหมาย (Cancel Appointment - DELETE Request)
  // =========================================================
  // [แก้ไข] ใส่ static และย้ายเข้ามาในปีกกา class แล้ว
    // --- โค้ดต่อ Backend จริง ---
    /*
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/appointments/${appointment.id}'),
      );
      if (response.statusCode == 200) {
        myAppointments.remove(appointment);
        return true;
      }
      return false;
    } catch (e) { return false; }
    */

    // --- Mock Up ---
    static Future<bool> cancelAppointment(AppointmentModel appointment) async {
    await Future.delayed(const Duration(seconds: 1));
    myAppointments.remove(appointment); // ลบจาก List กลาง
    return true;
  }

} 