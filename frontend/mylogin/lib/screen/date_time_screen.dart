import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mylogin/screen/time_picker_modal.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/appointment_service.dart';

class DateTimeSelectionScreen extends StatefulWidget {
  final String serviceName;

  const DateTimeSelectionScreen({super.key, required this.serviceName});

  @override
  State<DateTimeSelectionScreen> createState() =>
      _DateTimeSelectionScreenState();
}

class _DateTimeSelectionScreenState extends State<DateTimeSelectionScreen> {
  // --- Calendar State ---
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // --- Booking State ---
  String? _selectedTime;
  List<String> _timeSlots = []; // เวลาที่ได้จาก Server
  List<String> _disabledSlots = [];

  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    _fetchTimeSlots(_selectedDay!);
  }

  // --- Logic: ดึงเวลาว่างจาก Server ---
  Future<void> _fetchTimeSlots(DateTime date) async {
    setState(() {
      _timeSlots = [];
      _disabledSlots = []; // ล้างค่าเก่า
      _selectedTime = null;
    });

    try {
      // ใช้ Future.wait เพื่อเรียก 2 ฟังก์ชันพร้อมกัน (เวลาทำการ + เวลาที่จองแล้ว)
      final responses = await Future.wait([
        AppointmentService.getAvailableSlots(date), // index 0
        AppointmentService.getBookedSlots(date), // index 1
      ]);

      if (mounted) {
        setState(() {
          _timeSlots = (responses[0]).map((e) => e.toString()).toList();

          // แปลง index 1 (Booked)
          _disabledSlots = (responses[1])
              .map((e) => e.toString())
              .toList();
        });
      }
    } catch (e) {
      print("Error: $e");
      if (mounted);
    }
  }

  // --- Logic: กดจอง ---
  Future<void> _handleBooking() async {
    if (_selectedTime == null || _selectedDay == null) return;

    setState(() => _isBooking = true);

    try {
      final res = await AppointmentService.bookQueue(
        serviceName: widget.serviceName,
        date: _selectedDay!,
        time: _selectedTime!,
      );

      if (mounted) {
        setState(() => _isBooking = false);
        if (res['statusCode'] == 200 || res['statusCode'] == 201) {
          _showSuccessDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${res['body']['message']}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBooking = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "สำเร็จ",
          style: GoogleFonts.kanit(fontWeight: FontWeight.bold),
        ),
        content: Text("จองคิวเรียบร้อยแล้ว", style: GoogleFonts.kanit()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: Text("ตกลง", style: GoogleFonts.kanit()),
          ),
        ],
      ),
    );
  }

  void _showTimePickerModal() async {
    // เรียกใช้ Modal ที่เราแยกไฟล์ไว้
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TimePickerModal(
        timeSlots: _timeSlots,
        initialSelectedTime: _selectedTime,
        disabledSlots: _disabledSlots, // สามารถระบุเวลาที่จองเต็มแล้วได้ที่นี่
      ),
    );

    // ถ้ามีการเลือกเวลา (ไม่ได้กดปิด Modal เปล่าๆ)
    if (result != null) {
      setState(() {
        _selectedTime = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.serviceName,
          style: GoogleFonts.kanit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. ปฏิทิน (Table Calendar)
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  // เรียก API ดึงเวลาใหม่เมื่อเปลี่ยนวัน
                  _fetchTimeSlots(selectedDay);
                }
              },
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: GoogleFonts.kanit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: GoogleFonts.kanit(),
              ),
            ),

            const SizedBox(height: 20),

            // 2. ส่วนแสดงผล "ตารางเวลา"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ตารางเวลา",
                    style: GoogleFonts.kanit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Card แสดงวันที่และเวลาที่เลือก
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF6FF), // สีฟ้าอ่อนมาก
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        // ช่องกดเลือกเวลา
                        GestureDetector(
                          onTap: _showTimePickerModal, // กดแล้วเด้ง Modal
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedDay != null
                                      ? "${DateFormat('dd.MM.yyyy').format(_selectedDay!)}   ${_selectedTime != null ? '$_selectedTime น.' : 'เลือกเวลา'}"
                                      : "กรุณาเลือกวันที่",
                                  style: GoogleFonts.kanit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Icon(
                                  Icons.radio_button_checked,
                                  color: Colors.blue.shade700,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // ส่วนแจ้งเตือน (สีส้ม)
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade300,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.notifications_active,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "แจ้งเตือน",
                                    style: GoogleFonts.kanit(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "ก่อน 1 วันนัดหมาย",
                                    style: GoogleFonts.kanit(
                                      color: Colors.blue,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 3. ปุ่มยืนยัน
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (_selectedTime == null || _isBooking)
                      ? null
                      : _handleBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF), // สีน้ำเงินเข้ม
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isBooking
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "ยืนยันการจอง",
                          style: GoogleFonts.kanit(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
