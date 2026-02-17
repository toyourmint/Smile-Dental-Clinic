import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/screen/data/data_store.dart';

class AddAppointmentDialog extends StatefulWidget {
  final Map<String, String>? initialData;

  const AddAppointmentDialog({super.key, this.initialData});

  @override
  State<AddAppointmentDialog> createState() => _AddAppointmentDialogState();
}

class _AddAppointmentDialogState extends State<AddAppointmentDialog> {
  // Controllers
  final _patientIdController = TextEditingController(); 
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateController = TextEditingController();
  final _noteController = TextEditingController();

  // Variables
  String? _selectedPrefix;
  String? _selectedDoctor;
  String? _selectedTime;
  String? _selectedTreatment;

  // Lists
  final List<String> _prefixes = ['นาย', 'นาง', 'นางสาว'];
  final List<String> _doctors = ['ทพ. สมชาย ใจดี', 'ทพ. หญิง รักษา', 'ทพ. เก่ง เกินไป', 'ทพ. กล้า หาญ'];
  final List<String> _times = ['9.00 น.', '10.00 น.', '11.00 น.', '13.00 น.', '14.00 น.', '15.00 น.', '16.00 น.', '17.00 น.'];
  final List<String> _treatments = ['ตรวจสุขภาพช่องปาก', 'ฟันเทียม', 'รักษารากฟัน/อุดฟัน', 'ฝังรากฟันเทียม', 'ฟันแตก', 'จัดฟัน'];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final data = widget.initialData!;
      
      String rawId = data['id'] ?? "";
      if (rawId.startsWith("SD-")) {
        _patientIdController.text = rawId.substring(3);
      } else {
        _patientIdController.text = rawId;
      }

      List<String> nameParts = (data['name'] ?? "").split(' ');
      if (nameParts.isNotEmpty && _prefixes.contains(nameParts[0])) {
        _selectedPrefix = nameParts[0];
        if (nameParts.length > 1) _firstNameController.text = nameParts[1];
        if (nameParts.length > 2) _lastNameController.text = nameParts.sublist(2).join(' ');
      } else {
        _firstNameController.text = data['name'] ?? "";
      }

