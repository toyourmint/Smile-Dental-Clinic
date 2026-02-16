import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimePickerModal extends StatefulWidget {
  final List<String> timeSlots;
  final String? initialSelectedTime;
  final List<String>
  disabledSlots; // เพิ่มเพื่อให้กำหนดเวลาที่จองเต็มแล้วได้จากภายนอก

  const TimePickerModal({
    super.key,
    required this.timeSlots,
    this.initialSelectedTime,
    this.disabledSlots = const ["11:00", "15:00"], // ค่าเริ่มต้นตามตัวอย่าง
  });

  @override
  State<TimePickerModal> createState() => _TimePickerModalState();
}

class _TimePickerModalState extends State<TimePickerModal> {
  String? tempSelectedTime;

  @override
  void initState() {
    super.initState();
    tempSelectedTime = widget.initialSelectedTime;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFFE3F2FD),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            "เลือกเวลา",
            style: GoogleFonts.kanit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            // เช็คว่า timeSlots ว่างไหม?
            child: widget.timeSlots.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "ไม่มีเวลาว่างในวันนี้",
                          style: GoogleFonts.kanit(
                            fontSize: 18,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    // โค้ด ListView เดิมของคุณ
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: widget.timeSlots.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final time = widget.timeSlots[index];
                      bool isDisabled = widget.disabledSlots.contains(time);

                      return InkWell(
                        onTap: isDisabled
                            ? null
                            : () {
                                setState(() => tempSelectedTime = time);
                              },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDisabled
                                ? Colors.grey.shade300
                                : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: tempSelectedTime == time
                                ? Border.all(color: Colors.blue, width: 2)
                                : null,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "$time น.",
                                style: GoogleFonts.kanit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: isDisabled
                                      ? Colors.grey
                                      : Colors.black87,
                                ),
                              ),
                              Radio<String>(
                                value: time,
                                groupValue: tempSelectedTime,
                                activeColor: Colors.blue,
                                onChanged: isDisabled
                                    ? null
                                    : (value) {
                                        setState(
                                          () => tempSelectedTime = value,
                                        );
                                      },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: tempSelectedTime == null
                    ? null
                    : () {
                        // ส่งค่ากลับไปยังหน้าที่เรียก
                        Navigator.pop(context, tempSelectedTime);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "เลือก",
                  style: GoogleFonts.kanit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
