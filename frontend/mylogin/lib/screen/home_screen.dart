import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylogin/screen/appointment_modal.dart';
import '../services/appointment_service.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentClinicQueue = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  /// โหลดคิวปัจจุบันของคลินิก
  Future<void> _loadQueue() async {
    try {
      final q = await AppointmentService.getCurrentQueueFromClinic();

      if (mounted) {
        setState(() {
          currentClinicQueue = q;
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() => isLoading = false);
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
    final AppointmentModel? latestBooking =
        myAppointments.isNotEmpty ? myAppointments.last : null;

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
                    _buildProfileAvatar(),
                  ],
                ),

                const SizedBox(height: 25),

                /// ===== แสดงคิว =====
                if (isLoading)
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

                _buildDoctorCard(
                  name: "Dr. Joseph Brostito",
                  specialty: "Dental Specialist",
                  image: "https://i.pravatar.cc/150?img=68",
                ),
                const SizedBox(height: 15),
                _buildDoctorCard(
                  name: "Dr. Imran Syahir",
                  specialty: "General Dentist",
                  image: "https://i.pravatar.cc/150?img=12",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ================= PROFILE AVATAR =================
  Widget _buildProfileAvatar() {
    return const CircleAvatar(
      radius: 28,
      backgroundColor: Colors.orangeAccent,
      child: Icon(Icons.face, color: Colors.white, size: 35),
    );
  }

  Widget _buildQueueCard(AppointmentModel booking) {
  final myQueueNumber = booking.queueNumber ?? 0;

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

            /// 🔹 ชื่อ + บริการ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ✅ ชื่อจริง + นามสกุล
                  Text(
                    "${booking.firstName} ${booking.lastName}",
                    style: GoogleFonts.kanit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),

                  /// ✅ บริการอยู่บรรทัดเดียว
                  Text(
                    "บริการ: ${booking.serviceName}",
                    style: const TextStyle(
                      color: ColorUtils.whiteCC,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            _buildQueueInfo("คิวของคุณ", "$myQueueNumber"),
            const VerticalDivider(color: Colors.white24),
            _buildQueueInfo("คิวปัจจุบัน", "$currentClinicQueue"),
          ],
        ),
      ],
    ),
  );
}


  /// ================= NO BOOKING =================
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
          const SizedBox(height: 5),
          Text("จองคิวทันตแพทย์ได้เลย",
              style: GoogleFonts.kanit(
                  fontSize: 12, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildQueueInfo(String title, String value) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(color: ColorUtils.whiteB8)),
        Text(value,
            style: GoogleFonts.kanit(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  /// ================= SEARCH =================
  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: "ค้นหาทันตแพทย์...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  /// ================= DOCTOR CARD =================
  Widget _buildDoctorCard({
    required String name,
    required String specialty,
    required String image,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(image,
                width: 60, height: 60, fit: BoxFit.cover),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold)),
              Text(specialty,
                  style: TextStyle(color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }
}

class ColorUtils {
  static const Color whiteCC = Color(0xCCFFFFFF);
  static const Color whiteB8 = Color(0xB8FFFFFF);
}
