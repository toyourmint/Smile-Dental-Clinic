import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/daily/daily_table.dart';
import 'package:flutter_application_1/screen/daily/queue_manage.dart';
import 'package:flutter_application_1/screen/data/data_store.dart';

class DailyQueueScreen extends StatefulWidget {
  const DailyQueueScreen({super.key});

  @override
  State<DailyQueueScreen> createState() => _DailyQueueScreenState();
}

class _DailyQueueScreenState extends State<DailyQueueScreen> {
  late String todayDate;

  AppointmentModel? get currentPatientRoomA => _getPatientInRoom("A");
  AppointmentModel? get currentPatientRoomB => _getPatientInRoom("B");

  @override
  void initState() {
    super.initState();
    _initializeTodayDate();
  }

  void _initializeTodayDate() {
    DateTime now = DateTime.now();
    String day = now.day.toString().padLeft(2, '0');
    String month = now.month.toString().padLeft(2, '0');
    int year = now.year;
    
    setState(() {
      todayDate = "$day/$month/$year";
    });
  }

  AppointmentModel? _getPatientInRoom(String room) {
    try {
      return DataStore.allAppointments.firstWhere(
        (p) => p.date == todayDate && p.status == "InQueue" && p.assignedRoom == room
      );
    } catch (e) {
      return null;
    }
  }

  // --- Logic 1: กดรับคิว (เลือกระบุห้อง และรันคิวแยกห้อง) ---
  void _onReceiveQueue(AppointmentModel patient) async {
    // 1. โชว์หน้าต่าง Dialog ให้เลือกห้องก่อน
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, "A"), 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.blue.shade900,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    child: const Text("ห้องตรวจ A", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, "B"), 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade100,
                      foregroundColor: Colors.green.shade900,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    child: const Text("ห้องตรวจ B", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        );
      }
    );

    // ถ้ากดพื้นที่ว่างเพื่อปิด หรือไม่ได้เลือกห้อง ให้ยกเลิกการรับคิว
    if (selectedRoom == null) return;

    // 2. ถ้าระบุห้องแล้ว รันคิวแยกตามห้อง
    setState(() {
      int maxQueue = 0;
      
      // กรองหาคิวเฉพาะของ "ห้องที่เพิ่งเลือก (selectedRoom)" เท่านั้น
      var patientsWithQueueInRoom = DataStore.allAppointments.where(
        (p) => p.date == todayDate && 
               p.queueNumber != null && 
               p.assignedRoom == selectedRoom 
      );
      
      for (var p in patientsWithQueueInRoom) {
        int q = int.tryParse(p.queueNumber!) ?? 0;
        if (q > maxQueue) maxQueue = q;
      }

      patient.queueNumber = "${maxQueue + 1}"; // บวก 1 จากคิวล่าสุดของห้องนั้น
      patient.status = "Waiting"; 
      patient.assignedRoom = selectedRoom; 
    });
  }

  // --- Logic 2: เรียกคิวถัดไป (ดึงเฉพาะคนที่รอห้องตัวเอง) ---
  void _processQueue(String roomName, {required bool isSkip}) {
    setState(() {
      AppointmentModel? current = _getPatientInRoom(roomName);
      if (current != null) {
        current.status = isSkip ? "Skipped" : "Done";
      }

      try {
        var nextPerson = DataStore.allAppointments.firstWhere(
          (p) => p.date == todayDate && p.status == "Waiting" && p.assignedRoom == roomName
        );
        
        nextPerson.status = "InQueue"; 
      } catch (e) {
        // ไม่มีคนรอในห้องนี้แล้ว
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<AppointmentModel> todayPatients = DataStore.allAppointments
        .where((p) => p.date == todayDate)
        .toList();

    // แยกคิวรอของห้อง A
    List<Map<String, String>> waitingListA = DataStore.allAppointments
        .where((p) => p.date == todayDate && p.status == "Waiting" && p.assignedRoom == "A")
        .map((p) => {"id": p.queueNumber ?? "-", "name": p.name})
        .toList();

    // แยกคิวรอของห้อง B
    List<Map<String, String>> waitingListB = DataStore.allAppointments
        .where((p) => p.date == todayDate && p.status == "Waiting" && p.assignedRoom == "B")
        .map((p) => {"id": p.queueNumber ?? "-", "name": p.name})
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: DailyPatientTable(
              patients: todayPatients, 
              onAddToQueue: (index) {
                _onReceiveQueue(todayPatients[index]);
              },
            ),
          ),

          // ส่วนขวา: จัดการคิว
          Container(
            width: 400,
            // เอาสีพื้นหลังรวมออก เพื่อให้เห็นช่องว่าง
            // color: const Color(0xFFEAF6FF), 
            padding: const EdgeInsets.only(left: 20), // เพิ่มระยะห่างจากตารางซ้ายมือเล็กน้อย
            child: Column(
              children: [
                // --- ห้องตรวจ A ---
                Expanded(
                  child: Container(
                    // ใส่สีพื้นหลังแยกให้แต่ละกล่อง
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF6FF),
                      borderRadius: BorderRadius.circular(16) // เพิ่มความโค้งมนให้ดูแยกส่วน
                    ),
                    // เอาเส้นขอบออก เพราะมีช่องว่างแล้ว
                    // decoration: const BoxDecoration(
                    //   border: Border(bottom: BorderSide(color: Colors.white, width: 2))
                    // ),
                    child: QueueManagerSection(
                      queueNumber: currentPatientRoomA?.queueNumber ?? "-",
                      roomNumber: "A", 
                      currentPatientName: currentPatientRoomA?.name ?? "ว่าง",
                      nextQueues: waitingListA, 
                      onNext: () => _processQueue("A", isSkip: false),
                      onSkip: () => _processQueue("A", isSkip: true),
                    ),
                  ),
                ),
                
                // 💡 เพิ่มช่องว่างระหว่างห้อง A และ B ตรงนี้
                const SizedBox(height: 20), 

                // --- ห้องตรวจ B ---
                Expanded(
                  child: Container(
                    // ใส่สีพื้นหลังแยกให้แต่ละกล่อง
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF6FF),
                      borderRadius: BorderRadius.circular(16) // เพิ่มความโค้งมนให้ดูแยกส่วน
                    ),
                    child: QueueManagerSection(
                      queueNumber: currentPatientRoomB?.queueNumber ?? "-",
                      roomNumber: "B", 
                      currentPatientName: currentPatientRoomB?.name ?? "ว่าง",
                      nextQueues: waitingListB, 
                      onNext: () => _processQueue("B", isSkip: false),
                      onSkip: () => _processQueue("B", isSkip: true),
                    ),
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