import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// 💡 อย่าลืมเช็ค Path ของ 2 ไฟล์นี้ให้ตรงกับโปรเจกต์ของคุณด้วยนะครับ
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

  @override
  void initState() {
    super.initState();
    _initializeTodayDate();
    _fetchQueues();
  }

  void _initializeTodayDate() {
    DateTime now = DateTime.now();
    // เปลี่ยน format ให้อยู่ในรูป YYYY-MM-DD เพื่อส่งให้ Backend หาข้อมูลของวันนี้
    apiDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // 💡 ดึงข้อมูลคิวทั้งหมดจาก Backend
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

  // ดึงข้อมูลผู้ป่วยที่ "กำลังตรวจ (InQueue)" ในห้องที่ระบุ
  Map<String, dynamic>? _getPatientInRoom(String room) {
    try {
      return allPatients.firstWhere(
        (p) => p['current_status'] == "InQueue" && p['assigned_room'] == room
      );
    } catch (e) {
      return null;
    }
  }

  // 💡 ฟังก์ชันกด "รับคิว" (โยนเข้าห้อง A หรือ B)
  void _onReceiveQueue(Map<String, dynamic> patient) async {
    // 1. โชว์ Dialog ให้เลือกห้อง
    String? selectedRoom = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("เลือกห้องตรวจ", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("กรุณาระบุห้องตรวจสำหรับผู้ป่วยรายนี้"),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                  const SizedBox(width: 40),
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

    // ถ้ากดพื้นที่ว่างเพื่อปิด หรือไม่ได้เลือกห้อง ให้ยกเลิกการทำงาน
    if (selectedRoom == null) return;

    // 2. ยิง API ไปสร้างคิว
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/queue/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "appointment_id": patient['appointment_id'],
          "user_id": patient['user_id'] ?? 0,
          "room": selectedRoom
        })
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('สร้างคิวสำเร็จ'), backgroundColor: Colors.green));
        _fetchQueues(); // รีเฟรชตารางใหม่
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาดในการสร้างคิว'), backgroundColor: Colors.red));
      }
    } catch (e) {
      debugPrint("Error generating queue: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่สามารถเชื่อมต่อระบบคิวได้'), backgroundColor: Colors.red));
    }
  }

  // 💡 ฟังก์ชัน "เรียกคิวถัดไป" และ "ข้ามคิว"
  void _processQueue(String roomName, {required bool isSkip}) async {
    try {
      final endpoint = isSkip ? 'skip' : 'next';
      final url = Uri.parse('http://localhost:3000/api/queue/$endpoint?room=$roomName');
      
      http.Response response;
      if (isSkip) {
        response = await http.post(url);
      } else {
        response = await http.get(url);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'ดำเนินการสำเร็จ'), 
            backgroundColor: isSkip ? Colors.orange : Colors.green
          )
        );
        _fetchQueues(); // รีเฟรชข้อมูลคิวทั้งหมด
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
    // ดึงข้อมูลคนที่กำลังตรวจอยู่ในห้อง A และ B (InQueue)
    var currentPatientRoomA = _getPatientInRoom("A");
    var currentPatientRoomB = _getPatientInRoom("B");

    // เตรียมข้อความสำหรับโชว์ในจอห้อง A
    String labelQueueA = currentPatientRoomA != null ? "${currentPatientRoomA['assigned_room']}${currentPatientRoomA['queue_number']}" : "-";
    String labelNameA = currentPatientRoomA != null ? "${currentPatientRoomA['first_name']} ${currentPatientRoomA['last_name']}" : "ว่าง";

    // เตรียมข้อความสำหรับโชว์ในจอห้อง B
    String labelQueueB = currentPatientRoomB != null ? "${currentPatientRoomB['assigned_room']}${currentPatientRoomB['queue_number']}" : "-";
    String labelNameB = currentPatientRoomB != null ? "${currentPatientRoomB['first_name']} ${currentPatientRoomB['last_name']}" : "ว่าง";

    // ดึงรายชื่อคนที่ "รอเรียกคิว (Waiting)" ในห้อง A (เอาไปโชว์คิวถัดไป)
    List<Map<String, String>> waitingListA = allPatients
        .where((p) => p['current_status'] == "Waiting" && p['assigned_room'] == "A")
        .map((p) => {
          "id": "${p['assigned_room']}${p['queue_number']}", 
          "name": "${p['first_name']} ${p['last_name']}"
        })
        .toList();

    // ดึงรายชื่อคนที่ "รอเรียกคิว (Waiting)" ในห้อง B (เอาไปโชว์คิวถัดไป)
    List<Map<String, String>> waitingListB = allPatients
        .where((p) => p['current_status'] == "Waiting" && p['assigned_room'] == "B")
        .map((p) => {
          "id": "${p['assigned_room']}${p['queue_number']}", 
          "name": "${p['first_name']} ${p['last_name']}"
        })
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
                // แผงห้อง A
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white, width: 2))
                    ),
                    child: QueueManagerSection(
                      queueNumber: labelQueueA,
                      roomNumber: "A", 
                      currentPatientName: labelNameA,
                      nextQueues: waitingListA, 
                      onNext: () => _processQueue("A", isSkip: false),
                      onSkip: () => _processQueue("A", isSkip: true),
                    ),
                  ),
                ),
                
                // แผงห้อง B
                Expanded(
                  child: QueueManagerSection(
                    queueNumber: labelQueueB,
                    roomNumber: "B", 
                    currentPatientName: labelNameB,
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