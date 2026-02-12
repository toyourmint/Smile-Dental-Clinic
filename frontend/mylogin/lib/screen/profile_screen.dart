import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ===============================
  // 🔹 Mock Data (แทน Database)
  // ===============================
  final Map<String, dynamic> user = {
    "first_name": "มนต์แคน",
    "last_name": "ร้องเพลง",
    "phone": "012-345-6789",
    "birth_date": "2000-12-25",

    // address
    "house_no": "10/2",
    "subdistrict": "บางระวัง",
    "district": "บางพลู",
    "province": "กรุงเทพมหานคร",
    "postcode": "10520",

    // medical
    "disease": "-",
    "allergy": "แพ้กุ้ง",
    "medicine": "-",

    // benefit
    "right": "สิทธิประกันสังคม",
    "limit": "900"
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // ===============================
  // 🔹 คำนวณอายุ
  // ===============================
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

  // ===============================
  // 🔹 format วันไทย
  // ===============================
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

  // ===============================
  // 🔹 รวมที่อยู่
  // ===============================
  String fullAddress() {
    return "${user['house_no']} "
        "${user['subdistrict']} "
        "${user['district']} "
        "${user['province']} "
        "${user['postcode']}";
  }

  // ===============================
  // 🔹 UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("ข้อมูลส่วนตัว"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // ===== รูปโปรไฟล์ =====
          const CircleAvatar(
            radius: 55,
            backgroundImage: NetworkImage(
                "https://i.pravatar.cc/300"), // ใส่รูปจริงทีหลังได้
          ),

          const SizedBox(height: 12),

          Text(
            "คุณ ${user['first_name']} ${user['last_name']}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),
          const Text("รหัสผู้ป่วย : HN260001"),

          const SizedBox(height: 16),

          // ===============================
          // 🔵 TabBar
          // ===============================
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

  ////////////////////////////////////////////////////////
  /// TAB 1 : ข้อมูลส่วนตัว
  ////////////////////////////////////////////////////////
  Widget _personalTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field("ชื่อ - นามสกุล",
            "${user['first_name']} ${user['last_name']}"),
        _field("เบอร์โทรศัพท์", user['phone']),
        _field("วัน/เดือน/ปี เกิด", formatDate(user['birth_date'])),
        _field("อายุ (ปี)", calculateAge(user['birth_date']).toString()),
        _field("ที่อยู่", fullAddress()),
      ],
    );
  }

  ////////////////////////////////////////////////////////
  /// TAB 2 : ข้อมูลทางการแพทย์
  ////////////////////////////////////////////////////////
  Widget _medicalTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field("โรคประจำตัว", user['disease']),
        _field("ประวัติการแพ้", user['allergy']),
        _field("ยาประจำตัว", user['medicine']),
      ],
    );
  }

  ////////////////////////////////////////////////////////
  /// TAB 3 : สิทธิประโยชน์
  ////////////////////////////////////////////////////////
  Widget _benefitTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field("สิทธิการรักษา", user['right']),
        _field("วงเงิน/ค่าใช้จ่าย", user['limit']),
      ],
    );
  }

  ////////////////////////////////////////////////////////
  /// กล่อง input style เหมือนรูป
  ////////////////////////////////////////////////////////
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
