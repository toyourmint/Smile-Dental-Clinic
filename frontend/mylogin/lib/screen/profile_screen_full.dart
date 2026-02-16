import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

////////////////////////////////////////////////////////////
/// MODEL
////////////////////////////////////////////////////////////
class ProfileModel {
  final String hn;
  final String firstName;
  final String lastName;
  final String phone;
  final String birthDate;
  final String profileImage;
  final String address;
  final String subdistrict;
  final String district;
  final String province;
  final String zip;
  final String disease;
  final String allergies;
  final String medicine;
  final String rights;
  final String limit;

  ProfileModel({
    required this.hn,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.birthDate,
    required this.profileImage,
    required this.address,
    required this.subdistrict,
    required this.district,
    required this.province,
    required this.zip,
    required this.disease,
    required this.allergies,
    required this.medicine,
    required this.rights,
    required this.limit,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      hn: json['hn'] ?? "",
      firstName: json['first_name'] ?? "",
      lastName: json['last_name'] ?? "",
      phone: json['phone'] ?? "",
      birthDate: json['birth_date'] ?? "",
      profileImage: json['profile_image'] ?? "",
      address: json['address_line'] ?? "",
      subdistrict: json['subdistrict'] ?? "",
      district: json['district'] ?? "",
      province: json['province'] ?? "",
      zip: json['postcode'] ?? "",
      disease: json['disease'] ?? "",
      allergies: json['allergies'] ?? "",
      medicine: json['medicine'] ?? "",
      rights: json['rights'] ?? "",
      limit: json['limit'] ?? "",
    );
  }

  /// 🔥 สำหรับ Mock Mode
  factory ProfileModel.empty() {
    return ProfileModel(
      hn: "",
      firstName: "",
      lastName: "",
      phone: "",
      birthDate: "",
      profileImage: "",
      address: "",
      subdistrict: "",
      district: "",
      province: "",
      zip: "",
      disease: "",
      allergies: "",
      medicine: "",
      rights: "",
      limit: "",
    );
  }
}

////////////////////////////////////////////////////////////
/// SCREEN
////////////////////////////////////////////////////////////
class ProfileScreenFull extends StatefulWidget {
  final String token;

  const ProfileScreenFull({super.key, required this.token});

  @override
  State<ProfileScreenFull> createState() => _ProfileScreenFullState();
}

class _ProfileScreenFullState extends State<ProfileScreenFull>
    with SingleTickerProviderStateMixin {

  static const bool useMock = true; 
  // 🔥 เปลี่ยนเป็น false เมื่อจะใช้ API จริง

  late TabController _tabController;
  ProfileModel? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    if (useMock) {
      /// 🧪 MOCK MODE
      user = ProfileModel.empty();
      isLoading = false;
    } else {
      /// 🌐 REAL API MODE
      fetchProfile();
    }
  }

  ////////////////////////////////////////////////////////////
  /// API
  ////////////////////////////////////////////////////////////
  Future<void> fetchProfile() async {
    const url = "http://YOUR_API_URL/api/profile";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json"
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          user = ProfileModel.fromJson(data);
          isLoading = false;
        });
      } else {
        throw Exception("โหลดข้อมูลไม่สำเร็จ");
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  ////////////////////////////////////////////////////////////
  /// Utility
  ////////////////////////////////////////////////////////////
  int calculateAge(String birth) {
    if (birth.isEmpty) return 0;

    DateTime b = DateTime.parse(birth);
    DateTime today = DateTime.now();
    int age = today.year - b.year;

    if (today.month < b.month ||
        (today.month == b.month && today.day < b.day)) {
      age--;
    }
    return age;
  }

  String fullAddress() {
    if (user == null) return "";
    return "${user!.address} "
        "${user!.subdistrict} "
        "${user!.district} "
        "${user!.province} "
        "${user!.zip}";
  }

  ////////////////////////////////////////////////////////////
  /// UI
  ////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("โหลดข้อมูลไม่สำเร็จ")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("ข้อมูลส่วนตัว")),
      body: Column(
        children: [
          const SizedBox(height: 20),

          /// 🔥 Profile Image
          CircleAvatar(
            radius: 55,
            backgroundImage: user!.profileImage.isNotEmpty
                ? NetworkImage(user!.profileImage)
                : null,
            child: user!.profileImage.isEmpty
                ? const Icon(Icons.person, size: 55)
                : null,
          ),

          const SizedBox(height: 10),

          Text(
            "คุณ ${user!.firstName} ${user!.lastName}",
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          Text("รหัสผู้ป่วย : ${user!.hn}"),

          const SizedBox(height: 16),

          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "ข้อมูลส่วนตัว"),
              Tab(text: "ข้อมูลทางการแพทย์"),
              Tab(text: "สิทธิประโยชน์"),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _personalTab(),
                _medicalTab(),
                _benefitTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _personalTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field("ชื่อ - นามสกุล",
            "${user!.firstName} ${user!.lastName}"),
        _field("เบอร์โทรศัพท์", user!.phone),
        _field("อายุ",
            calculateAge(user!.birthDate) == 0
                ? ""
                : calculateAge(user!.birthDate).toString()),
        _field("ที่อยู่", fullAddress()),
      ],
    );
  }

  Widget _medicalTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field("โรคประจำตัว", user!.disease),
        _field("ประวัติการแพ้", user!.allergies),
        _field("ยาประจำตัว", user!.medicine),
      ],
    );
  }

  Widget _benefitTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field("สิทธิการรักษา", user!.rights),
        _field("วงเงิน", user!.limit),
      ],
    );
  }

  Widget _field(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue),
            ),
            child: Text(value),
          ),
        ],
      ),
    );
  }
}