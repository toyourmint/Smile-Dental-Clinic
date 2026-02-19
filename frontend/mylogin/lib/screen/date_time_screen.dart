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
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String? _selectedTime;
  List<String> _timeSlots = [];
  List<String> _disabledSlots = [];

  bool _isBooking = false;
  bool _isLoadingSlots = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchTimeSlots(_selectedDay!);
  }

  /// 🔹 โหลดเวลาว่างจาก server
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
        _timeSlots =
            slots.map((e) => e.time.substring(0, 5)).toList();

        _disabledSlots = slots
            .where((e) => e.isFull)
            .map((e) => e.time.substring(0, 5))
            .toList();

        _isLoadingSlots = false;
      });
    } catch (e) {
      print("โหลดช่วงเวลาล้มเหลว: $e");
      if (!mounted) return;
      setState(() => _isLoadingSlots = false);
    }
  }

  /// 🔹 กดจองคิว
  Future<void> _handleBooking() async {
    if (_selectedTime == null || _selectedDay == null) return;

    setState(() => _isBooking = true);

    try {
      final success = await AppointmentService.bookAppointment(
        date: DateFormat('yyyy-MM-dd').format(_selectedDay!),
        time: "$_selectedTime:00",
        reason: widget.serviceName,
      );

      if (!mounted) return;
      setState(() => _isBooking = false);

      if (success) {
        _showSuccessDialog();
      } else {
        _showError("ไม่สามารถจองคิวได้");
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
        title: Text("สำเร็จ",
            style: GoogleFonts.kanit(fontWeight: FontWeight.bold)),
        content: Text("จองคิวเรียบร้อยแล้ว",
            style: GoogleFonts.kanit()),
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

  /// 🔹 เปิด modal เลือกเวลา
  void _showTimePickerModal() async {
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
        : DateFormat('dd.MM.yyyy').format(_selectedDay!);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(widget.serviceName,
            style: GoogleFonts.kanit(
                color: Colors.black,
                fontWeight: FontWeight.bold)),
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
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) =>
                  isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _fetchTimeSlots(selectedDay);
                }
              },
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: GoogleFonts.kanit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle),
                todayDecoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: GoogleFonts.kanit(),
              ),
            ),

            const SizedBox(height: 20),

            /// ตารางเวลา
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ตารางเวลา",
                      style: GoogleFonts.kanit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  GestureDetector(
                    onTap: _isLoadingSlots ? null : _showTimePickerModal,
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
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : Icon(Icons.access_time,
                                  color: Colors.blue.shade700),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// ปุ่มยืนยัน
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
                      : Text("ยืนยันการจอง",
                          style: GoogleFonts.kanit(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
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
