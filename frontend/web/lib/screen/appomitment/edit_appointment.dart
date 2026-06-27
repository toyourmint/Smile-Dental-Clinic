import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/screen/auth_service.dart';

class EditAppointmentDialog extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const EditAppointmentDialog({super.key, required this.initialData});

  @override
  State<EditAppointmentDialog> createState() => _EditAppointmentDialogState();
}

class _EditAppointmentDialogState extends State<EditAppointmentDialog> {
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
  String? _selectedTreatment;
  String? _selectedTime;
  String? _apiFormattedDate; 
  
  List<dynamic> _availableSlots = [];
  bool _isLoadingSlots = false;
  bool _isSaving = false;
  bool _isLoadingDoctors = true;

  // Lists
  final List<String> _prefixes = ['นาย', 'นาง', 'นางสาว', 'ด.ช.', 'ด.ญ.'];
  final List<String> _treatments = ['ตรวจสุขภาพช่องปาก', 'ฟันเทียม', 'รักษารากฟัน/อุดฟัน', 'ฝังรากฟันเทียม', 'จัดฟัน', 'ถอนฟัน', 'ขูดหินปูน'];
  List<String> _doctors = []; 

  @override
  void initState() {
    super.initState();
    _fetchDoctors(); 
    _initializeData();
  }

  // 💡 โหลดข้อมูลเก่ามาใส่ในฟอร์ม
  void _initializeData() {
    final data = widget.initialData;
    
    // ข้อมูลผู้ป่วย (ล็อกห้ามแก้)
    _patientIdController.text = (data['hn'] ?? "").replaceAll("SD-", "");
    _firstNameController.text = data['first_name'] ?? "";
    _lastNameController.text = data['last_name'] ?? "";
    _phoneController.text = data['phone'] ?? "";
    
    // จัดการคำนำหน้า (ถ้ามีอยู่ใน list)
    if (data['title'] != null && _prefixes.contains(data['title'])) {
      _selectedPrefix = data['title'];
    }

    // จัดการหัตถการและแพทย์
    _selectedTreatment = data['reason'];
    if (!_treatments.contains(_selectedTreatment)) _selectedTreatment = null;

    String docName = data['doctor_name'] ?? "";
    if (docName != "-" && docName.isNotEmpty) {
      _selectedDoctor = docName;
    }

    // จัดการ Note
    _noteController.text = data['notes'] ?? "";

    // จัดการวันที่และเวลา
    if (data['appointment_date'] != null) {
      try {
        DateTime dt = DateTime.parse(data['appointment_date'].toString().split('T')[0]);
        _dateController.text = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
        _apiFormattedDate = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
        
        _selectedTime = data['appointment_time'];
        _fetchAvailableSlots(_apiFormattedDate!);
      } catch (e) {
        debugPrint("Date parse error: $e");
      }
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

  Future<void> _fetchDoctors() async {
    try {
      String? myToken = await AuthService.getValidToken();
      if (myToken == null) {
        if (mounted) AuthService.logout(context);
        return;
      }
      final response = await http.get(Uri.parse('http://localhost:3000/api/user/doctor'), headers: { 'Content-Type': 'application/json',
        'Authorization': 'Bearer $myToken'
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> doctorList = data['doctors'] ?? [];
        if (mounted) {
          setState(() {
            _doctors = doctorList.map((doc) => doc['doctor_name'].toString()).toList();
            // เช็คว่าหมอเดิมมีอยู่ใน list ไหม ถ้าไม่มีให้เพิ่มเข้าไปชั่วคราว
            if (_selectedDoctor != null && !_doctors.contains(_selectedDoctor)) {
               _doctors.add(_selectedDoctor!); 
            }
            _isLoadingDoctors = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingDoctors = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDoctors = false);
    }
  }

  Future<void> _fetchAvailableSlots(String dateYMD) async {
    setState(() => _isLoadingSlots = true);
    try {
      String? myToken = await AuthService.getValidToken();
      if (myToken == null) {
        if (mounted) AuthService.logout(context);
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/apm/slots?date=$dateYMD'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $myToken'}
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) setState(() => _availableSlots = data['slots']);
      }
    } catch (e) {
      debugPrint("Fetch slots error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

  Future<void> _pickDate() async {
    DateTime initialDate = DateTime.now();
    if (_apiFormattedDate != null) {
      try { initialDate = DateTime.parse(_apiFormattedDate!); } catch(e){}
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF0062E0))), 
        child: child!
      ),
    );
    
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
        _apiFormattedDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        _selectedTime = null; 
      });
      _fetchAvailableSlots(_apiFormattedDate!); 
    }
  }

