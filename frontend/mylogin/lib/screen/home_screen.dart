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
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final q = await AppointmentService.getCurrentQueueFromClinic();
    if (mounted) {
      setState(() {
        currentClinicQueue = q;
        isLoading = false;
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
    final AppointmentModel? latestBooking = myAppointments.isNotEmpty
        ? myAppointments.last
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: GoogleFonts.kanit(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          currentUser.name,
                          style: GoogleFonts.kanit(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    _buildProfileAvatar(),
                  ],
                ),

                const SizedBox(height: 25),

                // Logic การแสดงผล Card
                if (latestBooking != null)
                  _buildQueueCard(latestBooking)
                else
                  _buildNoBookingCard(),

                const SizedBox(height: 30),

                // Search Bar
                _buildSearchBar(),

                const SizedBox(height: 30),

                Text(
                  "รายชื่อทันตแพทย์",
                  style: GoogleFonts.kanit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                // --- [แก้ไข] เรียกใช้ Card แบบใหม่ (ไม่ต้องส่ง distance) ---
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Widget ย่อย ---

  Widget _buildProfileAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: const CircleAvatar(
        radius: 28,
        backgroundColor: Colors.orangeAccent,
        child: Icon(Icons.face, color: Colors.white, size: 35),
      ),
    );
  }

  Widget _buildQueueCard(AppointmentModel booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF448AFF), Color(0xFF2979FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?img=11',
                ),
                radius: 22,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUser.name,
                    style: GoogleFonts.kanit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "บริการ: ${booking.serviceName.replaceAll('\n', ' ')}",
                    style: const TextStyle(
                      color: ColorUtils.whiteCC,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(color: Colors.white24),
          ),
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQueueInfo("คิวของคุณ", "${booking.queueNumber}"),
                const VerticalDivider(color: Colors.white24, thickness: 1),
                _buildQueueInfo("คิวปัจจุบัน", "$currentClinicQueue"),
              ],
            ),
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
          Icon(
            Icons.calendar_today_outlined,
            size: 40,
            color: Colors.blue.shade300,
          ),
          const SizedBox(height: 10),
          Text(
            "คุณยังไม่มีการนัดหมาย",
            style: GoogleFonts.kanit(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 5),
          Text(
            "จองคิวทันตแพทย์ผู้เชี่ยวชาญได้เลย",
            style: GoogleFonts.kanit(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: "ค้นหาทันตแพทย์...",
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildQueueInfo(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: ColorUtils.whiteB8, fontSize: 14),
        ),
        Text(
          value,
          style: GoogleFonts.kanit(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // --- [แก้ไข] Widget นี้: เอาปุ่มและ distance ออก ---
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
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        // ใช้ Row อย่างเดียว เพราะไม่ต้องมีปุ่มด้านล่างแล้ว
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              image,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                Text(
                  specialty,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          ),
          // เอาส่วนแสดง Distance ออกแล้ว
        ],
      ),
    );
  }
}

class ColorUtils {
  static const Color whiteCC = Color(0xCCFFFFFF);
  static const Color whiteB8 = Color(0xB8FFFFFF);
}
