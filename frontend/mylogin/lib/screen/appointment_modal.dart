// ไฟล์: screen/appointment_modal.dart (หรือ model/appointment_model.dart)

class AppointmentModel {
  final String? id;
  final String serviceName;
  final String doctorName;
  final DateTime date;
  final String time;
  final int queueNumber;
  final String firstName; 
  final String lastName;

  AppointmentModel({
    this.id,
    required this.serviceName,
    this.doctorName = "ทพ. สมมติ เชี่ยวชาญ", // ค่า Default
    required this.date,
    required this.time,
    required this.queueNumber,
    required this.firstName,
    required this.lastName,
  });

  // 1. Factory: แปลง JSON จาก Server -> เป็น AppointmentModel
  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      serviceName: json['serviceName'],
      doctorName: json['doctorName'] ?? "ไม่ระบุแพทย์",
      date: DateTime.parse(json['date']), // แปลง String เป็น DateTime
      time: json['time'],
      queueNumber: json['queueNumber'] is int 
          ? json['queueNumber'] 
          : int.parse(json['queueNumber'].toString()), // กันเหนียวกรณีส่งมาเป็น String
          firstName: json['firstName'] ?? "",
      lastName: json['lastName'] ?? "",
    );
  }

  get userName => null;

  // 2. Method: แปลง AppointmentModel -> เป็น JSON ส่งให้ Server
  Map<String, dynamic> toJson() {
    return {
      'id': id, // เพิ่ม id ไปด้วยเผื่อใช้
      'serviceName': serviceName,
      'doctorName': doctorName,
      'date': date.toIso8601String(),
      'time': time,
      'queueNumber': queueNumber,
    };
  }
} // <--- ปิด Class AppointmentModel ตรงนี้

// *** ตัวแปร Global สำหรับเก็บข้อมูลชั่วคราว (Mock Database) ***
List<AppointmentModel> myAppointments = [];

// [เพิ่ม] จำลองข้อมูล User ที่ Login เข้ามา
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role; // เช่น 'patient', 'doctor'

  UserProfile({
    this.id = "1",
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
    );
  }
} // <--- ปิด Class UserProfile ตรงนี้

// สร้างตัวแปร Global ไว้ทดสอบ
UserProfile currentUser = UserProfile(
  name: "คุณ Anna",
  email: "Anna@gmail.com",
  role: "patient",
);