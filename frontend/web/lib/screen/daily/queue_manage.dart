import 'package:flutter/material.dart';

class QueueManagerSection extends StatelessWidget {
  final String queueNumber;
  final String roomNumber;
  final String currentPatientName;
  final String doctorName; // 💡 1. เพิ่มตัวรับค่าชื่อแพทย์
  final List<Map<String, String>> nextQueues;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;

  const QueueManagerSection({
    super.key,
    required this.queueNumber,
    required this.roomNumber,
    required this.currentPatientName,
    required this.doctorName, // 💡 2. รับค่าเข้ามาใน Constructor
    required this.nextQueues,
    this.onNext,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 20)],
              ),
              child: Column(
                children: [
                  // --- Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ฝั่งซ้าย: สถานะคิว
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("สถานะคิวปัจจุบัน", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              queueNumber, 
                              style: TextStyle(
                                fontSize: queueNumber == "-" ? 40 : 40, 
                                fontWeight: FontWeight.w900, 
                                height: 1,
                                color: queueNumber == "-" ? Colors.grey.shade300 : Colors.black
                              )
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                              child: Text(currentPatientName, style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                            )
                          ],
                        ),
                      ),
                      
                      // ฝั่งขวา: ห้องตรวจ + ชื่อแพทย์
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end, // จัดชิดขวา
                        children: [
                          // 💡 3. แสดงชื่อแพทย์ที่นี่ (เหนือห้องตรวจ)
                          if (doctorName != "-" && doctorName.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4)
                              ),
                              child: Text(
                                "แพทย์: $doctorName",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                              ),
                            ),

                          const Text("ห้องตรวจ", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFFF5F7FB),
                            child: Text(roomNumber, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                          )
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Buttons ---
                  Row(
                    children: [
                      Expanded(flex: 3, child: _buildBtn("เรียกซ้ำ", const Color(0xFF64B5F6), onNext != null ? () {} : null)),
                      const SizedBox(width: 8),
                      Expanded(flex: 3, child: _buildBtn("เรียกถัดไป", const Color(0xFF1976D2), onNext)),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: _buildBtn("ข้าม", const Color(0xFFFFB74D), onSkip)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // --- รายการคิวถัดไป ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Expanded(child: Text("รายละเอียดคิว", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 60, child: Center(child: Text("ลำดับคิว", style: TextStyle(fontWeight: FontWeight.bold)))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  if (nextQueues.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text("- ไม่มีคิวรอ -", style: TextStyle(color: Colors.grey.shade400)),
                    ),

                  ...nextQueues.map((q) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(color: const Color(0xFFFFCC80), borderRadius: BorderRadius.circular(30)),
                            child: Text("ชื่อผู้ป่วย : ${q['name']}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(color: const Color(0xFF42A5F5), borderRadius: BorderRadius.circular(30)),
                          child: Text(q['id']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBtn(String text, Color color, VoidCallback? onTap) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}