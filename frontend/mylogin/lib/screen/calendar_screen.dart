import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mylogin/services/appointment_service.dart';
import 'package:mylogin/screen/appointment_modal.dart';
import 'package:mylogin/screen/date_time_screen.dart';
import 'appointment_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool isBookingSelected = true;
  bool isProcessing = false;

  List<AppointmentModel> appointments = [];
  bool isLoadingAppointments = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  /// โหลดนัดหมายจากฐานข้อมูล
  Future<void> _loadAppointments() async {
    try {
      final data = await AppointmentService.fetchAppointments();

      if (!mounted) return;

      setState(() {
        appointments = data;
        isLoadingAppointments = false;
      });
    } catch (e) {
      debugPrint("โหลดนัดหมายผิดพลาด: $e");
      setState(() => isLoadingAppointments = false);
    }
  }

  void _refreshAfterBooking() {
    _loadAppointments();
    setState(() => isBookingSelected = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading:
            const BackButton(color: Colors.black54),
        title: Text(
          isBookingSelected ? "บริการ" : "การนัดหมาย",
          style: GoogleFonts.kanit(
              color: Colors.black87,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _toggleButtons(),
          const SizedBox(height: 20),
          Expanded(
            child: isBookingSelected
                ? _serviceGrid()
                : _appointmentList(),
          ),
        ],
      ),
    );
  }

  /// ================= TOGGLE =================
  Widget _toggleButtons() {
    return Container(
      width: 250,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          _toggleButton("จองคิว", true),
          _toggleButton("คิว", false),
        ],
      ),
    );
  }

  Widget _toggleButton(String text, bool value) {
    bool active = isBookingSelected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isBookingSelected = value),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                active ? const Color(0xFFE3F2FD) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            text,
            style: GoogleFonts.kanit(
              color: active ? Colors.blue : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// ================= SERVICE GRID =================
  Widget _serviceGrid() {
    return GridView.count(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      crossAxisCount: 3,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _serviceCard("ตรวจสุขภาพ\nช่องปาก", Icons.medical_services),
        _serviceCard("ฟันเทียม", Icons.health_and_safety),
        _serviceCard("รักษารากฟัน/\nอุดฟัน", Icons.healing),
        _serviceCard("ฝังราก\nฟันเทียม", Icons.biotech),
        _serviceCard("ฟันแตก", Icons.broken_image),
        _serviceCard("จัดฟัน", Icons.grid_view_rounded),
      ],
    );
  }

  Widget _serviceCard(String title, IconData icon) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DateTimeSelectionScreen(serviceName: title),
          ),
        );

        if (result == true) {
          _refreshAfterBooking();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 35, color: Colors.grey.shade600),
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.kanit(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  /// ================= APPOINTMENT LIST =================
  Widget _appointmentList() {
    if (isLoadingAppointments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (appointments.isEmpty) {
      return Center(
        child: Text("ยังไม่มีการนัดหมาย",
            style: GoogleFonts.kanit(fontSize: 16)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final apt = appointments[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 20),
              ],
            ),
            child: Column(
              children: [

                /// 👨‍⚕️ หมอ
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(Icons.person, color: Colors.blue),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(apt.doctorName,
                              style: GoogleFonts.kanit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text(
                            "(${apt.serviceName.replaceAll('\n', ' ')})",
                            style: GoogleFonts.kanit(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                /// 📅 วันที่ & เวลา
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('d MMM yyyy').format(apt.date),
                          style: GoogleFonts.kanit(),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 18),
                        const SizedBox(width: 6),
                        Text("${apt.time} น.",
                            style: GoogleFonts.kanit()),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                /// 🔵 รายละเอียด
                _blueButton("รายละเอียด", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AppointmentDetailScreen(appointment: apt),
                    ),
                  );
                }),

                const SizedBox(height: 10),

                /// 🟠 เลื่อนนัด
                _grayButton("เลื่อนนัดหมาย", () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DateTimeSelectionScreen(
                        serviceName: apt.serviceName,
                        appointmentId: apt.id,   // ⭐ ส่ง id นัดเดิมไป
                      ),
                    ),
                  );

                  if (result == true) {
                    _loadAppointments();  // รีโหลดข้อมูล
                  }
                }),


                const SizedBox(height: 10),

                /// 🔴 ยกเลิกนัด
                _redButton("ยกเลิกนัดหมาย", () async {
                  if (apt.id == null || isProcessing) return;

                  final confirm = await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("ยืนยันการยกเลิก"),
                      content: const Text("คุณต้องการยกเลิกนัดหมายนี้หรือไม่?"),
                      actions: [
                        TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text("ไม่")),
                        TextButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: const Text("ใช่")),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  setState(() => isProcessing = true);

                  final success =
                      await AppointmentService.cancelAppointment(apt.id!);

                  setState(() => isProcessing = false);

                  if (success) {
                    setState(() {
                      appointments.removeAt(index);
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("ยกเลิกนัดหมายแล้ว")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("ยกเลิกไม่สำเร็จ")),
                    );
                  }
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}


/// ===== BUTTON STYLES =====

Widget _blueButton(String text, VoidCallback onTap) {
  return _buttonBase(
      text, onTap, const Color(0xFFEAF6FF), Colors.blue);
}

Widget _grayButton(String text, VoidCallback onTap) {
  return _buttonBase(
      text, onTap, const Color(0xFFF3F3F3), Colors.orange);
}

Widget _redButton(String text, VoidCallback onTap) {
  return _buttonBase(
      text, onTap, const Color(0xFFFFEBEE), Colors.red);
}

Widget _buttonBase(
    String text, VoidCallback onTap, Color bg, Color textColor) {
  return SizedBox(
    width: double.infinity,
    height: 45,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30)),
      ),
      child:
          Text(text, style: GoogleFonts.kanit(color: textColor)),
    ),
  );
}
