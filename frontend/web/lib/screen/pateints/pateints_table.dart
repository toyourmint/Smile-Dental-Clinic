import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// 💡 อย่าลืมเช็ค path ของไฟล์ add_pateint.dart และ data_store.dart ให้ตรงกับโปรเจกต์ของคุณนะครับ
import 'package:flutter_application_1/screen/pateints/add_pateint.dart';
import 'package:flutter_application_1/screen/data/data_store.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  
  List<PatientInfo> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 💡 ฟังก์ชันดึงข้อมูลที่แก้ให้อ่าน { "profiles": [...] } แล้ว
  Future<void> _fetchPatients() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/user/getprofiles'));
      
      if (response.statusCode == 200) {
        // แปลงเป็น Map ก่อน เพราะ Backend ส่งมาเป็น { "profiles": [...] }
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // ดึงเอาลิสต์ข้อมูลออกจากคีย์ 'profiles'
        final List<dynamic> data = responseData['profiles'] ?? [];
        
        setState(() {
          _patients = data.map((json) {
            String genderTh = "ไม่ระบุ";
            if (json['gender'] == 'male') genderTh = "ชาย";
            if (json['gender'] == 'female') genderTh = "หญิง";
            if (json['gender'] == 'other') genderTh = "อื่นๆ";

            return PatientInfo(
              patientId: json['hn']?.toString() ?? "-",
              idCard: json['citizen_id']?.toString() ?? "-",
              prefix: json['title']?.toString() ?? "",
              firstName: json['first_name']?.toString() ?? "ไม่ระบุ",
              lastName: json['last_name']?.toString() ?? "",
              birthDate: json['birth_date']?.toString().split('T')[0] ?? "-", 
              gender: genderTh,
              phone: json['phone']?.toString() ?? "-",
              email: json['email']?.toString() ?? "-",
              disease: json['disease']?.toString() ?? "-",
              allergy: json['allergies']?.toString() ?? "-",
              medication: json['medicine']?.toString() ?? "-",
              history: "-",
              insuranceLimit: json['annual_budget']?.toString() ?? "-",
              address: json['address_line']?.toString() ?? "-",
              subDistrict: json['subdistrict']?.toString() ?? "-",
              district: json['district']?.toString() ?? "-",
              province: json['province']?.toString() ?? "-",
              zipCode: json['postal_code']?.toString() ?? "-",
              right: json['treatment_right']?.toString() ?? "-",
            );
          }).toList();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ดึงข้อมูลล้มเหลว (Status: ${response.statusCode})'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print("Fetch Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ดึงข้อมูลไม่ได้: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openAddPatientDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => AddPatientDialog(
        generatedId: null, 
        onPatientAdded: () {
          _fetchPatients(); 
        },
      ),
    );

    if (result == "success" || result == true) {
      _fetchPatients();
    }
  }

  void _openViewEditDialog(PatientInfo patient) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AddPatientDialog(
        existingPatient: patient, 
        onPatientAdded: () {
          _fetchPatients();
        },
      ),
    );

    if (result == "success" || result == true) {
      _fetchPatients(); 
    }
  }

  void _confirmDelete(PatientInfo patient) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text("ยืนยันการลบข้อมูล", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text("คุณต้องการลบข้อมูลของ \"${patient.fullName}\" ใช่หรือไม่?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("ยกเลิก", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ระบบลบข้อมูลกำลังอยู่ในช่วงพัฒนา'), backgroundColor: Colors.orange),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("ลบข้อมูล", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<PatientInfo> filteredPatients = _patients.where((item) {
      if (_searchQuery.isEmpty) return true;
      
      final searchLower = _searchQuery.toLowerCase();
      return item.fullName.toLowerCase().contains(searchLower) ||
             item.patientId.toLowerCase().contains(searchLower) ||
             item.idCard.contains(searchLower) ||
             item.phone.contains(searchLower);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("ข้อมูลผู้ป่วย", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(height: 3, width: 80, color: const Color(0xFF2196F3)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _openAddPatientDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("เพิ่มข้อมูลผู้ป่วย"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 300, height: 40,
                decoration: BoxDecoration(color: const Color(0xFFEDF2F7), borderRadius: BorderRadius.circular(20)),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() { _searchQuery = value; });
                  },
                  decoration: InputDecoration(
                    hintText: 'ค้นหาชื่อ, รหัสผู้ป่วย, เบอร์...', 
                    prefixIcon: const Icon(Icons.search, color: Colors.grey), 
                    border: InputBorder.none, 
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() { _searchQuery = ""; });
                          },
                        )
                      : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
              child: Row(children: const [
                SizedBox(width: 60), 
                Expanded(flex: 3, child: Text("ชื่อผู้ป่วย", style: TextStyle(fontWeight: FontWeight.bold))), 
                Expanded(flex: 3, child: Text("เลขบัตรประชาชน", style: TextStyle(fontWeight: FontWeight.bold))), 
                Expanded(flex: 1, child: Text("เพศ", style: TextStyle(fontWeight: FontWeight.bold))), 
                Expanded(flex: 2, child: Text("เบอร์โทรศัพท์", style: TextStyle(fontWeight: FontWeight.bold))), 
                Expanded(flex: 3, child: Text("อีเมล", style: TextStyle(fontWeight: FontWeight.bold))), 
                SizedBox(width: 80) 
              ]),
            ),

            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator()) 
                : filteredPatients.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          Text(
                            _patients.isEmpty ? "ยังไม่มีข้อมูลผู้ป่วยในระบบ" : "ไม่พบข้อมูลที่ค้นหา", 
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 16)
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredPatients.length,
                      separatorBuilder: (c, i) => const Divider(height: 1, color: Colors.black12),
                      itemBuilder: (context, index) {
                        final item = filteredPatients[index];

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20, backgroundColor: Colors.blue.shade50,
                                child: Text(item.firstName.isNotEmpty ? item.firstName[0] : "?", style: TextStyle(color: Colors.blue.shade900)),
                              ),
                              const SizedBox(width: 20),
                              
                              Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(item.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(item.patientId, style: const TextStyle(fontSize: 11, color: Color(0xFF1976D2), fontWeight: FontWeight.w600)),
                              ])),
                              
                              Expanded(flex: 3, child: Text(item.idCard, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                              Expanded(flex: 1, child: Text(item.gender, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                              Expanded(flex: 2, child: Text(item.phone, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                              Expanded(flex: 3, child: Text(item.email, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                              
                              SizedBox(
                                width: 80, 
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: () => _openViewEditDialog(item), 
                                      child: Container(
                                        width: 30, height: 30,
                                        decoration: BoxDecoration(color: const Color(0xFF64B5F6), borderRadius: BorderRadius.circular(6)),
                                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => _confirmDelete(item), 
                                      child: Container(
                                        width: 30, height: 30,
                                        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(6)),
                                        child: const Icon(Icons.delete, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}