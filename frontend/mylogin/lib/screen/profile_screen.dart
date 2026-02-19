import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; 
// 🌟 สำคัญ: อย่าลืม Import หน้า Login ของคุณเข้ามา
import 'package:mylogin/screen/login_screen.dart'; 

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
  /// 🔹 API
  //////////////////////////////////////////////////////
  Future<void> fetchUser() async {
    final url = Uri.parse("http://10.0.2.2:3000/api/user/getprofiles");

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? myToken = prefs.getString('my_token');

      if (myToken == null || myToken.isEmpty) {
        setState(() {
          errorMessage = "เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่";
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $myToken', 
        },
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final data = json.decode(decoded);

        setState(() {
          user = data;
          isLoading = false;
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        setState(() {
          errorMessage = "ไม่มีสิทธิ์เข้าถึง (Token อาจหมดอายุ)";
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "โหลดข้อมูลไม่สำเร็จ (${response.statusCode})";
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
  /// 🌟 ระบบ Logout (ลงชื่อออก)
  //////////////////////////////////////////////////////
  Future<void> _logout() async {
    // 1. ล้างข้อมูลทั้งหมดในเครื่อง (Token, HN ฯลฯ)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 

    if (mounted) {
      // 2. เด้งกลับไปหน้า Login และล้างประวัติหน้าจอ (ป้องกันการกดย้อนกลับ)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()), 
        (route) => false,
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("ลงชื่อออก", style: thaiText(weight: FontWeight.bold)),
        content: Text("คุณต้องการออกจากระบบใช่หรือไม่?", style: thaiText()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ยกเลิก", style: thaiText()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ปิด Dialog
              _logout(); // เรียกฟังก์ชัน Logout
            },
            child: Text("ยืนยัน", style: thaiText(weight: FontWeight.bold).copyWith(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  //////////////////////////////////////////////////////
  /// 🔹 อายุ และ วันที่
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

  String formatDate(String birth) {
    DateTime d = DateTime.parse(birth);
    return "${d.day} ${_monthThai(d.month)} ${d.year + 543}";
  }

  String _monthThai(int m) {
    const months = [
      "",
      "ม.ค.","ก.พ.","มี.ค.","เม.ย.","พ.ค.","มิ.ย.",
      "ก.ค.","ส.ค.","ก.ย.","ต.ค.","พ.ย.","ธ.ค."
    ];
    return months[m];
  }

  String fullAddress() {
    return [
      user?['address_line'],
      user?['subdistrict'],
      user?['district'],
      user?['province'],
      user?['postal_code']
    ].where((e) => e != null && e.toString().isNotEmpty).join(" ");
  }

  TextStyle thaiText({double size = 16, FontWeight weight = FontWeight.normal}) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      fontFamilyFallback: const [
        'Noto Sans Thai',
        'Sarabun',
        'Tahoma',
        'Arial',
      ],
    );
  }

  //////////////////////////////////////////////////////
  /// UI
  //////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ข้อมูลส่วนตัว"),
        // 🌟 จุดที่ 1: ไอคอน Logout มุมขวาบน
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _showLogoutDialog,
          ),
        ],
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
                      style: thaiText(size: 18, weight: FontWeight.bold),
                    ),

                    const SizedBox(height: 6),
                    Text(
                      "HN : ${user!['hn'] ?? '-'}",
                      style: thaiText(),
                    ),

                    const SizedBox(height: 16),

                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.center,
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
  /// TAB 1
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

        const SizedBox(height: 30),

        // 🌟 จุดที่ 2: ปุ่ม Logout ขนาดใหญ่ด้านล่างข้อมูลส่วนตัว
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout),
            label: Text("ลงชื่อออกจากระบบ", style: thaiText(weight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.redAccent),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  //////////////////////////////////////////////////////
  /// TAB 2
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
  /// TAB 3
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
/// กล่องข้อมูล
//////////////////////////////////////////////////////
Widget _field(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: thaiText(size: 13, weight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue),
          ),
          child: Text(value, style: thaiText()),
        ),
      ],
    ),
  );
} 
}
