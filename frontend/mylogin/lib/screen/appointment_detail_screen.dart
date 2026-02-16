// ไฟล์: screen/appointment_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mylogin/screen/appointment_modal.dart'; 

class AppointmentDetailScreen extends StatelessWidget {
  final AppointmentModel appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    // 1. แปลงปี ค.ศ. เป็น พ.ศ. (+543)
    final thaiYear = appointment.date.year + 543;

    // 2. แปลงชื่อเดือนเป็นภาษาไทย
    final monthName = DateFormat('MMMM', 'th').format(appointment.date);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "รายละเอียดการนัดหมาย",
          style: GoogleFonts.kanit(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // แถวที่ 1: วัน / เดือน / ปี
            Row(
              children: [
                Expanded(flex: 1, child: _buildInfoBox("วันที่", "${appointment.date.day}")),
                const SizedBox(width: 10),
                // *** แก้ไขตรงนี้: เรียกใช้ตัวแปร monthName ที่เราแปลงไว้แล้ว ***
                Expanded(flex: 2, child: _buildInfoBox("เดือน", monthName)), 
                const SizedBox(width: 10),
                Expanded(flex: 1, child: _buildInfoBox("ปี", "$thaiYear")),
              ],
            ),
            const SizedBox(height: 15),

            // แถวที่ 2: เวลา
            _buildInfoBox("เวลานัดหมาย", "${appointment.time} น."),
            const SizedBox(height: 15),

            // แถวที่ 3: ชื่อจริง (จำลองข้อมูล)
            _buildInfoBox("ชื่อจริง", appointment.firstName),
            const SizedBox(height: 15),

            // แถวที่ 4: นามสกุล (จำลองข้อมูล)
            _buildInfoBox("นามสกุล",appointment.lastName),
            const SizedBox(height: 15),

            // แถวที่ 5: รายละเอียด (ชื่อบริการ)
            _buildInfoBox("รายละเอียด", appointment.serviceName),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Widget สร้างกล่องข้อความแบบ Read-only
  Widget _buildInfoBox(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.kanit(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}