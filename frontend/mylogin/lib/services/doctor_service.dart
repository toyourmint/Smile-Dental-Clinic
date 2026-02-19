import 'dart:convert';
import 'package:http/http.dart' as http;

class Doctor {
  final int id;
  final String name;

  Doctor({
    required this.id,
    required this.name,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      name: json['doctor_name'],
    );
  }
}

class DoctorService {
  static const String url = "http://10.0.2.2:3000/api/user/doctor";

  static Future<List<Doctor>> fetchDoctors() async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      List data = jsonData['doctors'];

      return data.map((e) => Doctor.fromJson(e)).toList();
    } else {
      throw Exception("โหลดรายชื่อหมอไม่สำเร็จ");
    }
  }
}
