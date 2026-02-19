import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // ใช้สำหรับจัดรูปแบบวันที่
import 'package:mylogin/screen/appointment_modal.dart';
import '../services/appointment_service.dart';
import '../services/doctor_service.dart'; // import service หมอจาก dev

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- State Variables ---
  int currentClinicQueue = 0;
  bool isLoading = true;
  
  // ตัวแปรสำหรับหมอ (จาก dev)
  List<Doctor> doctors = [];
  bool isDoctorLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQueue();    // โหลดคิว
    _loadDoctors();  // โหลดหมอ
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
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// โหลดรายชื่อหมอ (จาก dev)
  Future<void> _loadDoctors() async {
    try {
      doctors = await DoctorService.fetchDoctors();
      print("Loaded doctors: ${doctors.length}");
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
    // 1. เรียงลำดับนัดหมาย (ใกล้สุดขึ้นก่อน) - จาก HEAD
    final sortedAppointments = List.from(myAppointments)
      ..sort((a, b) {
        int cmp = a.date.compareTo(b.date);
        if (cmp != 0) return cmp;
        return a.time.compareTo(b.time);
      });

    // สมมติคิวของคุณ
    int myQueueNumber = currentClinicQueue + 3;

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
                        Text(
                          _getGreeting(),
                          style: GoogleFonts.kanit(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          widget.userName,
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

                // ============================================
                // ส่วนแสดงสถานะคิว (Queue Dashboard) - จาก HEAD
                // ============================================
                if (isLoading)
                   const Center(child: CircularProgressIndicator())
                else if (sortedAppointments.isNotEmpty)
                  _buildQueueStatusCard(currentClinicQueue, myQueueNumber),

                const SizedBox(height: 25),

                // --- ส่วนแสดงรายการนัดหมายแบบย่อ (Compact List) - จาก HEAD ---
                if (sortedAppointments.isNotEmpty)
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15, left: 5),
                        child: Row(
                          children: [
                            const Icon(Icons.event_note, color: Colors.blueAccent),
                            const SizedBox(width: 8),
                            Text(
                              "นัดหมายของคุณ (${sortedAppointments.length})",
                              style: GoogleFonts.kanit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...sortedAppointments.map((booking) {
                        return _buildCompactCard(booking);
                      }).toList(),
                    ],
                  )
                else
                  _buildNoBookingCard(),

                const SizedBox(height: 30),

                // --- Search Bar ---
                _buildSearchBar(),

                const SizedBox(height: 30),

                // --- Doctor List (ใช้ Logic จาก dev เพื่อรองรับ backend) ---
                Text("รายชื่อทันตแพทย์",
                    style: GoogleFonts.kanit(
                        fontSize: 20, fontWeight: FontWeight.bold)),

                const SizedBox(height: 15),

                if (isDoctorLoading)
                  const Center(child: CircularProgressIndicator())
                else if (doctors.isEmpty)
                   // ถ้าโหลดแล้วไม่มีหมอ ให้แสดง Text
                  Center(child: Text("ไม่พบรายชื่อทันตแพทย์", style: GoogleFonts.kanit(color: Colors.grey)))
                else
                   // วนลูปสร้างการ์ดหมอจากข้อมูลจริง
                  Column(
                    children: doctors.map((doc) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: _buildDoctorCard(
                          name: doc.name,
                          specialty: "ทันตแพทย์ทั่วไป", // หรือ doc.specialty ถ้ามี
                          image: "https://i.pravatar.cc/150?img=${doc.id}", // รูปจำลอง
                        ),
                      );
                    }).toList(),
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

  // [ใหม่] การ์ดแสดงสถานะคิว (จาก HEAD)
  Widget _buildQueueStatusCard(int currentQ, int myQ) {
    int waitingCount = myQ - currentQ; 

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2979FF), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ฝั่งซ้าย: คิวปัจจุบัน
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("คิวปัจจุบัน", 
                    style: GoogleFonts.kanit(color: Colors.white70, fontSize: 14)),
                  Text(
                    "A-$currentQ",
                    style: GoogleFonts.kanit(
                      color: Colors.white, 
                      fontSize: 32, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
              Container(height: 40, width: 1, color: Colors.white24),
              // ฝั่งขวา: คิวของคุณ
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("คิวของคุณ", 
                    style: GoogleFonts.kanit(color: Colors.white70, fontSize: 14)),
                  Text(
                    "A-$myQ",
                    style: GoogleFonts.kanit(
                      color: Colors.amberAccent,
                      fontSize: 32, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  "รออีก $waitingCount คิว (ประมาณ ${waitingCount * 15} นาที)", 
                  style: GoogleFonts.kanit(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

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

  // การ์ดนัดหมายแบบย่อ (Compact List - จาก HEAD)
  Widget _buildCompactCard(AppointmentModel booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('d').format(booking.date),
                  style: GoogleFonts.kanit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    height: 1.0,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(booking.date),
                  style: GoogleFonts.kanit(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceName.replaceAll('\n', ' '),
                  style: GoogleFonts.kanit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      "${booking.time} น. • ทันตแพทย์ผู้เชี่ยวชาญ",
                      style: GoogleFonts.kanit(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
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
          Icon(Icons.calendar_today_outlined, size: 40, color: Colors.blue.shade300),
          const SizedBox(height: 10),
          Text("คุณยังไม่มีการนัดหมาย",
              style: GoogleFonts.kanit(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 5),
          Text("จองคิวทันตแพทย์ได้เลย",
              style: GoogleFonts.kanit(fontSize: 12, color: Colors.grey.shade400)),
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

  // --- Doctor Card (ปรับปรุงจาก dev ให้รองรับ error image) ---
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
            child: image != null && image.isNotEmpty
                ? Image.network(
                    image,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _defaultAvatar();
                    },
                  )
                : _defaultAvatar(),
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
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  specialty ?? "General Doctor",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
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