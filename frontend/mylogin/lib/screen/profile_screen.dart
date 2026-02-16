import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic>? user;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchUser();
  }

  //////////////////////////////////////////////////////
  /// 🔹 เรียก API
  //////////////////////////////////////////////////////
  Future<void> fetchUser() async {
    final url = Uri.parse("http://10.0.2.2:3000/api/users/1");
    // 🔥 มือถือจริงให้เปลี่ยนเป็น IP เครื่องคอม

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          user = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "โหลดข้อมูลไม่สำเร็จ";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "เชื่อมต่อเซิร์ฟเวอร์ไม่ได้";
        isLoading = false;
      });
    }
  }

  //////////////////////////////////////////////////////
  /// 🔹 คำนวณอายุ
  //////////////////////////////////////////////////////
  int calculateAge(String birth) {
    DateTime b = DateTime.parse(birth);
    DateTime today = DateTime.now();

    int age = today.year - b.year;
    if (today.month < b.month ||
        (today.month == b.month && today.day < b.day)) {
      age--;
    }
    return age;
  }

  //////////////////////////////////////////////////////
  /// 🔹 format วันไทย
  //////////////////////////////////////////////////////
  String formatDate(String birth) {
    DateTime d = DateTime.parse(birth);
    return "${d.day} ${_monthThai(d.month)} ${d.year + 543}";
  }

  String _monthThai(int m) {
    const months = [
      "",
      "ม.ค.",
      "ก.พ.",
      "มี.ค.",
      "เม.ย.",
      "พ.ค.",
      "มิ.ย.",
      "ก.ค.",
      "ส.ค.",
      "ก.ย.",
      "ต.ค.",
      "พ.ย.",
      "ธ.ค."
    ];
    return months[m];
  }

  //////////////////////////////////////////////////////
  /// 🔹 รวมที่อยู่
  //////////////////////////////////////////////////////
  String fullAddress() {
    return "${user!['address_line']} "
        "${user!['subdistrict']} "
        "${user!['district']} "
        "${user!['province']} "
        "${user!['postal_code']}";
  }

  //////////////////////////////////////////////////////
  /// 🔹 UI
  //////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("ข้อมูลส่วนตัว"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : Column(
                  children: [
                    const SizedBox(height: 16),

                    const CircleAvatar(
                      radius: 55,
                      backgroundImage:
                          NetworkImage("https://i.pravatar.cc/300"),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "คุณ ${user!['first_name']} ${user!['last_name']}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 6),
                    Text("Citizen ID : ${user!['citizen_id'] ?? '-'}"),

                    const SizedBox(height: 16),

                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
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

  //////////////////////////////////////////////////////
  /// TAB 1 : ข้อมูลส่วนตัว
  //////////////////////////////////////////////////////
  Widget _personalTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field("ชื่อ - นามสกุล",
            "${user!['first_name']} ${user!['last_name']}"),
        _field("เบอร์โทรศัพท์", user!['phone'] ?? '-'),
        _field("วันเกิด", formatDate(user!['birth_date'])),
        _field("อายุ", calculateAge(user!['birth_date']).toString()),
        _field("ที่อยู่", fullAddress()),
        _field("อีเมล", user!['email'] ?? '-'),
      ],
    );
  }

  //////////////////////////////////////////////////////
  /// TAB 2 : ข้อมูลทางการแพทย์
  //////////////////////////////////////////////////////
  Widget _medicalTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field("โรคประจำตัว", user!['disease'] ?? '-'),
        _field("ประวัติการแพ้", user!['allergies'] ?? '-'),
        _field("ยาประจำตัว", user!['medicine'] ?? '-'),
      ],
    );
  }

  //////////////////////////////////////////////////////
  /// TAB 3 : สิทธิประโยชน์
  //////////////////////////////////////////////////////
  Widget _benefitTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field("สิทธิการรักษา", user!['treatment_right'] ?? '-'),
        _field("วงเงินต่อปี",
            user!['annual_budget']?.toString() ?? '-'),
      ],
    );
  }

  //////////////////////////////////////////////////////
  /// 🔹 กล่องแสดงข้อมูล
  //////////////////////////////////////////////////////
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
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
