import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/data/table_styles.dart'; // ← เพิ่ม import

class DailyPatientTable extends StatefulWidget {
  final List<dynamic> patients;
  final Function(int) onAddToQueue;

  const DailyPatientTable({
    super.key,
    required this.patients,
    required this.onAddToQueue,
  });

  @override
  State<DailyPatientTable> createState() => _DailyPatientTableState();
}

class _DailyPatientTableState extends State<DailyPatientTable> {
  String _selectedFilter = "ทั้งหมด";

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredPatients = widget.patients.where((p) {
      String status = p['current_status'] ?? "Confirmed";

      if (_selectedFilter == "ทั้งหมด") return true;
      if (_selectedFilter == "ยังไม่มา" && status == "Confirmed") return true;
      if (_selectedFilter == "รอเรียกคิว" && status == "Waiting") return true;
      if (_selectedFilter == "กำลังตรวจ" && status == "InQueue") return true;
      if (_selectedFilter == "เสร็จสิ้น" && status == "Done") return true;
      if (_selectedFilter == "ข้าม" &&
          (status == "Skipped" || status == "Cancelled"))
        return true;

      return false;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // --- Header ---
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ข้อมูลผู้ป่วยประจำวันนี้",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(height: 3, width: 40, color: const Color(0xFF2196F3)),
                ],
              ),
              const Spacer(),

              // --- Filter Dropdown ---
              PopupMenuButton<String>(
                onSelected: (String value) {
                  setState(() { _selectedFilter = value; });
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                offset: const Offset(0, 50),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(value: "ทั้งหมด", child: Text('ทั้งหมด')),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(value: "ยังไม่มา", child: Text('ยังไม่มา (Confirmed)')),
                  const PopupMenuItem<String>(value: "รอเรียกคิว", child: Text('รอเรียกคิว (Waiting)')),
                  const PopupMenuItem<String>(value: "กำลังตรวจ", child: Text('กำลังตรวจ (In Queue)')),
                  const PopupMenuItem<String>(value: "เสร็จสิ้น", child: Text('เสร็จสิ้น (Done)')),
                  const PopupMenuItem<String>(value: "ข้าม", child: Text('ข้าม / ยกเลิก')),
                ],
                child: Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: _selectedFilter == "ทั้งหมด" ? Colors.blue : Colors.blue.shade700,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_alt_outlined, size: 16,
                          color: _selectedFilter == "ทั้งหมด" ? Colors.blue : Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        "สถานะ: $_selectedFilter",
                        style: TextStyle(
                          color: _selectedFilter == "ทั้งหมด" ? Colors.grey.shade700 : Colors.blue.shade800,
                          fontWeight: _selectedFilter == "ทั้งหมด" ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade500),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // --- หัวตาราง ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 50),
                Expanded(flex: 3, child: Text("ชื่อผู้ป่วย",          style: TableStyles.columnHeader)),
                Expanded(flex: 1, child: Text("เวลา",                 style: TableStyles.columnHeader, textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text("ประเภทการรักษา",        style: TableStyles.columnHeader, textAlign: TextAlign.center)),
                Expanded(flex: 3, child: Text("แพทย์",                style: TableStyles.columnHeader, textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text("เบอร์โทรศัพท์",        style: TableStyles.columnHeader, textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text("สถานะ",                style: TableStyles.columnHeader, textAlign: TextAlign.center)),
              ],
            ),
          ),
          const Divider(),

          // --- รายการข้อมูล ──────────────────────────────────────
          Expanded(
            child: filteredPatients.isEmpty
                ? Center(
                    child: Text(
                      "ไม่มีผู้ป่วยในสถานะ '$_selectedFilter'",
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredPatients.length,
                    separatorBuilder: (c, i) => const Divider(height: 1, color: Colors.transparent),
                    itemBuilder: (context, index) {
                      final p = filteredPatients[index];
                      final actualIndex = widget.patients.indexOf(p);

                      String name = "${p['first_name'] ?? ''} ${p['last_name'] ?? ''}".trim();
                      String timeStr = p['appointment_time']?.toString() ?? "-";
                      if (timeStr.length >= 5) {
                        timeStr = "${timeStr.substring(0, 2)}.${timeStr.substring(3, 5)} น.";
                      }

                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: TableStyles.avatarRadius,
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                name.isNotEmpty ? name[0] : "?",
                                style: TextStyle(color: Colors.blue.shade900),
                              ),
                            ),
                            const SizedBox(width: 14),

                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(name, style: TableStyles.patientName,
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(p['hn'] ?? "-", style: TableStyles.patientHn),
                                ],
                              ),
                            ),

                            Expanded(flex: 1, child: Text(timeStr,
                                style: TableStyles.cellBody, textAlign: TextAlign.center)),

                            Expanded(flex: 2, child: Text(p['treatment'] ?? "-",
                                style: TableStyles.cellMuted, textAlign: TextAlign.center,
                                maxLines: 1, overflow: TextOverflow.ellipsis)),

                            Expanded(flex: 3, child: Text(p['doctor_name'] ?? "-",
                                style: TableStyles.cellMuted, textAlign: TextAlign.center,
                                maxLines: 1, overflow: TextOverflow.ellipsis)),

                            Expanded(flex: 2, child: Text(p['phone'] ?? "-",
                                style: TableStyles.cellBody, textAlign: TextAlign.center)),

                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.center,
                                child: _buildStatusButton(
                                  status: p['current_status'] ?? "Confirmed",
                                  onTap: () => widget.onAddToQueue(actualIndex),
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

  Widget _buildStatusButton({required String status, required VoidCallback onTap}) {
    Color bgColor = Colors.grey;
    String label = status;
    bool isClickable = false;

    if (status == "Confirmed") {
      bgColor = const Color(0xFF42A5F5); label = "รับคิว"; isClickable = true;
    } else if (status == "Waiting") {
      bgColor = Colors.orangeAccent; label = "รอเรียกคิว";
    } else if (status == "InQueue") {
      bgColor = Colors.blue.shade700; label = "กำลังตรวจ";
    } else if (status == "Done") {
      bgColor = Colors.green; label = "เสร็จสิ้น";
    } else if (status == "Skipped") {
      bgColor = const Color(0xFFFFB74D); label = "ข้าม";
    } else if (status == "Cancelled") {
      bgColor = Colors.red; label = "ยกเลิก";
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
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );

    if (isClickable) {
      return Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: badgeContent),
      );
    }
    return badgeContent;
  }
}