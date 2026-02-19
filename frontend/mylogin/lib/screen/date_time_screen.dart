import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mylogin/screen/time_picker_modal.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/appointment_service.dart';

class DateTimeSelectionScreen extends StatefulWidget {
  final String serviceName;
  final String? appointmentId; // ถ้ามี = เลื่อนนัด

  const DateTimeSelectionScreen({
    super.key,
    required this.serviceName,
    this.appointmentId,
  });

  @override
  State<DateTimeSelectionScreen> createState() =>
      _DateTimeSelectionScreenState();
}

class _DateTimeSelectionScreenState extends State<DateTimeSelectionScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String? _selectedTime;
  List<String> _timeSlots = [];
  List<String> _disabledSlots = [];

  bool _isBooking = false;
  bool _isLoadingSlots = true;

  bool get isReschedule => widget.appointmentId != null;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchTimeSlots(_selectedDay!);
  }

  /// โหลดเวลาว่าง
  Future<void> _fetchTimeSlots(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _selectedTime = null;
      _timeSlots.clear();
      _disabledSlots.clear();
    });

    try {
      final slots = await AppointmentService.getAvailableSlots(date);

      if (!mounted) return;

      setState(() {
        _timeSlots = slots.map((e) => e.time.substring(0, 5)).toList();

        _disabledSlots = slots
            .where((e) => e.isFull)
            .map((e) => e.time.substring(0, 5))
            .toList();

        _isLoadingSlots = false;
      });
    } catch (e) {
      debugPrint("โหลดช่วงเวลาล้มเหลว: $e");
      if (!mounted) return;
      setState(() => _isLoadingSlots = false);
    }
  }

  /// จอง / เลื่อนนัด
  Future<void> _handleBooking() async {
    if (_selectedTime == null || _selectedDay == null) return;

    setState(() => _isBooking = true);

    final date = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    final time = "$_selectedTime:00";

    bool success = false;

    try {
      if (isReschedule) {
        success = await AppointmentService.rescheduleAppointment(
          id: widget.appointmentId!,
          date: date,
          time: time,
        );
      } else {
        success = await AppointmentService.bookAppointment(
          date: date,
          time: time,
          reason: widget.serviceName,
        );
      }

      if (!mounted) return;
      setState(() => _isBooking = false);

      if (success) {
        _showSuccessDialog();
      } else {
        _showError("ไม่สามารถบันทึกข้อมูลได้");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBooking = false);
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          isReschedule ? "เลื่อนนัดสำเร็จ" : "จองคิวสำเร็จ",
          style: GoogleFonts.kanit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isReschedule
              ? "เปลี่ยนเวลานัดเรียบร้อยแล้ว"
              : "จองคิวเรียบร้อยแล้ว",
          style: GoogleFonts.kanit(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: Text("ตกลง", style: GoogleFonts.kanit()),
          )
        ],
      ),
    );
  }

  /// modal เลือกเวลา
  void _showTimePickerModal() async {
    if (_isLoadingSlots) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TimePickerModal(
        timeSlots: _timeSlots,
        initialSelectedTime: _selectedTime,
        disabledSlots: _disabledSlots,
      ),
    );

    if (result != null) {
      setState(() => _selectedTime = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _selectedDay == null
        ? "กรุณาเลือกวันที่"
        : DateFormat('dd MMM yyyy').format(_selectedDay!);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(
          isReschedule
              ? "เลื่อนนัด • ${widget.serviceName}"
              : widget.serviceName,
          style: GoogleFonts.kanit(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// 📅 Calendar
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _fetchTimeSlots(selectedDay);
              },
            ),

            const SizedBox(height: 20),

            /// ⏰ เลือกเวลา
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: _showTimePickerModal,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$dateText   ${_selectedTime ?? 'เลือกเวลา'}",
                        style: GoogleFonts.kanit(
                            fontSize: 16,
                            fontWeight: FontWeight.w500),
                      ),
                      _isLoadingSlots
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.access_time,
                              color: Colors.blue.shade700),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// 🔵 ปุ่มยืนยัน
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
                    backgroundColor: const Color(0xFF0066FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isBooking
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isReschedule
                              ? "ยืนยันการเลื่อนนัด"
                              : "ยืนยันการจอง",
                          style: GoogleFonts.kanit(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
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
