import 'package:flutter/material.dart';

class QueueManagerSection extends StatelessWidget {
  final String queueNumber;
  final String roomNumber;
  final String currentPatientName;
  final String doctorName;
  final List<Map<String, String>> nextQueues;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;

  const QueueManagerSection({
    super.key,
    required this.queueNumber,
    required this.roomNumber,
    required this.currentPatientName,
    required this.doctorName,
    required this.nextQueues,
    this.onNext,
    this.onSkip,
  });

  // ใช้โทนสีเดียวกันทุกห้องตรวจ (อิงจากสีน้ำเงินหลักของ Smile Dental Clinic)
  Color get _badgeBg => const Color(0xFFE8F0FE);     // พื้นหลังป้ายห้อง/ป้ายคิว (ฟ้าอ่อนคลีนๆ)
  Color get _badgeFg => const Color(0xFF1A56A4);     // ตัวอักษรบนป้าย (น้ำเงินเข้มคมชัด)
  Color get _badgeBorder => const Color(0xFFC5D8F8); // เส้นขอบป้าย

  @override
  Widget build(BuildContext context) {
    final bool hasQueue = queueNumber != "-";

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===== Card หลัก =====
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Header: ป้ายห้อง ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _badgeBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _badgeBorder, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            roomNumber,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _badgeFg,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "ห้องตรวจ $roomNumber",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- แถบชื่อแพทย์ ---
                if (doctorName.isNotEmpty && doctorName != "-")
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      border: Border(
                        top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
                        bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 13, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            doctorName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
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
                          color: hasQueue ? const Color(0xFF1A56A4) : const Color(0xFFD1D5DB),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC), // ปรับพื้นหลังกล่องข้อความให้มีมิติ ไม่ดูกลืนกับพื้นหลังขาวเกินไป
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "กำลังตรวจ",
                                style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                currentPatientName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: hasQueue ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
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
                      // เรียกซ้ำ (ตกแต่งให้มีสไตล์พรีเมียม ขอบฟ้าอมน้ำเงิน เข้ากับธีมระบบ)
                      Expanded(child: _buildOutlineBtn("เรียกซ้ำ", onNext != null ? () {} : null)),
                      const SizedBox(width: 6),
                      // เรียกถัดไป
                      Expanded(child: _buildSolidBtn("เรียกถัดไป", onNext)),
                      const SizedBox(width: 6),
                      // ข้าม (ปรับเส้นสโตรกสีเหลืองตามดีไซน์ที่ชอบ)
                      SizedBox(width: 56, child: _buildSkipBtn("ข้าม", onSkip)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ===== Card คิวรอ =====
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
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
                    child: Row(
                      children: const [
                        Expanded(
                          child: Text(
                            "ชื่อผู้ป่วย",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF9CA3AF),
                              letterSpacing: 0.4,
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
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF9CA3AF),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 0.5, thickness: 0.5, color: Color(0xFFE5E7EB)),

                  // รายการคิวรอ
                  Expanded(
                    child: nextQueues.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.inbox_outlined, size: 28, color: Color(0xFFD1D5DB)),
                              SizedBox(height: 6),
                              Text(
                                "ไม่มีคิวรอ",
                                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          itemCount: nextQueues.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 5),
                          itemBuilder: (context, i) {
                            final q = nextQueues[i];
                            return Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC), // ปรับพื้นหลังแถวคิวรอให้อ่านแยกบรรทัดง่ายขึ้น ไม่กลืนหายไป
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
                                    ),
                                    child: Text(
                                      q['name'] ?? "-",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF374151),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 56,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _badgeBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _badgeBorder, width: 1),
                                  ),
                                  child: Center(
                                    child: Text(
                                      q['id']!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _badgeFg,
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

  Widget _buildSolidBtn(String text, VoidCallback? onTap) {
    final bool enabled = onTap != null;
    return SizedBox(
      height: 34,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? const Color(0xFF1A56A4) : const Color(0xFFF3F4F6),
          foregroundColor: enabled ? Colors.white : const Color(0xFF9CA3AF),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ),
    );
  }

  // ปุ่มเรียกซ้ำ ตกแต่งสไตล์ Outline ร่วมสมัย (ขอบฟ้าอมน้ำเงินแมตช์ธีมหลัก)
  Widget _buildOutlineBtn(String text, VoidCallback? onTap) {
    final bool enabled = onTap != null;
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: enabled ? const Color(0xFFF8FAFC) : Colors.transparent,
          foregroundColor: enabled ? const Color(0xFF1A56A4) : const Color(0xFF9CA3AF),
          side: BorderSide(
            color: enabled ? const Color(0xFF93C5FD) : const Color(0xFFE5E7EB),
            width: 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ปุ่มข้ามคิว (สโตรกเส้นขอบสีเหลืองทอง / ฟอนต์สีน้ำตาลส้มอมเหลือง)
  Widget _buildSkipBtn(String text, VoidCallback? onTap) {
    final bool enabled = onTap != null;
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: enabled ? const Color(0xFFFFFBEB) : Colors.transparent, // ใส่สีเหลืองจางๆ ด้านในเวลาเปิดใช้งานเพื่อให้ปุ่มดูละมุนขึ้น
          foregroundColor: enabled ? const Color(0xFFB45309) : const Color(0xFF9CA3AF),
          side: BorderSide(
            color: enabled ? const Color(0xFFFCD34D) : const Color(0xFFE5E7EB), 
            width: 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ),
    );
  }
}