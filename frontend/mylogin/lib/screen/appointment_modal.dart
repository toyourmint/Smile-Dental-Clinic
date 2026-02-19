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
    required this.date,
    required this.time,
    required this.queueNumber,
    required this.firstName,
    required this.lastName,
    this.doctorName = "ไม่ระบุแพทย์",
  });

  // 1. Factory: แปลง JSON จาก Server -> เป็น AppointmentModel
  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['apt_id'].toString(),
      serviceName: json['reason'] ?? "ตรวจทั่วไป",
      doctorName: json['doctor_name'] ?? "ไม่ระบุแพทย์",
      date: DateTime.parse(json['appointment_date']),
      time: json['appointment_time'].substring(0, 5),
      queueNumber: json['apt_id'] ?? 0,
      firstName: json['first_name'] ?? "",
      lastName: json['last_name'] ?? "",
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

