import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AddAppointmentDialog extends StatefulWidget {
  final Map<String, dynamic>? initialData;

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
  String? _selectedTreatment;
  String? _selectedTime;
  String? _apiFormattedDate; 
  
  List<dynamic> _availableSlots = [];
  bool _isLoadingSlots = false;
  bool _isSaving = false;
  bool _isSearchingPatient = false; 
  bool _isLoadingDoctors = true;

  // Lists
  final List<String> _prefixes = ['นาย', 'นาง', 'นางสาว', 'ด.ช.', 'ด.ญ.'];
  final List<String> _treatments = [
    'ตรวจสุขภาพช่องปาก', 
    'ฟันเทียม', 
    'รักษารากฟัน/อุดฟัน', 
    'ฝังรากฟันเทียม', 
    'ฟันแตก', 
    'จัดฟัน'
  ];
  List<String> _doctors = []; 

  @override
  void initState() {
    super.initState();
    _fetchDoctors(); 

    // ดักจับการพิมพ์ ถ้ารหัสครบ 6 หลัก ให้ค้นหาชื่ออัตโนมัติ
    _patientIdController.addListener(() {
      if (_patientIdController.text.length == 6) {
        _searchPatient(_patientIdController.text);
      } else if (_patientIdController.text.length < 6 && _firstNameController.text.isNotEmpty) {
        _clearPatientData();
      }
    });
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

  // 💡 1. ดึงรายชื่อหมอ
  Future<void> _fetchDoctors() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/user/doctor'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> doctorList = data['doctors'] ?? [];
        if (mounted) {
          setState(() {
            _doctors = doctorList.map((doc) => doc['doctor_name'].toString()).toList();
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

  // 💡 2. ค้นหาผู้ป่วยแบบออโต้
  Future<void> _searchPatient(String hnNumber) async {
    setState(() => _isSearchingPatient = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? myToken = prefs.getString('my_token');

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/user/getallprofiles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${myToken ?? ""}',
        }
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> profiles = responseData['profiles'] ?? [];
        final targetHn = 'SD-$hnNumber';
        final patient = profiles.firstWhere((p) => p['hn'] == targetHn, orElse: () => null);

        if (patient != null) {
          setState(() {
            _selectedPrefix = patient['title']?.toString();
            if (!_prefixes.contains(_selectedPrefix)) _selectedPrefix = null; 
            _firstNameController.text = patient['first_name']?.toString() ?? '';
            _lastNameController.text = patient['last_name']?.toString() ?? '';
            _phoneController.text = patient['phone']?.toString() ?? '';
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('พบข้อมูลผู้ป่วย'), backgroundColor: Colors.green, duration: Duration(seconds: 1)));
        } else {
          _clearPatientData();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบข้อมูลผู้ป่วยรหัสนี้ในระบบ'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      debugPrint("Search patient error: $e");
    } finally {
      if (mounted) setState(() => _isSearchingPatient = false);
    }
  }

  void _clearPatientData() {
    setState(() {
      _selectedPrefix = null;
      _firstNameController.clear();
      _lastNameController.clear();
      _phoneController.clear();
    });
  }

  // 💡 3. เช็คคิวว่าง
  Future<void> _fetchAvailableSlots(String dateYMD) async {
    setState(() => _isLoadingSlots = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? myToken = prefs.getString('my_token');

      final response = await http.get(
        Uri.parse('http://localhost:3000/api/apm/slots?date=$dateYMD'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${myToken ?? ""}', 
        }
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
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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

  // 💡 4. บันทึก
  Future<void> _saveAppointment() async {
    if (_patientIdController.text.isEmpty || _apiFormattedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกรหัสผู้ป่วย วันที่ และเลือกเวลาให้ครบ'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? myToken = prefs.getString('my_token');

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/apm/apmAdmin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${myToken ?? ""}', 
        },
        body: jsonEncode({
          "hn": "SD-${_patientIdController.text.trim()}",
          "doctor_name": _selectedDoctor ?? "-",
          "appointment_date": _apiFormattedDate,
          "appointment_time": _selectedTime,
          "reason": _selectedTreatment ?? "-",
          "notes": _noteController.text
        }),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
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
                      const Text("เพิ่มการนัดหมาย", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text("กรอกข้อมูลการนัดหมาย (พิมพ์รหัส 6 หลักเพื่อค้นหาชื่อ)", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey), 
                    onPressed: () => Navigator.of(context).pop()
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // --- Row 1: รหัสผู้ป่วย | เบอร์โทรศัพท์ ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      "รหัสผู้ป่วย", 
                      "XXXXXX", 
                      controller: _patientIdController, 
                      prefixText: "SD-", 
                      isNumber: true, 
                      maxLength: 6,
                      isIdField: true, 
                      suffixWidget: _isSearchingPatient 
                        ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))) 
                        : const Icon(Icons.search, color: Colors.black54)
                    )
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      "เบอร์โทรศัพท์", 
                      "080xxxxxxx", 
                      controller: _phoneController, 
                      enabled: false 
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Row 2: คำนำหน้า | ชื่อจริง | นามสกุล ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildDropdownField("คำนำหน้า", _prefixes, _selectedPrefix, null, enabled: false), 
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _buildTextField("ชื่อจริง", "ชื่อ", controller: _firstNameController, enabled: false)
                  ), 
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _buildTextField("นามสกุล", "นามสกุล", controller: _lastNameController, enabled: false)
                  ), 
                ],
              ),
              const SizedBox(height: 20),
              
              // --- Row 3: แพทย์ | วัน/เดือน/ปี ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _isLoadingDoctors 
                      ? const Center(child: CircularProgressIndicator()) 
                      : _buildDropdownField(
                          "แพทย์", 
                          _doctors, 
                          _selectedDoctor, 
                          (v) => setState(() => _selectedDoctor = v)
                        )
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: _buildTextField(
                          "วัน / เดือน / ปี", 
                          "YYYY-MM-DD", 
                          controller: _dateController, 
                          suffixWidget: const Icon(Icons.calendar_month, color: Colors.black54)
                        )
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Row 4: หัตถการ (กว้างเต็มบรรทัด) ---
              _buildDropdownField(
                "หัตถการ", 
                _treatments, 
                _selectedTreatment, 
                (v) => setState(() => _selectedTreatment = v)
              ),
              const SizedBox(height: 24),

              // --- โซนเวลา (Slot แบบตาราง) ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("เวลา", style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    if (_dateController.text.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16), 
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), 
                        child: const Center(child: Text("กรุณาเลือกวันที่ เพื่อดูเวลาที่ว่าง", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)))
                      )
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

                          return InkWell(
                            onTap: isFull ? null : () => setState(() => _selectedTime = timeVal),
                            child: Container(
                              width: 110, 
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isFull ? Colors.grey.shade200 : (isSelected ? const Color(0xFF0062E0) : Colors.white),
                                border: Border.all(color: isFull ? Colors.grey.shade300 : (isSelected ? const Color(0xFF0062E0) : Colors.blue.shade300)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _formatDisplayTime(timeVal), 
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      color: isFull ? Colors.grey.shade500 : (isSelected ? Colors.white : Colors.blue.shade800)
                                    )
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isFull ? "เต็มแล้ว" : "$booked/4 คิว", 
                                    style: TextStyle(
                                      fontSize: 11, 
                                      color: isFull ? Colors.red.shade400 : (isSelected ? Colors.blue.shade100 : Colors.grey.shade600)
                                    )
                                  ),
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
              _buildTextField("บันทึก", "", controller: _noteController, maxLines: 3),
              const SizedBox(height: 30),

              // --- Button บันทึกการจอง ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0062E0), 
                      foregroundColor: Colors.white, 
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    child: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text("บันทึกการจอง", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widget: TextField ---
  Widget _buildTextField(String label, String hint, {TextEditingController? controller, Widget? suffixWidget, bool isNumber = false, int? maxLength, String? prefixText, bool enabled = true, int maxLines = 1, bool isIdField = false}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLength: maxLength,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      style: TextStyle(
        color: isIdField ? Colors.blue.shade800 : (enabled ? Colors.black87 : Colors.grey.shade600), 
        fontWeight: isIdField ? FontWeight.bold : FontWeight.normal
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 15),
        floatingLabelBehavior: FloatingLabelBehavior.always, 
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixText: prefixText,
        counterText: "",
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
        fillColor: isIdField ? Colors.blue.shade50 : (enabled ? Colors.white : const Color(0xFFF4F7F9)), 
        filled: true,
        suffixIcon: suffixWidget,
      ),
    );
  }

  // --- Helper Widget: Dropdown ---
  Widget _buildDropdownField(String label, List<String> items, String? value, Function(String?)? onChanged, {bool enabled = true}) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: enabled ? Colors.black87 : Colors.grey.shade700)))).toList(),
      onChanged: enabled ? onChanged : null,
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 15),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
        fillColor: enabled ? Colors.white : const Color(0xFFF4F7F9),
        filled: true,
      ),
      hint: Text(enabled ? (items.isEmpty ? "กำลังโหลด..." : "เลือก") : "-", style: TextStyle(color: Colors.grey.shade400)),
    );
  }
}