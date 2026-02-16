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
  // วันที่ปัจจุบัน
  late String todayDate;

  // ใช้ Getter ช่วยดึงข้อมูลสดๆ เสมอ (ลดการประกาศตัวแปรซ้ำซ้อน)
  // จะไปเรียกฟังก์ชัน _getPatientInRoom เพื่อหาว่าใครอยู่ในห้อง A หรือ B
  AppointmentModel? get currentPatientRoomA => _getPatientInRoom("A");
  AppointmentModel? get currentPatientRoomB => _getPatientInRoom("B");

  @override
  void initState() {
    super.initState();
    _initializeTodayDate();
  }

  // --- 1. ฟังก์ชันหาวันที่ปัจจุบัน ---
  void _initializeTodayDate() {
    DateTime now = DateTime.now();
    // Format: dd/MM/yyyy (เช่น 14/02/2026)
    String day = now.day.toString().padLeft(2, '0');
    String month = now.month.toString().padLeft(2, '0');
    int year = now.year;
    
    setState(() {
      todayDate = "$day/$month/$year";
    });
  }

  // --- Helper: ฟังก์ชันช่วยหาคนในห้อง (ลดโค้ดซ้ำ) ---
  AppointmentModel? _getPatientInRoom(String room) {
    try {
      return DataStore.allAppointments.firstWhere(
        (p) => p.date == todayDate && p.status == "InQueue" && p.assignedRoom == room
      );
    } catch (e) {
      return null;
    }
  }

  // --- Logic 1: กดรับคิว (แก้บั๊กเลขซ้ำด้วยสูตร Max + 1) ---
  void _onReceiveQueue(AppointmentModel patient) {
    setState(() {
      int maxQueue = 0;
      
      // 1. วนลูปหาเลขคิวที่ "มากที่สุด" ในวันนี้
      var patientsWithQueue = DataStore.allAppointments
          .where((p) => p.date == todayDate && p.queueNumber != null);
      
      for (var p in patientsWithQueue) {
        int q = int.tryParse(p.queueNumber!) ?? 0;
        if (q > maxQueue) maxQueue = q;
      }

      // 2. สร้างเลขคิวใหม่ = เลขมากสุด + 1 (รับรองไม่ซ้ำแน่นอน)
      patient.queueNumber = "${maxQueue + 1}";
      patient.status = "Waiting"; // เปลี่ยนสถานะเป็นรอเรียก
    });
  }

  // --- Logic 2: จัดการคิว (รวม Next และ Skip ไว้ในที่เดียว) ---
  // roomName: "A" หรือ "B"
  // isSkip: true = ข้าม, false = เรียกคิวถัดไป
  void _processQueue(String roomName, {required bool isSkip}) {
    setState(() {
      // 1. จัดการคนเก่าในห้อง (ถ้ามี)
      AppointmentModel? current = _getPatientInRoom(roomName);
      if (current != null) {
        // ถ้ากดข้าม -> สถานะ Skipped (แสดงเป็น "ข้าม" ใน Daily, "ยกเลิก" ใน Appointment)
        // ถ้ากดถัดไป -> สถานะ Done
        current.status = isSkip ? "Skipped" : "Done";
      }

      // 2. เรียกคนใหม่เข้าห้อง (ดึงจากคนที่รออยู่)
      try {
        var nextPerson = DataStore.allAppointments.firstWhere(
          (p) => p.date == todayDate && p.status == "Waiting"
        );
        
        nextPerson.status = "InQueue"; // เข้าห้องตรวจ
        nextPerson.assignedRoom = roomName; // ระบุห้อง
      } catch (e) {
        // ไม่มีคนรอแล้ว (ห้องว่าง) -> ระบบจะรู้เองว่า current เป็น null
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // กรอง 1: รายชื่อผู้ป่วยทั้งหมดของ "วันนี้" (แสดงตารางซ้าย)
    List<AppointmentModel> todayPatients = DataStore.allAppointments
        .where((p) => p.date == todayDate)
        .toList();

    // กรอง 2: รายชื่อคนรอคิว (Waiting List) ใช้ร่วมกันทั้ง 2 ห้อง
    List<Map<String, String>> waitingList = DataStore.allAppointments
        .where((p) => p.date == todayDate && p.status == "Waiting")
        .map((p) => {
              "id": p.queueNumber ?? "-", 
              "name": p.name
            })
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ส่วนซ้าย: ตารางรายชื่อผู้ป่วย ---
          Expanded(
            flex: 3,
            child: DailyPatientTable(
              patients: todayPatients, 
              onAddToQueue: (index) {
                // ส่ง object ผู้ป่วยไปสร้างเลขคิว
                _onReceiveQueue(todayPatients[index]);
              },
            ),
          ),

          // --- ส่วนขวา: แผงควบคุมคิว (Queue Manager) ---
          Container(
            width: 400,
            color: const Color(0xFFEAF6FF), // พื้นหลังสีฟ้าอ่อน
            child: Column(
              children: [
                // --- ห้องตรวจ A (ครึ่งบน) ---
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white, width: 2))
                    ),
                    child: QueueManagerSection(
                      queueNumber: currentPatientRoomA?.queueNumber ?? "-",
                      roomNumber: "A", 
                      currentPatientName: currentPatientRoomA?.name ?? "ว่าง",
                      nextQueues: waitingList,
                      // เรียกใช้ฟังก์ชันกลาง
                      onNext: () => _processQueue("A", isSkip: false),
                      onSkip: () => _processQueue("A", isSkip: true),
                    ),
                  ),
                ),
                
                // --- ห้องตรวจ B (ครึ่งล่าง) ---
                Expanded(
                  child: QueueManagerSection(
                    queueNumber: currentPatientRoomB?.queueNumber ?? "-",
                    roomNumber: "B", 
                    currentPatientName: currentPatientRoomB?.name ?? "ว่าง",
                    nextQueues: waitingList,
                    // เรียกใช้ฟังก์ชันกลาง
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