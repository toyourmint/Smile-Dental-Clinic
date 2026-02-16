import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/appomitment/add_appointment.dart';
import 'package:flutter_application_1/screen/data/data_store.dart';


class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {

  // 1. Controller สำหรับ Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // 2. ตัวแปรสำหรับเก็บวันที่ที่เลือกจาก Filter
  DateTime? _selectedFilterDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- ฟังก์ชันเปิดปฏิทินเลือกวันที่ ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue, // สีหัวปฏิทิน
              onPrimary: Colors.white, 
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedFilterDate) {
      setState(() {
        _selectedFilterDate = picked;
      });
    }
  }

  void _openAddDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const AddAppointmentDialog(),
    );

    if (result != null) {
      setState(() {
        DataStore.allAppointments.add(AppointmentModel(
          id: result['id']!,
          name: result['name']!,
          date: result['date']!,
          time: result['time']!,
          treatment: result['treatment']!,
          doctor: result['doctor']!,
          phone: result['phone']!,
          status: result['status']!,
        ));
      });
    }
  }

  void _openEditDialog(int actualIndex) async {
    final currentItem = DataStore.allAppointments[actualIndex];
    if (currentItem.status == "Cancelled" || currentItem.status == "Done" || currentItem.status == "Skipped") return;

    final initialData = {
      "id": currentItem.id,
      "name": currentItem.name,
      "date": currentItem.date,
      "time": currentItem.time,
      "treatment": currentItem.treatment,
      "doctor": currentItem.doctor,
      "phone": currentItem.phone,
      "status": currentItem.status,
    };

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AddAppointmentDialog(initialData: initialData),
    );

    if (result != null) {
      setState(() {
        DataStore.allAppointments[actualIndex] = AppointmentModel(
          id: result['id']!,
          name: result['name']!,
          date: result['date']!,
          time: result['time']!,
          treatment: result['treatment']!,
          doctor: result['doctor']!,
          phone: result['phone']!,
          status: result['status']!,
          queueNumber: currentItem.queueNumber, 
          assignedRoom: currentItem.assignedRoom, 
        );
      });
    }
  }

  void _confirmCancel(int actualIndex) {
    final item = DataStore.allAppointments[actualIndex];
    if (item.status == "Cancelled" || item.status == "Skipped") return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text("ยืนยันการยกเลิก", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text("คุณต้องการยกเลิกนัดหมายของ \"${item.name}\" ใช่หรือไม่?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("ปิด", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  DataStore.allAppointments[actualIndex].status = "Cancelled";
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("ยืนยันการยกเลิก", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 3. กรองข้อมูล (Search Text + Filter Date)
    List<AppointmentModel> filteredAppointments = DataStore.allAppointments.where((item) {
      // --- ตรวจสอบเงื่อนไข Search ---
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final nameLower = item.name.toLowerCase();
        final idLower = item.id.toLowerCase();
        final phoneLower = item.phone.toLowerCase();
        final searchLower = _searchQuery.toLowerCase();
        matchesSearch = nameLower.contains(searchLower) || idLower.contains(searchLower) || phoneLower.contains(searchLower);
      }

      // --- ตรวจสอบเงื่อนไขวันที่ (Date Filter) ---
      bool matchesDate = true;
      if (_selectedFilterDate != null) {
        // แปลงวันที่ที่เลือกให้อยู่ในรูปแบบ dd/MM/yyyy เพื่อเทียบกับใน DataStore
        String day = _selectedFilterDate!.day.toString().padLeft(2, '0');
        String month = _selectedFilterDate!.month.toString().padLeft(2, '0');
        String year = _selectedFilterDate!.year.toString();
        String formattedFilterDate = "$day/$month/$year";
        
        matchesDate = (item.date == formattedFilterDate);
      }

      // ต้องผ่านทั้ง 2 เงื่อนไขถึงจะแสดง
      return matchesSearch && matchesDate;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            // --- Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("ข้อมูลการนัดหมายผู้ป่วย", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(height: 3, width: 100, color: const Color(0xFF2196F3)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _openAddDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("เพิ่มการนัดหมาย"),
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
            
            // --- Search & Filter Bar ---
            Row(
              children: [
                // 1. ช่อง Search
                Container(
                  width: 300,
                  height: 45,
                  decoration: BoxDecoration(color: const Color(0xFFEDF2F7), borderRadius: BorderRadius.circular(25)),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() { _searchQuery = value; });
                    },
                    decoration: InputDecoration(
                      hintText: 'ค้นหาชื่อ, รหัสผู้ป่วย, เบอร์โทร',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() { _searchQuery = ""; });
                            },
                          )
                        : null,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                
                // 2. ปุ่ม Filter Date
                OutlinedButton(
                  onPressed: () => _selectDate(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: _selectedFilterDate == null ? Colors.blue : Colors.blue.shade700, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), // ปรับขนาดปุ่มให้พอดี
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: _selectedFilterDate == null ? Colors.blue : Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        _selectedFilterDate == null 
                          ? "Filter by Date" 
                          : "${_selectedFilterDate!.day.toString().padLeft(2, '0')}/${_selectedFilterDate!.month.toString().padLeft(2, '0')}/${_selectedFilterDate!.year}",
                        style: TextStyle(
                          color: _selectedFilterDate == null ? Colors.grey.shade700 : Colors.blue.shade800, 
                          fontWeight: _selectedFilterDate == null ? FontWeight.normal : FontWeight.bold
                        ),
                      ),
                      // ถ้าเลือกวันที่แล้ว จะมีปุ่มกากบาทให้เคลียร์วันที่ทิ้ง
                      if (_selectedFilterDate != null) ...[
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () {
                            setState(() { _selectedFilterDate = null; });
                          },
                          child: const Icon(Icons.cancel, size: 18, color: Colors.redAccent),
                        )
                      ]
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- Table Header ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
              child: Row(
                children: const [
                  SizedBox(width: 60),
                  Expanded(flex: 2, child: Text("ชื่อผู้ป่วย", style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text("วันที่", style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text("เวลา", style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text("ประเภทการรักษา", style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text("แพทย์", style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text("เบอร์โทรศัพท์", style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text("สถานะ", style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),

            // --- Data List ---
            Expanded(
              child: filteredAppointments.isEmpty
                ? const Center(
                    child: Text(
                      "ไม่พบข้อมูลการนัดหมาย", 
                      style: TextStyle(color: Colors.grey, fontSize: 16)
                    )
                  )
                : ListView.separated(
                    itemCount: filteredAppointments.length, 
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                    itemBuilder: (context, index) {
                      final item = filteredAppointments[index]; 
                      
                      final actualIndex = DataStore.allAppointments.indexOf(item);
                      
                      Color statusColor;
                      String statusText;

                      switch (item.status) {
                        case "Confirmed":
                          statusColor = const Color(0xFF42A5F5); 
                          statusText = "Confirmed";
                          break;
                        case "Waiting": 
                        case "InQueue": 
                          statusColor = Colors.orangeAccent; 
                          statusText = "อยู่ในกระบวนการ"; 
                          break;
                        case "Done":
                          statusColor = Colors.green; 
                          statusText = "เสร็จสิ้น"; 
                          break;
                        case "Skipped": 
                        case "Cancelled":
                          statusColor = Colors.red;
                          statusText = "ยกเลิก"; 
                          break;
                        default:
                          statusColor = Colors.grey;
                          statusText = item.status;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                        color: Colors.white,
                        child: Row(
                          children: [
                            CircleAvatar(radius: 20, backgroundColor: Colors.blue.shade100, child: Text(item.name.isNotEmpty ? item.name[0] : "?")),
                            const SizedBox(width: 20),
                            Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)), const SizedBox(height: 2), Text(item.id, style: TextStyle(color: Colors.blue.shade700, fontSize: 11, fontWeight: FontWeight.bold))])),
                            Expanded(flex: 1, child: Text(item.date)),
                            Expanded(flex: 1, child: Text(item.time)),
                            Expanded(flex: 2, child: Text(item.treatment)),
                            Expanded(flex: 2, child: Text(item.doctor)),
                            Expanded(flex: 2, child: Text(item.phone)),
                            
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                                    child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 10),
                                  InkWell(
                                    onTap: () => _openEditDialog(actualIndex),
                                    child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(border: Border.all(color: Colors.black87), borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.edit, size: 16, color: Colors.black87)),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _confirmCancel(actualIndex),
                                    child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.close, size: 16, color: Colors.white)),
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