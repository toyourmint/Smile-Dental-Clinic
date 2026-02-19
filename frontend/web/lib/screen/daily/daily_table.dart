import 'package:flutter/material.dart';

class DailyPatientTable extends StatefulWidget {
  final List<dynamic> patients;
  final Function(int) onAddToQueue;

  const DailyPatientTable({
    super.key, 
    required this.patients, 
    required this.onAddToQueue
  });

  @override
  State<DailyPatientTable> createState() => _DailyPatientTableState();
}

class _DailyPatientTableState extends State<DailyPatientTable> {
  // ตัวแปรเก็บสถานะที่กำลังเลือกอยู่ (ค่าเริ่มต้นคือดูทั้งหมด)
  String _selectedFilter = "ทั้งหมด"; 

  @override
  Widget build(BuildContext context) {
    
    // --- 1. กรองข้อมูล (Filter Logic) ตามสถานะที่เลือก ---
    List<dynamic> filteredPatients = widget.patients.where((p) {
      String status = p['current_status'] ?? "Confirmed";
      
      if (_selectedFilter == "ทั้งหมด") return true;
      if (_selectedFilter == "ยังไม่มา" && status == "Confirmed") return true;
      if (_selectedFilter == "รอเรียกคิว" && status == "Waiting") return true;
      if (_selectedFilter == "กำลังตรวจ" && status == "InQueue") return true;
      if (_selectedFilter == "เสร็จสิ้น" && status == "Done") return true;
      if (_selectedFilter == "ข้าม" && (status == "Skipped" || status == "Cancelled")) return true;
      
      return false; // นอกเหนือจากนี้ไม่แสดง
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // --- ส่วนหัว (Header) ---
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ข้อมูลผู้ป่วยประจำวัน", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 4),
                  Container(height: 3, width: 40, color: const Color(0xFF0062E0)),
                ],
              ),
              const Spacer(),
              
              // --- 2. ปุ่ม Filter (แบบ Dropdown Menu) ---
              Material(
                color: Colors.white, 
                elevation: 2, 
                borderRadius: BorderRadius.circular(20),
                child: PopupMenuButton<String>(
                  onSelected: (String value) {
                    setState(() {
                      _selectedFilter = value; // อัปเดตสถานะที่เลือก
                    });
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  offset: const Offset(0, 45), // เด้งเมนูลงมาด้านล่าง
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(value: "ทั้งหมด", child: Text("ทั้งหมด")),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(value: "ยังไม่มา", child: Text("ยังไม่มา (Confirmed)")),
                    const PopupMenuItem<String>(value: "รอเรียกคิว", child: Text("รอเรียกคิว (Waiting)")),
                    const PopupMenuItem<String>(value: "กำลังตรวจ", child: Text("กำลังตรวจ (In Queue)")),
                    const PopupMenuItem<String>(value: "เสร็จสิ้น", child: Text("เสร็จสิ้น (Done)")),
                    const PopupMenuItem<String>(value: "ข้าม", child: Text("ข้าม / ยกเลิก")),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, size: 16, color: Colors.blue), 
                        const SizedBox(width: 8), 
                        Text("สถานะ: $_selectedFilter", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                        const SizedBox(width: 4), 
                        const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // --- หัวตาราง (Table Column Headers) ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: const [
                SizedBox(width: 50), // เว้นที่ Avatar
                Expanded(flex: 2, child: Text("ชื่อผู้ป่วย", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text("เวลา", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("ประเภทการรักษา", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("แพทย์", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("เบอร์โทรศัพท์", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("สถานะ", style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const Divider(),

          // --- 3. รายการข้อมูล (ใช้ List ที่กรองแล้ว) ---
          Expanded(
            child: filteredPatients.isEmpty
              ? Center(
                  child: Text(
                    "ไม่มีผู้ป่วยในสถานะ '$_selectedFilter'", 
                    style: const TextStyle(color: Colors.grey, fontSize: 16)
                  )
                )
              : ListView.separated(
                  itemCount: filteredPatients.length,
                  separatorBuilder: (c, i) => const Divider(height: 1, color: Colors.transparent),
                  itemBuilder: (context, index) {
                    final p = filteredPatients[index];
                    
                    // หา Index ที่แท้จริงใน List หลัก เพื่อให้ตอนกดรับคิวตรงกับข้อมูลจริง
                    final actualIndex = widget.patients.indexOf(p);
                    
                    // จัดการการแสดงผลชื่อและเวลา
                    String name = "${p['first_name'] ?? ''} ${p['last_name'] ?? ''}".trim();
                    String timeStr = p['appointment_time']?.toString() ?? "-";
                    // เปลี่ยนจาก "09:00:00" เป็น "09.00 น."
                    if (timeStr.length >= 5) {
                      timeStr = "${timeStr.substring(0, 2)}.${timeStr.substring(3, 5)} น.";
                    }

                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        border: Border(bottom: BorderSide(color: Colors.grey.shade100))
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18, 
                            backgroundColor: Colors.blue.shade100, 
                            child: Text(name.isNotEmpty ? name[0] : "?", style: TextStyle(color: Colors.blue.shade900))
                          ),
                          const SizedBox(width: 14),
                          
                          Expanded(
                            flex: 2, 
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                // 💡 เปลี่ยนจาก Apt. เป็นรหัสผู้ป่วย (HN)
                                Text(
                                  p['hn'] ?? "-", 
                                  style: const TextStyle(
                                    fontSize: 11, 
                                    color: Color(0xFF1976D2), 
                                    fontWeight: FontWeight.w600
                                  )
                                ),
                              ],
                            ),
                          ),
                          
                          Expanded(flex: 1, child: Text(timeStr, style: const TextStyle(color: Colors.black87))),
                          Expanded(flex: 2, child: Text(p['treatment'] ?? "-", style: const TextStyle(color: Colors.black54))),
                          Expanded(flex: 2, child: Text(p['doctor_name'] ?? "-", style: const TextStyle(color: Colors.black54))),
                          Expanded(flex: 2, child: Text(p['phone'] ?? "-", style: const TextStyle(color: Colors.black54))),
                          
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _buildStatusButton(
                                status: p['current_status'] ?? "Confirmed", 
                                // ส่ง actualIndex กลับไปหาหน้าหลักเมื่อกดปุ่ม
                                onTap: () => widget.onAddToQueue(actualIndex) 
                              ),
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
    );
  }

  // Widget สร้างปุ่มสถานะ
  Widget _buildStatusButton({required String status, required VoidCallback onTap}) {
    Color bgColor = Colors.grey;
    String label = status;
    bool isClickable = false;

    if (status == "Confirmed") {
      bgColor = const Color(0xFF42A5F5); 
      label = "รับคิว"; 
      isClickable = true; // ให้ปุ่มนี้กดได้เท่านั้น
    } else if (status == "Waiting") {
      bgColor = Colors.orangeAccent; 
      label = "รอเรียกคิว";
    } else if (status == "InQueue") {
      bgColor = Colors.blue.shade700; 
      label = "กำลังตรวจ";
    } else if (status == "Done") {
      bgColor = Colors.green; 
      label = "เสร็จสิ้น";
    } else if (status == "Skipped") {
      bgColor = const Color(0xFFFFB74D); // สีส้มอ่อน (Pastel Orange)
      label = "ข้าม"; 
    } else if (status == "Cancelled") {
      bgColor = Colors.red;
      label = "ยกเลิก";
    }

    Widget badgeContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: isClickable 
          ? [BoxShadow(color: bgColor.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))] 
          : null,
      ),
      child: Text(
        label, 
        style: const TextStyle(
          color: Colors.white, 
          fontSize: 12, 
          fontWeight: FontWeight.bold
        )
      ),
    );

    // ถ้ากดได้ให้ใส่ InkWell ครอบ
    if (isClickable) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: badgeContent,
        ),
      );
    } 
    
    return badgeContent;
  }
}