  // 💡 ยิง API แก้ไขข้อมูล
  Future<void> _saveEdit() async {
    if (_apiFormattedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาระบุวันที่และเวลาให้ครบ'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);
    try {
      String? myToken = await AuthService.getValidToken();
      if (myToken == null) {
        if (mounted) AuthService.logout(context);
        return;
      }

      final aptId = widget.initialData['apt_id'];

      final response = await http.put(
        Uri.parse('http://localhost:3000/api/apm/edit/$aptId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $myToken', 
        },
        body: jsonEncode({
          "doctor_name": _selectedDoctor ?? "-",
          "appointment_date": _apiFormattedDate,
          "appointment_time": _selectedTime,
          "reason": _selectedTreatment ?? "-",
          "notes": _noteController.text
        }),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'แก้ไขสำเร็จ'), backgroundColor: Colors.green));
        Navigator.of(context).pop("success"); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'เกิดข้อผิดพลาด'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDisplayTime(String apiTime) {
    if (apiTime.startsWith('09')) return '9.00 น.';
    return '${apiTime.substring(0,2)}.00 น.';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 800, 
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("แก้ไขการนัดหมาย", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text("แก้ไขรายละเอียดการนัดหมายผู้ป่วย", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey), 
                    onPressed: () => Navigator.of(context).pop()
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // --- Row 1: รหัสผู้ป่วย | เบอร์โทรศัพท์ (ล็อก) ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField("รหัสผู้ป่วย", "", controller: _patientIdController, prefixText: "SD-", enabled: false, isIdField: true)
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField("เบอร์โทรศัพท์", "", controller: _phoneController, enabled: false),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Row 2: คำนำหน้า | ชื่อจริง | นามสกุล (ล็อก) ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildDropdownField("คำนำหน้า", _prefixes, _selectedPrefix, null, enabled: false)), 
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: _buildTextField("ชื่อจริง", "", controller: _firstNameController, enabled: false)), 
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: _buildTextField("นามสกุล", "", controller: _lastNameController, enabled: false)), 
                ],
              ),
              const SizedBox(height: 20),
              
              // --- Row 3: แพทย์ | วัน/เดือน/ปี (แก้ได้) ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _isLoadingDoctors 
                      ? const Center(child: CircularProgressIndicator()) 
                      : _buildDropdownField("แพทย์", _doctors, _selectedDoctor, (v) => setState(() => _selectedDoctor = v))
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: _buildTextField("วัน / เดือน / ปี", "YYYY-MM-DD", controller: _dateController, suffixWidget: const Icon(Icons.calendar_month, color: Colors.black54))
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Row 4: หัตถการ (แก้ได้) ---
              _buildDropdownField("หัตถการ", _treatments, _selectedTreatment, (v) => setState(() => _selectedTreatment = v)),
              const SizedBox(height: 24),

              // --- โซนเวลา ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("เวลา", style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    if (_dateController.text.isEmpty)
                      Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: const Center(child: Text("กรุณาเลือกวันที่ เพื่อดูเวลาที่ว่าง", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))))
                    else if (_isLoadingSlots)
                      const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                    else
                      Wrap(
                        spacing: 12, 
                        runSpacing: 12,
                        children: _availableSlots.map((slot) {
                          String timeVal = slot['time'];
                          bool isFull = slot['isFull'];
                          int booked = slot['bookedCount'];
                          bool isSelected = _selectedTime == timeVal;

                          // 💡 อนุญาตให้เลือกเวลาเดิมของตัวเองได้แม้จะขึ้นว่าเต็ม
                          bool isOriginalTime = (timeVal == widget.initialData['appointment_time'] && _apiFormattedDate == widget.initialData['appointment_date'].toString().split('T')[0]);
                          bool canSelect = !isFull || isOriginalTime;

                          return InkWell(
                            onTap: canSelect ? () => setState(() => _selectedTime = timeVal) : null,
                            child: Container(
                              width: 110, 
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !canSelect ? Colors.grey.shade200 : (isSelected ? const Color(0xFF0062E0) : Colors.white),
                                border: Border.all(color: !canSelect ? Colors.grey.shade300 : (isSelected ? const Color(0xFF0062E0) : Colors.blue.shade300)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(_formatDisplayTime(timeVal), style: TextStyle(fontWeight: FontWeight.bold, color: !canSelect ? Colors.grey.shade500 : (isSelected ? Colors.white : Colors.blue.shade800))),
                                  const SizedBox(height: 4),
                                  Text(!canSelect ? "เต็มแล้ว" : (isOriginalTime ? "เวลาเดิม" : "$booked/4 คิว"), style: TextStyle(fontSize: 11, color: !canSelect ? Colors.red.shade400 : (isSelected ? Colors.blue.shade100 : Colors.grey.shade600))),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              
              // --- Row 5: บันทึกเพิ่มเติม ---
              _buildTextField("บันทึก", "เพิ่มหมายเหตุ...", controller: _noteController, maxLines: 3),
              const SizedBox(height: 30),

              // --- Button ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveEdit,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0062E0), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("บันทึกการแก้ไข", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {TextEditingController? controller, Widget? suffixWidget, String? prefixText, bool enabled = true, int maxLines = 1, bool isIdField = false}) {
    return TextField(
      controller: controller, enabled: enabled, maxLines: maxLines,
      style: TextStyle(color: enabled ? Colors.black87 : Colors.grey.shade600, fontWeight: isIdField ? FontWeight.bold : FontWeight.normal),
      decoration: InputDecoration(
        labelText: label, labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 15), floatingLabelBehavior: FloatingLabelBehavior.always, 
        hintText: hint, prefixText: prefixText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
        fillColor: enabled ? Colors.white : const Color(0xFFF4F7F9), filled: true, suffixIcon: suffixWidget,
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String? value, Function(String?)? onChanged, {bool enabled = true}) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: enabled ? Colors.black87 : Colors.grey.shade700)))).toList(),
      onChanged: enabled ? onChanged : null,
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
      decoration: InputDecoration(
        labelText: label, labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 15), floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
        fillColor: enabled ? Colors.white : const Color(0xFFF4F7F9), filled: true,
      ),
      hint: Text(enabled ? "เลือก" : "-", style: TextStyle(color: Colors.grey.shade400)),
    );
  }
}