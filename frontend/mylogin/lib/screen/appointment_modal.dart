class AppointmentModel {
  final String id;
  final String serviceName;
  final DateTime date;
  final String time;
  final int queueNumber;
  final String firstName;
  final String lastName;
  final String doctorName;

  AppointmentModel({
    required this.id,
    required this.serviceName,
    required this.date,
    required this.time,
    required this.queueNumber,
    required this.firstName,
    required this.lastName,
    this.doctorName = "ไม่ระบุแพทย์",
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      /// ⭐ id นัดหมาย
      id: (json['id'] ?? json['apt_id']).toString(),

      /// ⭐ ชื่อบริการ
      serviceName:
          json['service_name'] ??
          json['reason'] ??
          "ตรวจทั่วไป",

      /// ⭐ ชื่อหมอ
      doctorName:
          json['doctor_name'] ??
          "ไม่ระบุแพทย์",

      /// ⭐ วันที่
      date: DateTime.parse(json['appointment_date']),

      /// ⭐ เวลา
      time: (json['appointment_time'] as String).substring(0, 5),

      /// ⭐ เลขคิว
      queueNumber:
          json['queue_number'] ??
          json['apt_id'] ??
          json['id'] ??
          0,

      /// ⭐ ชื่อผู้ป่วย
      firstName: json['first_name'] ?? "",
      lastName: json['last_name'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceName': serviceName,
      'date': date.toIso8601String(),
      'time': time,
      'queueNumber': queueNumber,
      'firstName': firstName,
      'lastName': lastName,
      'doctorName': doctorName,
    };
  }
}
