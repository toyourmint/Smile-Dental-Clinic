import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylogin/screen/appointment_modal.dart';
import '../services/appointment_service.dart';
import '../services/doctor_service.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String currentClinicQueue = "-";

  bool isQueueLoading = true;
  bool isDoctorLoading = true;
  bool isAppointmentLoading = true;

  List<Doctor> doctors = [];
  List<AppointmentModel> appointments = [];

  @override
  void initState() {
    super.initState();
    _loadQueue();
    _loadDoctors();
    _loadAppointments();
  }

  /// โหลดรายการนัดหมายจาก backend
  Future<void> _loadAppointments() async {
    try {
      final data = await AppointmentService.fetchAppointments();

      if (mounted) {
        setState(() {
          appointments = data;
          isAppointmentLoading = false;
        });
      }
    } catch (e) {
      print("โหลดนัดหมายผิดพลาด: $e");
      setState(() => isAppointmentLoading = false);
    }
  }

  /// โหลดคิวปัจจุบัน
  Future<void> _loadQueue() async {
    try {
      final q = await AppointmentService.getCurrentQueueFromClinic();

      if (mounted) {
        setState(() {
          currentClinicQueue = q;
          isQueueLoading = false;
        });
      }
    } catch (e) {
      setState(() => isQueueLoading = false);
    }
  }

  /// โหลดรายชื่อหมอ
  Future<void> _loadDoctors() async {
    try {
      doctors = await DoctorService.fetchDoctors();
    } catch (e) {
      print("Doctor load error: $e");
    }

    if (mounted) {
      setState(() {
        isDoctorLoading = false;
      });
    }
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "สวัสดีตอนเช้า,";
    if (hour >= 12 && hour < 17) return "สวัสดีตอนบ่าย,";
    if (hour >= 17 && hour < 20) return "สวัสดีตอนเย็น,";
    return "สวัสดีครับ,";
  }

  @override
  Widget build(BuildContext context) {
    /// ใช้ข้อมูลล่าสุดจาก backend
    final AppointmentModel? latestBooking =
        appointments.isNotEmpty ? appointments.last : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getGreeting(),
                            style: GoogleFonts.kanit(
                                fontSize: 18, color: Colors.grey[600])),
                        Text(widget.userName,
                            style: GoogleFonts.kanit(
                                fontSize: 26,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.orangeAccent,
                      child: Icon(Icons.face, color: Colors.white, size: 35),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                /// ===== คิว =====
                if (isAppointmentLoading || isQueueLoading)
                  const Center(child: CircularProgressIndicator())
                else if (latestBooking != null)
                  _buildQueueCard(latestBooking)
                else
                  _buildNoBookingCard(),

                const SizedBox(height: 30),

                _buildSearchBar(),

                const SizedBox(height: 30),

                Text("รายชื่อทันตแพทย์",
                    style: GoogleFonts.kanit(
                        fontSize: 20, fontWeight: FontWeight.bold)),

                const SizedBox(height: 15),

                if (isDoctorLoading)
                  const Center(child: CircularProgressIndicator())
                else if (doctors.isEmpty)
                  Text("ไม่พบรายชื่อทันตแพทย์",
                      style: GoogleFonts.kanit(color: Colors.grey))
                else
                  Column(
                    children: doctors.map((doc) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: _buildDoctorCard(
                          name: doc.name,
                          specialty: "ทันตแพทย์ทั่วไป",
                          image: "https://i.pravatar.cc/150?img=${doc.id}",
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ================= QUEUE CARD =================
  Widget _buildQueueCard(AppointmentModel booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF448AFF), Color(0xFF2979FF)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundImage:
                    NetworkImage('https://i.pravatar.cc/150?img=11'),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${booking.firstName} ${booking.lastName}",
                      style: GoogleFonts.kanit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "บริการ: ${booking.serviceName}",
                      style: const TextStyle(
                        color: ColorUtils.whiteCC,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQueueInfo("คิวของคุณ", "${booking.queueNumber}"),
              const VerticalDivider(color: Colors.white24),
              _buildQueueInfo("คิวปัจจุบัน", currentClinicQueue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoBookingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 40, color: Colors.blue.shade300),
          const SizedBox(height: 10),
          Text("คุณยังไม่มีการนัดหมาย",
              style: GoogleFonts.kanit(
                  fontSize: 16, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildQueueInfo(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: ColorUtils.whiteB8)),
        Text(value,
            style: GoogleFonts.kanit(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: "ค้นหาทันตแพทย์...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildDoctorCard({
    required String name,
    String? specialty,
    String? image,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: image != null
                ? Image.network(image, width: 60, height: 60, fit: BoxFit.cover)
                : _defaultAvatar(),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(specialty ?? "",
                    style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _defaultAvatar() {
  return Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(15),
    ),
    child: const Icon(Icons.person, size: 30, color: Colors.white),
  );
}

class ColorUtils {
  static const Color whiteCC = Color(0xCCFFFFFF);
  static const Color whiteB8 = Color(0xB8FFFFFF);
}
