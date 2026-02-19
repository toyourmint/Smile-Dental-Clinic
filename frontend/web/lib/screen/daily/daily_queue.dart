import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/screen/daily/daily_table.dart';
import 'package:flutter_application_1/screen/daily/queue_manage.dart';

class DailyQueueScreen extends StatefulWidget {
  const DailyQueueScreen({super.key});

  @override
  State<DailyQueueScreen> createState() => _DailyQueueScreenState();
}

class _DailyQueueScreenState extends State<DailyQueueScreen> {
  String apiDate = "";
  List<dynamic> allPatients = [];
  bool isLoading = true;

  // 💡 กำหนดชื่อแพทย์ประจำห้องที่นี่
  final String fixedDoctorA = "นายแพทย์ณัฐวิทย์ โนวังหาร";
  final String fixedDoctorB = "นายแพทย์ธนภัทร ธนศรีสถิตย์";

  @override
  void initState() {
    super.initState();
    _initializeTodayDate();
    _fetchQueues();
  }

  void _initializeTodayDate() {
    DateTime now = DateTime.now();
    apiDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> _fetchQueues() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/queue/all?date=$apiDate'));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          allPatients = data['profiles'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching queues: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Map<String, dynamic>? _getPatientInRoom(String room) {
    try {
      return allPatients.firstWhere(
        (p) => p['current_status'] == "InQueue" && p['assigned_room'] == room
      );
    } catch (e) {
      return null;
    }
  }

  // 💡 ฟังก์ชันกดรับคิวแบบมีเงื่อนไข (เช็คชื่อแพทย์)
  void _onReceiveQueue(Map<String, dynamic> patient) async {
    String currentDoctor = patient['doctor_name'] ?? "-";
    bool hasDoctor = currentDoctor != "-" && currentDoctor.isNotEmpty;

    // เช็คว่าควรแสดงปุ่มห้องไหนบ้าง
    bool showRoomA = !hasDoctor || currentDoctor == fixedDoctorA;
    bool showRoomB = !hasDoctor || currentDoctor == fixedDoctorB;

    String? selectedRoom = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("เลือกห้องตรวจ", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ข้อความแสดงใน Popup เปลี่ยนไปตามว่ามีหมอหรือยัง
              if (hasDoctor)
                Text(
                  "แพทย์ผู้ตรวจ: $currentDoctor\nกรุณากดรับคิวเพื่อส่งไปยังห้องตรวจ", 
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.5)
                )
              else
                const Text(
                  "ผู้ป่วยรายนี้ยังไม่ได้ระบุแพทย์\nกรุณาเลือกห้องตรวจเพื่อจ่ายงานและระบบจะเพิ่มชื่อแพทย์ให้อัตโนมัติ", 
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.5)
                ),
                
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showRoomA)
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, "A"), 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade100, 
                        foregroundColor: Colors.blue.shade900, 
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: const Text("ห้องตรวจ A", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  
                  if (showRoomA && showRoomB) const SizedBox(width: 40),
                  
                  if (showRoomB)
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, "B"), 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade100, 
                        foregroundColor: Colors.green.shade900, 
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: const Text("ห้องตรวจ B", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                ],
              )
            ],
          ),
        );
      }
    );

    if (selectedRoom == null) return;

    // 💡 ถ้าคนไข้ยังไม่มีหมอ ให้เตรียมชื่อหมอตามห้องเพื่อส่งไปอัปเดตที่ Database
    String? assignDoctorName;
    if (!hasDoctor) {
      assignDoctorName = selectedRoom == "A" ? fixedDoctorA : fixedDoctorB;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/queue/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "appointment_id": patient['appointment_id'],
          "user_id": patient['user_id'] ?? 0,
          "room": selectedRoom,
          "assign_doctor_name": assignDoctorName // 💡 ส่งค่าชื่อหมอไปอัปเดตถ้าจำเป็น
        })
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('สร้างคิวสำเร็จ'), backgroundColor: Colors.green));
        _fetchQueues(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาดในการสร้างคิว'), backgroundColor: Colors.red));
      }
    } catch (e) {
      debugPrint("Error generating queue: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่สามารถเชื่อมต่อระบบคิวได้'), backgroundColor: Colors.red));
    }
  }

  void _processQueue(String roomName, {required bool isSkip}) async {
    try {
      final endpoint = isSkip ? 'skip' : 'next';
      final url = Uri.parse('http://localhost:3000/api/queue/$endpoint?room=$roomName');
      
      http.Response response = isSkip ? await http.post(url) : await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'ดำเนินการสำเร็จ'), 
            backgroundColor: isSkip ? Colors.orange : Colors.green
          )
        );
        _fetchQueues(); 
      }
    } catch (e) {
      debugPrint("Error processing queue: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ระบบขัดข้อง'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var currentPatientRoomA = _getPatientInRoom("A");
    var currentPatientRoomB = _getPatientInRoom("B");

    String labelQueueA = currentPatientRoomA != null ? "${currentPatientRoomA['assigned_room']}${currentPatientRoomA['queue_number']}" : "-";
    String labelNameA = currentPatientRoomA != null ? "${currentPatientRoomA['first_name']} ${currentPatientRoomA['last_name']}" : "ว่าง";

    String labelQueueB = currentPatientRoomB != null ? "${currentPatientRoomB['assigned_room']}${currentPatientRoomB['queue_number']}" : "-";
    String labelNameB = currentPatientRoomB != null ? "${currentPatientRoomB['first_name']} ${currentPatientRoomB['last_name']}" : "ว่าง";

    List<Map<String, String>> waitingListA = allPatients
        .where((p) => p['current_status'] == "Waiting" && p['assigned_room'] == "A")
        .map((p) => {"id": "${p['assigned_room']}${p['queue_number']}", "name": "${p['first_name']} ${p['last_name']}"})
        .toList();

    List<Map<String, String>> waitingListB = allPatients
        .where((p) => p['current_status'] == "Waiting" && p['assigned_room'] == "B")
        .map((p) => {"id": "${p['assigned_room']}${p['queue_number']}", "name": "${p['first_name']} ${p['last_name']}"})
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ฝั่งซ้าย: ตารางรายชื่อ
          Expanded(
            flex: 3,
            child: isLoading 
              ? const Center(child: CircularProgressIndicator())
              : DailyPatientTable(
                  patients: allPatients, 
                  onAddToQueue: (index) {
                    _onReceiveQueue(allPatients[index]);
                  },
                ),
          ),

          // ฝั่งขวา: แผงควบคุมคิวห้อง A และ B
          Container(
            width: 400,
            color: const Color(0xFFEAF6FF), 
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white, width: 2))
                    ),
                    child: QueueManagerSection(
                      queueNumber: labelQueueA,
                      roomNumber: "A", 
                      currentPatientName: labelNameA,
                      doctorName: fixedDoctorA, // แสดงชื่อตายตัวที่แผง A
                      nextQueues: waitingListA, 
                      onNext: () => _processQueue("A", isSkip: false),
                      onSkip: () => _processQueue("A", isSkip: true),
                    ),
                  ),
                ),
                
                Expanded(
                  child: QueueManagerSection(
                    queueNumber: labelQueueB,
                    roomNumber: "B", 
                    currentPatientName: labelNameB,
                    doctorName: fixedDoctorB, // แสดงชื่อตายตัวที่แผง B
                    nextQueues: waitingListB, 
                    onNext: () => _processQueue("B", isSkip: false),
                    onSkip: () => _processQueue("B", isSkip: true),
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