import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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

  Map<String, dynamic>? myQueue;
  bool hasActiveQueue = false;

  List<Doctor> doctors = [];
  List<AppointmentModel> appointments = [];

  @override
  void initState() {
    super.initState();
    _loadQueue();
    _loadDoctors();
    _loadAppointments();
    _loadMyQueue();   // ⭐ โหลดคิวของผู้ใช้
    _startQueueAutoRefresh();   // ⭐ เพิ่ม
  }

  /// โหลดนัดหมาย
  Future<void> _loadAppointments() async {
    try {
      final data = await AppointmentService.fetchAppointments();
      if (mounted) {
        setState(() {
          appointments = data.where((a) =>
          a.status != 'cancelled' &&
          a.status != 'completed'
        ).toList();

          isAppointmentLoading = false;
        });
      }
    } catch (_) {
      setState(() => isAppointmentLoading = false);
    }
  }

  /// โหลดคิวปัจจุบันของคลินิก
  Future<void> _loadQueue() async {
    try {
      final q = await AppointmentService.getCurrentQueueFromClinic();
      if (mounted) {
        setState(() {
          currentClinicQueue = q.replaceAll(RegExp(r'[^0-9]'), '');

          isQueueLoading = false;
        });
      }
    } catch (_) {
      setState(() => isQueueLoading = false);
    }
  }

  /// ⭐ โหลดคิวของผู้ใช้ (waiting เท่านั้น)
  Future<void> _loadMyQueue() async {
    try {
      final q = await AppointmentService.getMyQueue();

      if (!mounted) return;

      setState(() {
        if (q == null) {
          /// ⭐ ล้างค่าทั้งหมด
          myQueue = null;
          hasActiveQueue = false;
          return;
        }

        final status = q['status'];

        if (status != 'waiting' && status != 'in_room') {
          /// ⭐ กันสถานะอื่น
          myQueue = null;
          hasActiveQueue = false;
          return;
        }

        /// ⭐ แสดงคิวปกติ
        myQueue = q;
        hasActiveQueue = true;
      });

    } catch (e) {
      print("Queue error: $e");
    }
  }


  void _startQueueAutoRefresh() {
  Future.doWhile(() async {
    await Future.delayed(const Duration(seconds: 5));
    await _loadQueue();
    await _loadMyQueue();   // ⭐ อัปเดตสถานะคิวผู้ใช้ด้วย
    return mounted;
  });
}


  /// โหลดรายชื่อหมอ
  Future<void> _loadDoctors() async {
    try {
      doctors = await DoctorService.fetchDoctors();
    } catch (_) {}

    if (mounted) {
      setState(() => isDoctorLoading = false);
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

                /// ===== QUEUE DASHBOARD =====
                if (isQueueLoading)
                  const Center(child: CircularProgressIndicator())

                // ⭐ แสดงคิวเฉพาะเมื่อมี waiting queue
                else if (hasActiveQueue && myQueue != null)

                 _buildQueueStatusCard(
                  int.parse(myQueue!['queue_number'].toString()),
                  myQueue!['room'] ?? 'A',
                  myQueue!['status'],
                  myQueue!['service_name'] ?? '',
                )



                else
                  _buildNoBookingCard(),

                const SizedBox(height: 25),

                /// ===== APPOINTMENTS =====
                if (appointments.isNotEmpty)
                  Column(
                    children:
                        appointments.map((e) => _buildCompactCard(e)).toList(),
                  ),

                const SizedBox(height: 30),

                _buildSearchBar(),

                const SizedBox(height: 30),

                /// DOCTORS
                Text("รายชื่อทันตแพทย์",
                    style: GoogleFonts.kanit(
                        fontSize: 20, fontWeight: FontWeight.bold)),

                const SizedBox(height: 15),

                if (isDoctorLoading)
                  const Center(child: CircularProgressIndicator())
                else if (doctors.isEmpty)
                  Center(
                      child: Text("ไม่พบรายชื่อทันตแพทย์",
                          style: GoogleFonts.kanit(color: Colors.grey)))
                else
                  Column(
                    children: doctors.map((doc) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: _buildDoctorCard(
                          name: doc.name,
                          specialty: "ทันตแพทย์ทั่วไป",
                          image:
                              "https://i.pravatar.cc/150?img=${doc.id}",
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

  /// ================= QUEUE DASHBOARD =================
  Widget _buildQueueStatusCard(
  int myQueueNumber,
  String room,
  String status,
  String serviceName,
) {
  int currentQ = int.tryParse(currentClinicQueue) ?? 0;
  int waitingCount = (myQueueNumber - currentQ).clamp(0, 999);


  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: status == 'in_room'
          ? const LinearGradient(
              colors: [Color(0xFF00C853), Color(0xFF1B5E20)], // 🟢 เขียวเมื่อถึงคิว
            )
          : const LinearGradient(
              colors: [Color(0xFF2979FF), Color(0xFF0D47A1)],
            ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        /// 🔹 แถวคิว
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _queueColumn("คิวปัจจุบัน", "$room-$currentQ", Colors.white),

            Container(height: 40, width: 1, color: Colors.white24),

            _queueColumn("คิวของคุณ", "$room-$myQueueNumber", Colors.amberAccent),
          ],
        ),

        const SizedBox(height: 14),

        /// 🔹 ชื่อบริการ
        if (serviceName.isNotEmpty)
          Text(
            serviceName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.kanit(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),

        const SizedBox(height: 12),

        /// 🔹 ข้อความสถานะ
        Text(
          status == 'in_room'
              ? "ถึงคิวของคุณแล้ว กรุณาเข้าห้องตรวจ"
              : waitingCount > 0
                  ? "รออีก $waitingCount คิว (~${waitingCount * 15} นาที)"
                  : "ใกล้ถึงคิวของคุณแล้ว",
          textAlign: TextAlign.center,
          style: GoogleFonts.kanit(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}


  Widget _queueColumn(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.kanit(color: Colors.white70, fontSize: 14)),
        Text(value,
            style: GoogleFonts.kanit(
                color: color,
                fontSize: 32,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCompactCard(AppointmentModel booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(DateFormat('d MMM').format(booking.date),
              style: GoogleFonts.kanit(fontWeight: FontWeight.bold)),
          const SizedBox(width: 15),
          Expanded(child: Text(booking.serviceName)),
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
      ),
      child: Column(
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 40, color: Colors.blue.shade300),
          const SizedBox(height: 10),
          Text("คุณยังไม่มีคิวในขณะนี้",
              style: GoogleFonts.kanit(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: "ค้นหาทันตแพทย์...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20)),
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
          borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: image != null
                ? Image.network(image,
                    width: 60, height: 60, fit: BoxFit.cover)
                : _defaultAvatar(),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return const CircleAvatar(
      radius: 28,
      backgroundColor: Colors.orangeAccent,
      child: Icon(Icons.face, color: Colors.white, size: 35),
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
    child: const Icon(Icons.person, color: Colors.white),
  );
}
