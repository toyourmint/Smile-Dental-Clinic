import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _generateNextPatientId() {
    DateTime now = DateTime.now();
    String yearStr = (now.year % 100).toString().padLeft(2, '0');
    String prefix = "SD-$yearStr";

    int maxRunning = 0;

    for (var p in DataStore.allPatients) {
      if (p.patientId.startsWith(prefix)) {
        String numStr = p.patientId.substring(prefix.length);
        int? num = int.tryParse(numStr);
        if (num != null && num > maxRunning) {
          maxRunning = num;
        }
      }
    }

    String nextNumberStr = (maxRunning + 1).toString().padLeft(4, '0');
    return "$prefix$nextNumberStr";
  }

  void _openAddPatientDialog() async {
    String nextId = _generateNextPatientId();

    final result = await showDialog<PatientInfo>(
      context: context,
      builder: (context) => AddPatientDialog(
        generatedId: nextId, 
      ),
    );

    if (result != null) {
      setState(() {
        DataStore.allPatients.add(result);
      });
    }
  }

  void _openViewEditDialog(int actualIndex) async {
    final result = await showDialog<PatientInfo>(
      context: context,
      builder: (context) => AddPatientDialog(
        existingPatient: DataStore.allPatients[actualIndex], 
      ),
    );

    if (result != null) {
      setState(() {
        DataStore.allPatients[actualIndex] = result; 
      });
    }
  }

  // --- 💡 ฟังก์ชันสำหรับลบข้อมูล ---
  void _confirmDelete(int actualIndex) {
    final patient = DataStore.allPatients[actualIndex];
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
          content: Text("คุณต้องการลบข้อมูลของ \"${patient.fullName}\" ออกจากระบบใช่หรือไม่?\n(การกระทำนี้ไม่สามารถย้อนกลับได้)"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("ยกเลิก", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  DataStore.allPatients.removeAt(actualIndex); // ลบออกจาก DataStore
                });
                Navigator.of(context).pop();
                
                // โชว์แจ้งเตือนว่าลบสำเร็จ
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ลบข้อมูลผู้ป่วยสำเร็จ'), backgroundColor: Colors.green),
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
    List<PatientInfo> filteredPatients = DataStore.allPatients.where((item) {
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
                    hintText: 'ค้นหาชื่อ, รหัสรหัสผู้ป่วย, เลขบัตรประจำตัวประชาชน, เบอร์', 
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
                Expanded(flex: 3, child: Text("ชื่อผู้ป่วย")), 
                Expanded(flex: 3, child: Text("เลขบัตรประจำตัวประชาชน")), 
                Expanded(flex: 1, child: Text("เพศ")), 
                Expanded(flex: 2, child: Text("เบอร์โทรศัพท์")), 
                Expanded(flex: 3, child: Text("อีเมล")), 
                SizedBox(width: 80) // 💡 เพิ่มพื้นที่ว่างให้ปุ่มลบ
              ]),
            ),

            Expanded(
              child: filteredPatients.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          Text(
                            DataStore.allPatients.isEmpty ? "ยังไม่มีข้อมูลผู้ป่วย" : "ไม่พบข้อมูลที่ค้นหา", 
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
                        final actualIndex = DataStore.allPatients.indexOf(item);

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20, backgroundColor: Colors.blue.shade100,
                                child: Text(item.firstName.isNotEmpty ? item.firstName[0] : "?", style: TextStyle(color: Colors.blue.shade900)),
                              ),
                              const SizedBox(width: 20),
                              
                              Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(item.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                Text(item.patientId, style: const TextStyle(fontSize: 11, color: Color(0xFF1976D2), fontWeight: FontWeight.w600)),
                              ])),
                              
                              Expanded(flex: 3, child: Text(item.idCard, style: const TextStyle(fontSize: 13, color: Colors.black54))),
                              Expanded(flex: 1, child: Text(item.gender, style: const TextStyle(fontSize: 13, color: Colors.black54))),
                              Expanded(flex: 2, child: Text(item.phone, style: const TextStyle(fontSize: 13, color: Colors.black54))),
                              Expanded(flex: 3, child: Text(item.email, style: const TextStyle(fontSize: 13, color: Colors.black54))),
                              
                              // 💡 เปลี่ยนตรงนี้เป็น 2 ปุ่ม (ปุ่มแก้ไข กับ ปุ่มลบ)
                              SizedBox(
                                width: 80, // เพิ่มความกว้างให้พอสำหรับ 2 ปุ่ม
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: () => _openViewEditDialog(actualIndex), 
                                      child: Container(
                                        width: 30, height: 30,
                                        decoration: BoxDecoration(color: const Color(0xFF64B5F6), borderRadius: BorderRadius.circular(6)),
                                        // เปลี่ยนไอคอนลูกศรเป็นปากกาให้เข้าใจง่ายขึ้น
                                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => _confirmDelete(actualIndex), // 💡 กดแล้วเรียกฟังก์ชันลบ
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