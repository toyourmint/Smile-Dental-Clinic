import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mylogin/screen/appointment_modal.dart';
import 'package:mylogin/screen/date_time_screen.dart';
import 'appointment_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // เก็บสถานะว่าเลือก "จองคิว" หรือ "คิว"
  bool isBookingSelected = true;
  // ตัวแปรเก็บชื่อบริการที่ถูกเลือก
  String selectedService = "ตรวจสุขภาพ\nช่องปาก";

  // ฟังก์ชันสำหรับรีเฟรชหน้าจอ (ใช้ตอนกดกลับมาจากหน้าจองสำเร็จ)
  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F9FF,
      ), // ปรับสีพื้นหลังให้อ่อนลงเล็กน้อย
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isBookingSelected ? "บริการ" : "การนัดหมาย", // เปลี่ยนหัวข้อตามแท็บ
          style: GoogleFonts.kanit(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildToggleButtons(),
          const SizedBox(height: 20),

          // ใช้ Expanded เพื่อสลับเนื้อหาระหว่าง "ตารางบริการ" กับ "รายการนัดหมาย"
          Expanded(
            child: isBookingSelected
                ? _buildServiceGrid() // ถ้าเลือก "จองคิว" -> โชว์ตารางบริการ
                : _buildAppointmentList(), // ถ้าเลือก "คิว" -> โชว์รายการนัด
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ส่วนที่ 1: ปุ่ม Toggle (จองคิว / คิว)
  // ==========================================
  Widget _buildToggleButtons() {
    return Center(
      child: Container(
        width: 250,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            _buildToggleButton("จองคิว", true),
            _buildToggleButton("คิว", false),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isBookingBtn) {
    bool isActive = isBookingSelected == isBookingBtn;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isBookingSelected = isBookingBtn),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE3F2FD) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            text,
            style: GoogleFonts.kanit(
              color: isActive ? Colors.blue : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ส่วนที่ 2: หน้าเลือกบริการ (Service Grid)
  // ==========================================
  Widget _buildServiceGrid() {
    return Column(
      children: [
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            crossAxisCount: 3,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            children: [
              _buildServiceCard("ตรวจสุขภาพ\nช่องปาก", Icons.medical_services),
              _buildServiceCard("ฟันเทียม", Icons.health_and_safety),
              _buildServiceCard("รักษารากฟัน/\nอุดฟัน", Icons.healing),
              _buildServiceCard("ฝังราก\nฟันเทียม", Icons.biotech),
              _buildServiceCard("ฟันแตก", Icons.broken_image),
              _buildServiceCard("จัดฟัน", Icons.grid_view_rounded),
            ],
          ),
        ),
        // ปุ่มถัดไป
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DateTimeSelectionScreen(serviceName: selectedService),
                ),
              ).then((_) {
                // *** สำคัญ: เมื่อกลับมาจากหน้าจอง ให้รีเฟรชหน้าจอเพื่อแสดงข้อมูลใหม่ ***
                _refresh();
                // สลับไปหน้า "คิว" เพื่อให้ User เห็นรายการทันที
                if (myAppointments.isNotEmpty) {
                  setState(() {
                    isBookingSelected = false;
                  });
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
            ),
            child: Text(
              "ถัดไป",
              style: GoogleFonts.kanit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildServiceCard(String title, IconData icon) {
    bool isSelected = selectedService == title;
    return GestureDetector(
      onTap: () => setState(() => selectedService = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF42A5F5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: isSelected
              ? Border.all(color: Colors.blue.shade700, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.white : const Color(0xFF42A5F5),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ส่วนที่ 3: หน้ารายการนัดหมาย (Appointment List)
  // ==========================================
  Widget _buildAppointmentList() {
    // ดึงข้อมูลจากตัวแปร Global ใน appointment_model.dart
    if (myAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(
              "ยังไม่มีการนัดหมาย",
              style: GoogleFonts.kanit(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: myAppointments.length,
      itemBuilder: (context, index) {
        final appointment = myAppointments[index]; // ดึงข้อมูลแต่ละรายการ
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // ส่วนหัว: รูปหมอ + ชื่อ
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(
                      Icons.person,
                      size: 35,
                      color: Colors.blue,
                    ), // ใส่รูปจริงตรงนี้ได้
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.doctorName,
                          style: GoogleFonts.kanit(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          "ทันตแพทย์เฉพาะทาง (${appointment.serviceName.replaceAll('\n', ' ')})",
                          style: GoogleFonts.kanit(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ส่วนข้อมูล: วันที่ และ เวลา
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFF0F0F0)),
                    bottom: BorderSide(color: Color(0xFFF0F0F0)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('d MMM yyyy').format(appointment.date),
                          style: GoogleFonts.kanit(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${appointment.time} น.",
                          style: GoogleFonts.kanit(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ปุ่ม: รายละเอียด / เลื่อนนัด
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppointmentDetailScreen(
                              appointment: appointment,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEAF6FF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        "รายละเอียด",
                        style: GoogleFonts.kanit(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: TextButton(
                      onPressed: () async {
                        // เปิดหน้าจองเวลาใหม่ (ใช้หน้าเดิมที่มี)
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DateTimeSelectionScreen(
                              serviceName:
                                  appointment.serviceName, // จองบริการเดิม
                            ),
                          ),
                        );

                        // ถ้ากลับมาพร้อมค่า true แปลว่าจองใหม่สำเร็จแล้ว
                        if (result == true) {
                          setState(() {
                            // ลบนัดหมาย "อันเก่า" ออกจาก List (เพราะเลื่อนไปอันใหม่แล้ว)
                            myAppointments.removeAt(index);
                          });

                          // แจ้งเตือนผู้ใช้นิดนึง
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'เลื่อนนัดหมายเรียบร้อยแล้ว',
                                  style: GoogleFonts.kanit(),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFFAFAFA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        "เลื่อนนัดหมาย",
                        style: GoogleFonts.kanit(color: Colors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              "ยืนยันการยกเลิก",
                              style: GoogleFonts.kanit(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: Text(
                              "คุณต้องการยกเลิกนัดหมายนี้ใช่หรือไม่?",
                              style: GoogleFonts.kanit(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  "ไม่",
                                  style: GoogleFonts.kanit(color: Colors.grey),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // ปิด Dialog
                                  setState(() {
                                    myAppointments.removeAt(index); // ลบข้อมูล
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'ยกเลิกนัดหมายเรียบร้อยแล้ว',
                                        style: GoogleFonts.kanit(),
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                },
                                child: Text(
                                  "ใช่, ยกเลิก",
                                  style: GoogleFonts.kanit(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFEBEE),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        "ยกเลิกนัดหมาย",
                        style: GoogleFonts.kanit(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
