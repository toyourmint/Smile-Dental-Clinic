import 'package:flutter/material.dart';

class QueueManagerSection extends StatelessWidget {
  final String queueNumber;
  final String roomNumber;
  final String currentPatientName;
  final String doctorName;
  final List<Map<String, String>> nextQueues;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;

  // เพิ่มตัวแปร themeColor เพื่อให้เปลี่ยนสีตามห้องได้แบบ Dynamic
  final Color themeColor;

  const QueueManagerSection({
    super.key,
    required this.queueNumber,
    required this.roomNumber,
    required this.currentPatientName,
    required this.doctorName,
    required this.nextQueues,
    required this.themeColor, // Require สีประจำห้อง
    this.onNext,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasQueue = queueNumber != "-";

    // สร้างสีอ่อนสำหรับพื้นหลังและเส้นขอบ โดยคำนวณจาก themeColor
    final Color bgTint = themeColor.withOpacity(0.08);
    final Color borderTint = themeColor.withOpacity(0.3);

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===== Card หลัก (ห้องตรวจปัจจุบัน) =====
          Container(
            decoration: BoxDecoration(
              color: bgTint, // ใช้สีพื้นหลังอ่อนๆ ตามสีประจำห้อง (แบบภาพ After)
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderTint, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Header: ป้ายห้อง และ ป้ายสถานะ ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: themeColor, // ป้ายห้องเป็นสีทึบ
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                roomNumber,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "ห้องตรวจ $roomNumber",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                      // ป้าย "กำลังตรวจ" มุมขวาบน (เพิ่มตามดีไซน์ After)
                      if (hasQueue)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderTint),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 3,
                                backgroundColor: themeColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "กำลังตรวจ",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: themeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // --- แถบชื่อแพทย์ ---
                if (doctorName.isNotEmpty && doctorName != "-")
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      border: Border(
                        top: BorderSide(color: borderTint, width: 0.5),
                        bottom: BorderSide(color: borderTint, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 13,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            doctorName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF4B5563),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                // --- คิวปัจจุบัน ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        hasQueue ? queueNumber : "–",
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          color: hasQueue
                              ? themeColor
                              : const Color(0xFFD1D5DB), // เลขคิวใช้สีประจำห้อง
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 250, 250, 250),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderTint, width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "กำลังตรวจ",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                currentPatientName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: hasQueue
                                      ? const Color(0xFF111827)
                                      : const Color(0xFF9CA3AF),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- ปุ่มควบคุม ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      // เรียกซ้ำ (คำยาวปานกลาง ให้ flex: 5)
                      Expanded(
                        flex: 5,
                        child: _buildOutlineBtn(
                          "เรียกซ้ำ",
                          onNext != null ? () {} : null,
                          themeColor,
                        ),
                      ),
                      const SizedBox(width: 5),

                      // เรียกถัดไป (คำยาวที่สุด ให้พื้นที่เยอะสุด flex: 6)
                      Expanded(
                        flex: 6,
                        child: _buildSolidBtn("เรียกถัดไป", onNext, themeColor),
                      ),
                      const SizedBox(width: 5),

                      // ข้าม (คำสั้นที่สุด ให้พื้นที่น้อยสุด flex: 4)
                      Expanded(flex: 4, child: _buildSkipBtn("ข้าม", onSkip)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ===== Card คิวรอ (ดีไซน์คงความคลีนไว้) =====
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
                    child: Row(
                      children: const [
                        Expanded(
                          child: Text(
                            "ชื่อผู้ป่วย",
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 56,
                          child: Text(
                            "ลำดับ",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: Color(0xFFE5E7EB),
                  ),
                  Expanded(
                    child: nextQueues.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 28,
                                  color: Color(0xFFD1D5DB),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  "ไม่มีคิวรอ",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                            itemCount: nextQueues.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 5),
                            itemBuilder: (context, i) {
                              final q = nextQueues[i];
                              return Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        q['name'] ?? "-",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF374151),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 56,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: themeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: themeColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        q['id']!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: themeColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ปรับปุ่มให้รับ themeColor
  Widget _buildSolidBtn(String text, VoidCallback? onTap, Color color) {
    final bool enabled = onTap != null;
    return SizedBox(
      height: 34,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? color : const Color(0xFFF3F4F6),
          foregroundColor: enabled ? Colors.white : const Color(0xFF9CA3AF),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 4), // ลด padding ด้านข้างเล็กน้อยเพื่อเพิ่มพื้นที่ตัวอักษร
        ),
        // ใช้ FittedBox เพื่อให้ฟอนต์ย่อขนาดตัวเองอัตโนมัติถ้าพื้นที่ไม่พอ (ไม่ตกบรรทัด)
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildOutlineBtn(String text, VoidCallback? onTap, Color color) {
    final bool enabled = onTap != null;
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: enabled ? color.withOpacity(0.05) : Colors.transparent,
          foregroundColor: enabled ? color : const Color(0xFF9CA3AF),
          side: BorderSide(color: enabled ? color.withOpacity(0.5) : const Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildSkipBtn(String text, VoidCallback? onTap) {
    final bool enabled = onTap != null;
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: enabled ? const Color(0xFFFFFBEB) : Colors.transparent,
          foregroundColor: enabled ? const Color(0xFFB45309) : const Color(0xFF9CA3AF),
          side: BorderSide(color: enabled ? const Color(0xFFFCD34D) : const Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}