      _phoneController.text = data['phone'] == "-" ? "" : data['phone']!;
      if (_doctors.contains(data['doctor'])) _selectedDoctor = data['doctor'];
      _dateController.text = data['date'] == "-" ? "" : data['date']!;
      if (_times.contains(data['time'])) _selectedTime = data['time'];
      if (_treatments.contains(data['treatment'])) _selectedTreatment = data['treatment'];
    }
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF0062E0)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
        // เมื่อเปลี่ยนวัน ให้ล้างเวลาที่เลือกไว้ (เพราะคิวเปลี่ยนไปแล้ว)
        _selectedTime = null; 
      });
    }
  }

  // 💡 ฟังก์ชันเช็คว่าช่วงเวลานี้ในวันที่เลือก มีคนจองไปกี่คนแล้ว
  int _getBookedCount(String timeSlot) {
    if (_dateController.text.isEmpty) return 0; // ถ้ายังไม่เลือกวัน ถือว่าว่างหมด
    
    int count = 0;
    for (var appt in DataStore.allAppointments) {
      // นับเฉพาะคนที่จองในวันที่ตรงกัน และเวลาตรงกัน (และยังไม่ยกเลิก)
      if (appt.date == _dateController.text && 
          appt.time == timeSlot && 
          appt.status != "Cancelled" && 
          appt.status != "Skipped") {
        count++;
      }
    }
    
    // 💡 กรณีเปิดเข้ามาแก้ไขข้อมูลของคนเดิม (ดึงคิวของคนเดิมออกจากการนับ 1 คน จะได้ไม่เต็มเพราะคิวตัวเอง)
    if (widget.initialData != null) {
        if(widget.initialData!['date'] == _dateController.text && widget.initialData!['time'] == timeSlot){
            count--;
        }
    }

    return count;
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.initialData != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 800, // ขยายกล่องให้กว้างขึ้น เพื่อวางปุ่มเวลา
        padding: const EdgeInsets.all(30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // หัวข้อ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? "เลื่อนการนัดหมาย" : "เพิ่มการนัดหมาย", 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(), 
                  ),
                ],
              ),
              const Text("ตารางนัดหมายสำหรับผู้ป่วย", style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 24),

              // แถว 1: รหัสผู้ป่วย & เบอร์
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      "รหัสผู้ป่วย", "", 
                      controller: _patientIdController, 
                      prefixText: "SD-", 
                      isNumber: true, 
                      maxLength: 6,
                      enabled: !isEditing,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      "เบอร์โทรศัพท์", "", 
                      controller: _phoneController, 
                      isNumber: true,
                      enabled: !isEditing,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // แถว 2: ชื่อ-นามสกุล
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: _buildDropdownField("คำนำหน้า", _prefixes, _selectedPrefix, (value) => setState(() => _selectedPrefix = value), enabled: !isEditing),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("ชื่อจริง", "ชื่อ", controller: _firstNameController, enabled: !isEditing)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("นามสกุล", "นามสกุล", controller: _lastNameController, enabled: !isEditing)),
                ],
              ),
              const SizedBox(height: 16),

              // แถว 3: แพทย์, วันที่, และ หัตถการ
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildDropdownField("แพทย์", _doctors, _selectedDoctor, (value) => setState(() => _selectedDoctor = value), enabled: true)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: _buildTextField("วัน / เดือน / ปี", "dd/mm/yyyy", controller: _dateController, icon: Icons.calendar_today_outlined, enabled: true),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDropdownField("หัตถการ", _treatments, _selectedTreatment, (value) => setState(() => _selectedTreatment = value), enabled: true)),
                ],
              ),
              const SizedBox(height: 24),

              // 💡 แถว 4: โซนเลือกเวลา (เปลี่ยนจาก Dropdown เป็นปุ่มกด)
              const Text("เลือกเวลา (รับได้สูงสุด 4 คน/คิว)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              
              if (_dateController.text.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Center(child: Text("กรุณาเลือก 'วัน/เดือน/ปี' ก่อนเพื่อดูคิวว่าง", style: TextStyle(color: Colors.blue))),
                )
              else
                Wrap(
                  spacing: 12, // ระยะห่างแนวนอน
                  runSpacing: 12, // ระยะห่างแนวตั้ง
                  children: _times.map((time) {
                    // 💡 คำนวณหาจำนวนคนจอง
                    int booked = _getBookedCount(time);
                    bool isFull = booked >= 4;
                    bool isSelected = _selectedTime == time;

                    return InkWell(
                      // ถ้าเต็มแล้ว ห้ามกด
                      onTap: isFull ? null : () {
                        setState(() { _selectedTime = time; });
                      },
                      child: Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isFull ? Colors.grey.shade200 : (isSelected ? Colors.blue.shade600 : Colors.white),
                          border: Border.all(color: isFull ? Colors.grey.shade300 : (isSelected ? Colors.blue.shade600 : Colors.blue.shade300)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(time, style: TextStyle(fontWeight: FontWeight.bold, color: isFull ? Colors.grey.shade500 : (isSelected ? Colors.white : Colors.blue.shade800))),
                            const SizedBox(height: 4),
                            // โชว์ว่าจองไปแล้วกี่คน
                            Text(
                              isFull ? "เต็มแล้ว" : "$booked/4 คิว", 
                              style: TextStyle(fontSize: 11, color: isFull ? Colors.red.shade400 : (isSelected ? Colors.blue.shade100 : Colors.grey.shade600))
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 24),

              // แถว 5: บันทึก
              _buildTextField("บันทึกเพิ่มเติม", "-", controller: _noteController, maxLines: 3, enabled: true),
              const SizedBox(height: 30),

              // ปุ่มบันทึก
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("ยกเลิก", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_selectedTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกเวลา'), backgroundColor: Colors.redAccent));
                        return;
                      }

                      String prefix = _selectedPrefix ?? "";
                      String first = _firstNameController.text;
                      String last = _lastNameController.text;
                      String fullName = "$prefix $first $last".trim();
                      if (fullName.isEmpty) fullName = isEditing ? (widget.initialData!['name'] ?? "") : "ผู้ป่วยใหม่";

                      String fullId = "SD-${_patientIdController.text}";
                      if (_patientIdController.text.isEmpty) fullId = isEditing ? (widget.initialData!['id'] ?? "SD-xxxxxx") : "SD-xxxxxx";

                      final Map<String, String> resultData = {
                        "id": fullId, 
                        "name": fullName,
                        "phone": _phoneController.text.isEmpty ? "-" : _phoneController.text,
                        "doctor": _selectedDoctor ?? "-",
                        "date": _dateController.text.isEmpty ? "-" : _dateController.text,
                        "time": _selectedTime!,
                        "treatment": _selectedTreatment ?? "-",
                        "status": isEditing ? (widget.initialData!['status'] ?? "Confirmed") : "Confirmed",
                      };

                      Navigator.of(context).pop(resultData);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0062E0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isEditing ? "บันทึกการเลื่อนนัดหมาย" : "บันทึกการจอง", 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildTextField(String label, String hint, {int maxLines = 1, IconData? icon, TextEditingController? controller, String? prefixText, bool isNumber = false, int? maxLength, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                color: enabled ? Colors.white : Colors.grey.shade100,
              ),
              child: TextField(
                controller: controller,
                enabled: enabled,
                readOnly: !enabled,
                maxLines: maxLines,
                keyboardType: isNumber ? TextInputType.number : TextInputType.text,
                inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
                maxLength: maxLength,
                style: TextStyle(color: enabled ? Colors.black : Colors.grey.shade600),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: hint,
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixText: prefixText,
                  prefixStyle: TextStyle(color: enabled ? Colors.black : Colors.grey.shade600, fontWeight: FontWeight.normal),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: icon != null ? Icon(icon, size: 20, color: Colors.black54) : null,
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: -10,
              child: Container(
                color: enabled ? Colors.white : Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String? currentValue, Function(String?) onChanged, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                color: enabled ? Colors.white : Colors.grey.shade100,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currentValue,
                  isExpanded: true,
                  hint: Text("เลือก", style: TextStyle(color: Colors.grey.shade400)),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                  onChanged: enabled ? onChanged : null,
                  items: items.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(color: enabled ? Colors.black : Colors.grey.shade600)),
                    );
                  }).toList(),
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: -10,
              child: Container(
                color: enabled ? Colors.white : Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}