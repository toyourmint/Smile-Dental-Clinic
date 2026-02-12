import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // เก็บสถานะว่าเลือก "จองคิว" หรือ "คิว"
  bool isBookingSelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // สีพื้นหลังฟ้าอ่อนตามภาพ
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "การนัดหมาย",
          style: GoogleFonts.kanit(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // 1. ส่วน Toggle Button (จองคิว / คิว)
          _buildToggleButtons(),
          const SizedBox(height: 30),
          
          // 2. ส่วน Grid รายการบริการ
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              crossAxisCount: 3, // แสดง 3 คอลัมน์
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _buildServiceCard("ตรวจสุขภาพ\nช่องปาก", Icons.medical_services, isSelected: true),
                _buildServiceCard("ฟันเทียม", Icons.health_and_safety), // เปลี่ยน icon ตามต้องการ
                _buildServiceCard("รักษารากฟัน/\nอุดฟัน", Icons.healing),
                _buildServiceCard("ฝังราก\nฟันเทียม", Icons.biotech),
                _buildServiceCard("ฟันแตก", Icons.broken_image),
                _buildServiceCard("จัดฟัน", Icons.grid_view_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget สำหรับปุ่มสลับ จองคิว/คิว
  Widget _buildToggleButtons() {
    return Container(
      width: 250,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isBookingSelected = true),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isBookingSelected ? const Color(0xFFBBDEFB) : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  border: isBookingSelected ? Border.all(color: Colors.blue.shade100, width: 2) : null,
                ),
                child: Text("จองคิว", 
                  style: GoogleFonts.kanit(color: isBookingSelected ? Colors.blue : Colors.grey)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isBookingSelected = false),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !isBookingSelected ? const Color(0xFFBBDEFB) : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text("คิว", 
                  style: GoogleFonts.kanit(color: !isBookingSelected ? Colors.blue : Colors.grey)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget สำหรับสร้าง Card บริการแต่ละอัน
  Widget _buildServiceCard(String title, IconData icon, {bool isSelected = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF42A5F5) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: isSelected ? Colors.white : const Color(0xFF42A5F5)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.kanit(
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}