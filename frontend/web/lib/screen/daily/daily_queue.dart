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

  // --- 💡 Logic 1: กดรับคิว (เลือกระบุห้อง และรันคิวแยกห้อง) ---
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
              const SizedBox(height: 32), // เพิ่มระยะห่างจากข้อความ
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // จัดกึ่งกลาง
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, "A"), 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.blue.shade900,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20), // เพิ่มขนาดปุ่ม
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    child: const Text("ห้องตรวจ A", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(width: 40), // 💡 เพิ่มระยะห่างระหว่างปุ่มตรงนี้
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, "B"), 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade100,
                      foregroundColor: Colors.green.shade900,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20), // เพิ่มขนาดปุ่ม
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

    // ถ้ากดพื้นที่ว่างเพื่อปิด หรือไม่ได้เลือกห้อง ให้ยกเลิกการรับคิว
    if (selectedRoom == null) return;

    // 2. ถ้าระบุห้องแล้ว รันคิวแยกตามห้อง
    setState(() {
      int maxQueue = 0;
      
      var patientsWithQueueInRoom = DataStore.allAppointments.where(
        (p) => p.date == todayDate && 
               p.queueNumber != null && 
               p.assignedRoom == selectedRoom
      );
      
      for (var p in patientsWithQueueInRoom) {
        int q = int.tryParse(p.queueNumber!) ?? 0;
        if (q > maxQueue) maxQueue = q;
      }

      patient.queueNumber = "${maxQueue + 1}"; 
      patient.status = "Waiting"; 
      patient.assignedRoom = selectedRoom; 
    });
  }

  // --- Logic 2: เรียกคิวถัดไป ---
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

    List<Map<String, String>> waitingListA = DataStore.allAppointments
        .where((p) => p.date == todayDate && p.status == "Waiting" && p.assignedRoom == "A")
        .map((p) => {"id": p.queueNumber ?? "-", "name": p.name})
        .toList();

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
                      queueNumber: currentPatientRoomA?.queueNumber ?? "-",
                      roomNumber: "A", 
                      currentPatientName: currentPatientRoomA?.name ?? "ว่าง",
                      nextQueues: waitingListA, 
                      onNext: () => _processQueue("A", isSkip: false),
                      onSkip: () => _processQueue("A", isSkip: true),
                    ),
                  ),
                ),
                
                Expanded(
                  child: QueueManagerSection(
                    queueNumber: currentPatientRoomB?.queueNumber ?? "-",
                    roomNumber: "B", 
                    currentPatientName: currentPatientRoomB?.name ?? "ว่าง",
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