import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:flutter_application_1/screen/appomitment/edit_appointment.dart'; 
import 'package:flutter_application_1/screen/appomitment/add_appointment.dart'; 

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  DateTime? _selectedFilterDate;
  
  String _selectedStatusFilter = 'ทั้งหมด';

  List<dynamic> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? myToken = prefs.getString('my_token');

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/apm/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${myToken ?? ""}', 
        }
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _appointments = data['appointments'] ?? [];
          });
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("ไม่มีสิทธิ์เข้าถึง หรือเซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่"), backgroundColor: Colors.orange)
           );
         }
      } else {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("ดึงข้อมูลล้มเหลว (${response.statusCode})"), backgroundColor: Colors.red)
           );
         }
      }
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้"), backgroundColor: Colors.red)
         );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
              primary: Colors.blue, 
              onPrimary: Colors.white, 
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedFilterDate) {
      setState(() => _selectedFilterDate = picked);
    }
  }

  void _openAddDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const AddAppointmentDialog(),
    );
    if (result == "success") _fetchAppointments();
  }

  void _openEditDialog(Map<String, dynamic> item) async {
    final result = await showDialog(
      context: context,
      builder: (context) => EditAppointmentDialog(initialData: item),
    );
    if (result == "success") _fetchAppointments();
  }

  void _confirmCancel(dynamic item) {
    if (item['status'] == 'cancelled' || item['status'] == 'completed') return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text("ยืนยันการยกเลิก", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          content: Text("คุณต้องการยกเลิกนัดหมายรหัส ${item['hn']} ใช่หรือไม่?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("ปิด", style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  String? myToken = prefs.getString('my_token');

                  final response = await http.put(
                    Uri.parse('http://localhost:3000/api/apm/cancel/${item['apt_id']}'),
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer ${myToken ?? ""}', 
                    }
                  );
                  
                  if (response.statusCode == 200) {
                    _fetchAppointments(); 
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ยกเลิกสำเร็จ"), backgroundColor: Colors.green));
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ยกเลิกไม่สำเร็จ"), backgroundColor: Colors.red));
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("เกิดข้อผิดพลาดในการเชื่อมต่อ"), backgroundColor: Colors.red));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("ยืนยันการยกเลิก", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // 💡 แก้ไขฟังก์ชันนี้ให้แปลงเป็น พ.ศ. (+543)
  String _formatDate(String isoString) {
    try {
      DateTime dt = DateTime.parse(isoString);
      int thaiYear = dt.year + 543; // บวก 543 เป็น พ.ศ.
      return "${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/$thaiYear";
    } catch(e) { 
      return isoString; 
    }
  }

  String _formatTime(String time) {
    if(time.startsWith('09')) return '9.00 น.';
    return '${time.substring(0,2)}.00 น.';
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    List<dynamic> filteredAppointments = _appointments.where((item) {
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        String hn = (item['hn'] ?? "").toLowerCase();
        String name = "${item['title'] ?? ''} ${item['first_name']} ${item['last_name']}".toLowerCase();
        String phone = (item['phone'] ?? "").toLowerCase();
        String searchLower = _searchQuery.toLowerCase();
        matchesSearch = hn.contains(searchLower) || name.contains(searchLower) || phone.contains(searchLower);
      }
      
      bool matchesDate = true;
      String dateStr = (item['appointment_date'] ?? "").split('T')[0];
      DateTime? itemDate;
      try {
        itemDate = DateTime.parse(dateStr);
        itemDate = DateTime(itemDate.year, itemDate.month, itemDate.day);
      } catch (e) {
        itemDate = null;
      }

      if (_selectedFilterDate != null) {
        if (itemDate != null) {
           matchesDate = itemDate.isAtSameMomentAs(
             DateTime(_selectedFilterDate!.year, _selectedFilterDate!.month, _selectedFilterDate!.day)
           );
        } else {
           matchesDate = false;
        }
      } else {
        if (itemDate != null) {
           if (itemDate.isBefore(today)) {
             matchesDate = false; 
           }
        }
      }

      bool matchesStatus = true;
      String rawStatus = item['status'] ?? "booking";
      if (_selectedStatusFilter == 'จองแล้ว') {
        matchesStatus = rawStatus == 'booking';
      } else if (_selectedStatusFilter == 'รับคิวแล้ว') {
        matchesStatus = rawStatus == 'arrived';
      } else if (_selectedStatusFilter == 'เสร็จสิ้น') {
        matchesStatus = rawStatus == 'completed';
      } else if (_selectedStatusFilter == 'ยกเลิก') {
        matchesStatus = rawStatus == 'cancelled';
      }
      
      return matchesSearch && matchesDate && matchesStatus;
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
            
            // --- Search & Filter ---
            Row(
              children: [
                Container(
                  width: 300, height: 45,
                  decoration: BoxDecoration(color: const Color(0xFFEDF2F7), borderRadius: BorderRadius.circular(25)),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
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
                              setState(() => _searchQuery = ""); 
                            }
                          ) 
                        : null,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                
                // 💡 ปุ่ม Filter เปลี่ยนปีเป็น พ.ศ. โดย +543
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: _selectedFilterDate == null ? Colors.blue : Colors.blue.shade700, 
                        width: 1.5
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 16, color: _selectedFilterDate == null ? Colors.blue : Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          _selectedFilterDate == null 
                            ? "Filter by Date" 
                            : "${_selectedFilterDate!.day.toString().padLeft(2, '0')}/${_selectedFilterDate!.month.toString().padLeft(2, '0')}/${_selectedFilterDate!.year + 543}", // +543 ตรงนี้
                          style: TextStyle(
                            color: _selectedFilterDate == null ? Colors.grey.shade700 : Colors.blue.shade800,
                            fontWeight: _selectedFilterDate == null ? FontWeight.normal : FontWeight.bold
                          )
                        ),
                      ],
                    ),
                  ),
                ),
                if (_selectedFilterDate != null) ...[
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => setState(() => _selectedFilterDate = null),
                    child: const Icon(Icons.cancel, size: 18, color: Colors.redAccent)
                  )
                ],

                const SizedBox(width: 20),

                PopupMenuButton<String>(
                  onSelected: (String value) {
                    setState(() {
                      _selectedStatusFilter = value;
                    });
                  },
                  offset: const Offset(0, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(value: 'ทั้งหมด', child: Text('สถานะ: ทั้งหมด')),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(value: 'จองแล้ว', child: Text('🔵 จองแล้ว (Booking)')),
                    const PopupMenuItem<String>(value: 'รับคิวแล้ว', child: Text('🟠 รับคิวแล้ว (Arrived)')),
                    const PopupMenuItem<String>(value: 'เสร็จสิ้น', child: Text('🟢 เสร็จสิ้น (Completed)')),
                    const PopupMenuItem<String>(value: 'ยกเลิก', child: Text('🔴 ยกเลิก (Cancelled)')),
                  ],
                  child: Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: _selectedStatusFilter == 'ทั้งหมด' ? Colors.blue : Colors.blue.shade700, 
                        width: 1.5
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_alt_outlined, size: 16, color: _selectedStatusFilter == 'ทั้งหมด' ? Colors.blue : Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          "สถานะ: $_selectedStatusFilter",
                          style: TextStyle(
                            color: _selectedStatusFilter == 'ทั้งหมด' ? Colors.grey.shade700 : Colors.blue.shade800,
                            fontWeight: _selectedStatusFilter == 'ทั้งหมด' ? FontWeight.normal : FontWeight.bold
                          )
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade500),
                      ],
                    ),
                  ),
                ),

              ],
            ),
            const SizedBox(height: 30),

            // --- Table Header ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), 
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
              child: Row(children: const [
                SizedBox(width: 60),
                Expanded(flex: 3, child: Text("ชื่อผู้ป่วย", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text("วันที่", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text("เวลา", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text("ประเภทการรักษา", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("แพทย์", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("เบอร์โทรศัพท์", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("สถานะ / จัดการ", style: TextStyle(fontWeight: FontWeight.bold))),
              ]),
            ),

            // --- Table Body ---
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : filteredAppointments.isEmpty 
                  ? const Center(child: Text("ไม่พบข้อมูลการนัดหมาย", style: TextStyle(color: Colors.grey, fontSize: 16)))
                  : ListView.separated(
                      itemCount: filteredAppointments.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                      itemBuilder: (context, index) {
                        final item = filteredAppointments[index];
                        
                        String rawStatus = item['status'] ?? "booking";
                        Color statusColor;
                        String statusText;

                        if (rawStatus == 'cancelled') {
                          statusColor = Colors.red;
                          statusText = "ยกเลิก";
                        } else if (rawStatus == 'completed') {
                          statusColor = Colors.green; 
                          statusText = "เสร็จสิ้น"; 
                        } else if (rawStatus == 'arrived') {
                          statusColor = Colors.orange;
                          statusText = "รับคิวแล้ว";
                        } else {
                          statusColor = const Color(0xFF42A5F5); 
                          statusText = (rawStatus == 'booking') ? "จองแล้ว" : rawStatus;
                        }
                        
                        String titleStr = item['title'] != null && item['title'] != 'null' ? item['title'] : "";
                        String fullName = "$titleStr${titleStr.isNotEmpty ? ' ' : ''}${item['first_name']} ${item['last_name']}".trim();
                        String hn = item['hn'] ?? "-";
                        String initialChar = (item['first_name'] != null && item['first_name'].isNotEmpty) ? item['first_name'][0] : "?";
                        String doctor = item['doctor_name'] ?? "-"; 
                        String phone = item['phone'] ?? "-";

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                          color: Colors.white,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20, 
                                backgroundColor: Colors.blue.shade100, 
                                child: Text(initialChar, style: TextStyle(color: Colors.blue.shade900))
                              ),
                              const SizedBox(width: 20),
                              
                              Expanded(
                                flex: 3, 
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start, 
                                  children: [
                                    Text(fullName, style: const TextStyle(fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text(hn, style: TextStyle(color: Colors.blue.shade700, fontSize: 11, fontWeight: FontWeight.bold))
                                  ]
                                )
                              ),
                              
                              Expanded(flex: 1, child: Text(_formatDate(item['appointment_date']))), // 💡 แสดงเป็น พ.ศ.
                              Expanded(flex: 1, child: Text(_formatTime(item['appointment_time']))),
                              Expanded(flex: 3, child: Text(item['reason'] ?? "-", style: const TextStyle(color: Colors.black87))),
                              Expanded(flex: 2, child: Text(doctor, style: const TextStyle(color: Colors.black54))),
                              Expanded(flex: 2, child: Text(phone, style: const TextStyle(color: Colors.black87))),
                              
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
                                    
                                    if (rawStatus != 'cancelled' && rawStatus != 'completed' && rawStatus != 'arrived') ...[
                                      InkWell(
                                        onTap: () => _openEditDialog(item),
                                        child: Container(
                                          padding: const EdgeInsets.all(4), 
                                          decoration: BoxDecoration(border: Border.all(color: Colors.black87), borderRadius: BorderRadius.circular(4)), 
                                          child: const Icon(Icons.edit, size: 16, color: Colors.black87)
                                        )
                                      ),
                                      const SizedBox(width: 8),
                                    ],

                                    if (rawStatus != 'cancelled' && rawStatus != 'completed') ...[
                                      InkWell(
                                        onTap: () => _confirmCancel(item),
                                        child: Container(
                                          padding: const EdgeInsets.all(4), 
                                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)), 
                                          child: const Icon(Icons.close, size: 16, color: Colors.white)
                                        ),
                                      )
                                    ]
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    )
            )
          ]
        )
      )
    );
  }
}