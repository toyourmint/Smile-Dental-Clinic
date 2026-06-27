import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/screen/data/data_store.dart';
import 'package:flutter_application_1/screen/auth_service.dart';

/// =========================
/// ENUMS & EXTENSIONS
/// =========================
enum Gender { male, female, other }
enum TreatmentRight { goldCard, government, socialSecurity, selfPay }

extension GenderExt on Gender {
  String get api {
    switch (this) {
      case Gender.male: return 'male'; 
      case Gender.female: return 'female';
      case Gender.other: return 'other';
    }
  }

  String get labelTH {
    switch (this) {
      case Gender.male: return 'ชาย';
      case Gender.female: return 'หญิง';
      case Gender.other: return 'ไม่ระบุ';
    }
  }
}

extension TreatmentRightExt on TreatmentRight {
  String get api {
    switch (this) {
      case TreatmentRight.goldCard: return 'gold_card';
      case TreatmentRight.government: return 'government';
      case TreatmentRight.socialSecurity: return 'social_security';
      case TreatmentRight.selfPay: return 'self_pay';
    }
  }

  String get labelTH {
    switch (this) {
      case TreatmentRight.goldCard: return 'บัตรทอง';
      case TreatmentRight.government: return 'สิทธิข้าราชการ';
      case TreatmentRight.socialSecurity: return 'สิทธิ์ประกันสังคม';
      case TreatmentRight.selfPay: return 'จ่ายเงินเอง';
    }
  }
}

class AddPatientDialog extends StatefulWidget {
  final PatientInfo? existingPatient;
  final String? generatedId;
  final VoidCallback? onPatientAdded; // 💡 รับ Callback มาจากหน้าตาราง

  const AddPatientDialog({
    super.key, 
    this.existingPatient, 
    this.generatedId, 
    this.onPatientAdded 
  });

  @override
  State<AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<AddPatientDialog> {
  late bool _isViewMode;
  bool _isLoading = false;

  final _patientIdCtrl = TextEditingController();
  final _idCardCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  
  final _diseaseCtrl = TextEditingController();
  final _allergyCtrl = TextEditingController();
  final _medicationCtrl = TextEditingController();
  final _historyCtrl = TextEditingController();
  
  final _insuranceCtrl = TextEditingController();
  
  final _addressCtrl = TextEditingController();
  final _subDistrictCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _zipCodeCtrl = TextEditingController();

  String? title;
  Gender? gender;
  TreatmentRight? right;

  final List<String> _prefixes = ['นาย', 'นาง', 'นางสาว'];

  @override
  void initState() {
    super.initState();
    _isViewMode = widget.existingPatient != null;

    if (widget.existingPatient != null) {
      final p = widget.existingPatient!;
      _patientIdCtrl.text = p.patientId;
      _idCardCtrl.text = p.idCard;
      title = _prefixes.contains(p.prefix) ? p.prefix : null;
      _firstNameCtrl.text = p.firstName;
      _lastNameCtrl.text = p.lastName;
      _birthDateCtrl.text = p.birthDate;
      _phoneCtrl.text = p.phone;
      _emailCtrl.text = p.email;
      
      _diseaseCtrl.text = p.disease;
      _allergyCtrl.text = p.allergy;
      _medicationCtrl.text = p.medication;
      _historyCtrl.text = p.history;
      
      _insuranceCtrl.text = p.insuranceLimit;
      
      _addressCtrl.text = p.address;
      _subDistrictCtrl.text = p.subDistrict;
      _districtCtrl.text = p.district;
      _provinceCtrl.text = p.province;
      _zipCodeCtrl.text = p.zipCode;

      if (p.gender == "ชาย") gender = Gender.male;
      else if (p.gender == "หญิง") gender = Gender.female;
      else if (p.gender != "-") gender = Gender.other;

      if (p.right == "บัตรทอง") right = TreatmentRight.goldCard;
      else if (p.right == "สิทธิข้าราชการ") right = TreatmentRight.government;
      else if (p.right == "สิทธ์ประกันสังคม") right = TreatmentRight.socialSecurity;
      else if (p.right == "จ่ายเงินเอง") right = TreatmentRight.selfPay;

    } else {
      _patientIdCtrl.text = widget.generatedId ?? "สร้างอัตโนมัติจากเซิร์ฟเวอร์";
    }
  }

  @override
  void dispose() {
    _patientIdCtrl.dispose(); _idCardCtrl.dispose(); _firstNameCtrl.dispose(); 
    _lastNameCtrl.dispose(); _birthDateCtrl.dispose(); _phoneCtrl.dispose(); 
    _emailCtrl.dispose(); _diseaseCtrl.dispose(); _allergyCtrl.dispose(); 
    _medicationCtrl.dispose(); _historyCtrl.dispose(); _insuranceCtrl.dispose(); 
    _addressCtrl.dispose(); _subDistrictCtrl.dispose(); _districtCtrl.dispose(); 
    _provinceCtrl.dispose(); _zipCodeCtrl.dispose();
    super.dispose();
  }

  // 💡 เพิ่มฟังก์ชันล้างข้อมูล เพื่อเตรียมกรอกคนถัดไป
  void _resetForm() {
    _idCardCtrl.clear();
    _firstNameCtrl.clear();
    _lastNameCtrl.clear();
    _birthDateCtrl.clear();
    _phoneCtrl.clear();
    _emailCtrl.clear();
    _diseaseCtrl.clear();
    _allergyCtrl.clear();
    _medicationCtrl.clear();
    _historyCtrl.clear();
    _addressCtrl.clear();
    _subDistrictCtrl.clear();
    _districtCtrl.clear();
    _provinceCtrl.clear();
    _zipCodeCtrl.clear();
    setState(() {
      title = null;
      gender = null;
      right = null;
      _isLoading = false; 
    });
  }

  Future<void> _pickDate() async {
    if (_isViewMode) return;

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
        _birthDateCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _onRightChanged(TreatmentRight? value) {
    setState(() {
      right = value;
      if (value == TreatmentRight.socialSecurity) {
        _insuranceCtrl.text = '900 บาท';
      } else {
        _insuranceCtrl.text = '-';
      }
    });
  }

  Future<void> _saveToDatabase() async {
  if (_isLoading) return;

  print('>>> existingPatient = ${widget.existingPatient}');
  print('>>> userId = ${widget.existingPatient?.userId}');

  if (_idCardCtrl.text.trim().isEmpty ||
      _firstNameCtrl.text.trim().isEmpty ||
      _lastNameCtrl.text.trim().isEmpty ||
      _phoneCtrl.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('กรุณากรอกข้อมูลที่จำเป็น (*) ให้ครบถ้วน'),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    String? myToken = await AuthService.getValidToken();
    if (myToken == null) {
      if (mounted) AuthService.logout(context);
      return;
    }
    http.Response response;

    if (widget.existingPatient != null) {
      // ✅ โหมดแก้ไข — PUT พร้อม userId จริงจากฐานข้อมูล
      final userId = widget.existingPatient!.userId;
      final url = Uri.parse('http://localhost:3000/api/user/editprofile/$userId');

      response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $myToken',
        },
        body: jsonEncode({
          "hn": widget.existingPatient!.patientId,
          "citizen_id": _idCardCtrl.text.trim(),
          "title": title ?? "",
          "first_name": _firstNameCtrl.text.trim(),
          "last_name": _lastNameCtrl.text.trim(),
          "birth_date": _birthDateCtrl.text.trim(),
          "gender": gender?.api ?? "other",
          "email": _emailCtrl.text.trim(),
          "phone": _phoneCtrl.text.trim(),
          "address_line": _addressCtrl.text.trim(),
          "subdistrict": _subDistrictCtrl.text.trim(),
          "district": _districtCtrl.text.trim(),
          "province": _provinceCtrl.text.trim(),
          "postal_code": _zipCodeCtrl.text.trim(),
          "treatment_right": right?.api ?? "self_pay",
          "allergies": _allergyCtrl.text.trim(),
          "disease": _diseaseCtrl.text.trim(),
          "medicine": _medicationCtrl.text.trim(),
        }),
      );
    } else {
      // ✅ โหมดเพิ่มใหม่ — POST เหมือนเดิม
      final url = Uri.parse('http://localhost:3000/api/auth/addUser');

      response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $myToken',
        },
        body: jsonEncode({
          "citizen_id": _idCardCtrl.text.trim(),
          "title": title ?? "",
          "first_name": _firstNameCtrl.text.trim(),
          "last_name": _lastNameCtrl.text.trim(),
          "birth_date": _birthDateCtrl.text.trim(),
          "gender": gender?.api ?? "other",
          "email": _emailCtrl.text.trim(),
          "phone": _phoneCtrl.text.trim(),
          "address_line": _addressCtrl.text.trim(),
          "subdistrict": _subDistrictCtrl.text.trim(),
          "district": _districtCtrl.text.trim(),
          "province": _provinceCtrl.text.trim(),
          "postal_code": _zipCodeCtrl.text.trim(),
          "rights": right?.api ?? "self_pay",
          "allergies": _allergyCtrl.text.trim(),
          "disease": _diseaseCtrl.text.trim(),
          "medicine": _medicationCtrl.text.trim(),
        }),
      );
    }

    if (!mounted) return;

    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic responseData = jsonDecode(response.body);
      final String hn = (responseData is Map && responseData['hn'] != null)
          ? responseData['hn'].toString()
          : '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingPatient != null
                ? 'บันทึกการแก้ไขสำเร็จ'
                : 'เพิ่มข้อมูลผู้ป่วยสำเร็จ ${hn.isNotEmpty ? "(HN: $hn)" : ""}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.existingPatient != null) {
        // ✅ แก้ไขสำเร็จ → ปิด Dialog แล้วรีเฟรชตาราง
        Navigator.of(context).pop(true);
      } else {
        // ✅ เพิ่มใหม่สำเร็จ → ล้างฟอร์ม รอกรอกคนถัดไป
        _resetForm();
      }

      widget.onPatientAdded?.call();

    } else {
      setState(() => _isLoading = false);
      try {
        final dynamic errorData = jsonDecode(response.body);
        final String errMsg =
            (errorData is Map && errorData['message'] != null)
                ? errorData['message'].toString()
                : 'เกิดข้อผิดพลาด';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), backgroundColor: Colors.redAccent),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${response.statusCode}: เซิร์ฟเวอร์ขัดข้อง'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  } catch (e) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (e.toString().contains('!_debugLocked')) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('การเชื่อมต่อมีปัญหา: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    String dialogTitle = "ลงทะเบียนผู้ป่วยใหม่";
    if (widget.existingPatient != null) {
      dialogTitle = _isViewMode ? "ข้อมูลประจำตัวผู้ป่วย" : "แก้ไขข้อมูลผู้ป่วย";
    }

    bool isEditingExisting = !_isViewMode && widget.existingPatient != null;
    Color saveButtonColor = isEditingExisting ? Colors.green.shade600 : const Color(0xFF0062E0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 💡 เพิ่มปุ่ม X ปิดหน้าต่างไว้มุมขวาบน
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dialogTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(), 
                  ),
                ],
              ),
              if (widget.existingPatient == null)
                const Text("กรอกข้อมูลสำหรับผู้ป่วยใหม่ (ช่องที่มี * จำเป็นต้องกรอก)", style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 24),

              _buildTextField("รหัสผู้ป่วย", "SD-XXXXXX", controller: _patientIdCtrl, enabled: false, isIdField: true),
              const SizedBox(height: 16),

              _buildTextField("เลขบัตรประจำตัวประชาชน", "x-xxxx-xxxxx-xx-x", controller: _idCardCtrl, isNumber: true, maxLength: 13, enabled: !_isViewMode, isRequired: true),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120, 
                    child: _buildDropdownField<String>("คำนำหน้า", _prefixes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), title, (val) => setState(() => title = val), enabled: !_isViewMode, isRequired: true)
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("ชื่อจริง", "ชื่อ", controller: _firstNameCtrl, enabled: !_isViewMode, isRequired: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("นามสกุล", "นามสกุล", controller: _lastNameCtrl, enabled: !_isViewMode, isRequired: true)),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildDropdownField<Gender>("เพศ", Gender.values.map((g) => DropdownMenuItem(value: g, child: Text(g.labelTH))).toList(), gender, (val) => setState(() => gender = val), enabled: !_isViewMode, isRequired: true)
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: _buildTextField("วัน / เดือน / ปีเกิด", "YYYY-MM-DD", controller: _birthDateCtrl, icon: Icons.calendar_today_outlined, enabled: !_isViewMode)
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTextField("เบอร์โทรศัพท์", "08xxxxxxxx", controller: _phoneCtrl, isNumber: true, maxLength: 10, enabled: !_isViewMode, isRequired: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("อีเมล", "name@example.com", controller: _emailCtrl, enabled: !_isViewMode)), 
                ],
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTextField("โรคประจำตัว", "-", controller: _diseaseCtrl, enabled: !_isViewMode)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("ประวัติการแพ้ยา", "-", controller: _allergyCtrl, enabled: !_isViewMode)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("ยาประจำตัว", "-", controller: _medicationCtrl, enabled: !_isViewMode)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField("ประวัติการรักษา", "-", controller: _historyCtrl, enabled: !_isViewMode),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildDropdownField<TreatmentRight>("สิทธิ์การรักษา", TreatmentRight.values.map((r) => DropdownMenuItem(value: r, child: Text(r.labelTH))).toList(), right, _onRightChanged, enabled: !_isViewMode, isRequired: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("วงเงินประกัน", "-", controller: _insuranceCtrl, enabled: false)), 
                ],
              ),
              const SizedBox(height: 16),

              _buildTextField("ที่อยู่", "-", controller: _addressCtrl, enabled: !_isViewMode),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTextField("แขวง / ตำบล", "-", controller: _subDistrictCtrl, enabled: !_isViewMode)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("เขต / อำเภอ", "-", controller: _districtCtrl, enabled: !_isViewMode)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTextField("จังหวัด", "-", controller: _provinceCtrl, enabled: !_isViewMode)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("รหัสไปรษณีย์", "-", controller: _zipCodeCtrl, isNumber: true, maxLength: 5, enabled: !_isViewMode)),
                ],
              ),
              const SizedBox(height: 30),

              // 💡 เพิ่มปุ่มปิด/ยกเลิก ไว้ข้างปุ่มบันทึก
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text("ปิดหน้าต่าง", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () { 
                      if (_isViewMode) {
                        setState(() => _isViewMode = false);
                      } else {
                        _saveToDatabase();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: saveButtonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            _isViewMode 
                              ? "แก้ไขข้อมูลผู้ป่วย" 
                              : (widget.existingPatient != null ? "บันทึกการแก้ไข" : "บันทึกข้อมูลผู้ป่วย"), 
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

  Widget _buildTextField(String label, String hint, {TextEditingController? controller, bool isNumber = false, int? maxLength, IconData? icon, bool enabled = true, bool isIdField = false, bool isRequired = false}) {
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
                color: isIdField ? Colors.blue.shade50 : (enabled ? Colors.white : Colors.grey.shade100),
              ),
              child: TextField(
                controller: controller,
                keyboardType: isNumber ? TextInputType.number : TextInputType.text,
                inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
                maxLength: maxLength,
                enabled: enabled,
                style: TextStyle(
                  color: isIdField ? Colors.blue.shade800 : Colors.black87,
                  fontWeight: isIdField ? FontWeight.bold : FontWeight.normal
                ),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: hint,
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: icon != null ? Icon(icon, size: 20, color: Colors.black54) : null,
                ),
              ),
            ),
            Positioned(
              left: 12, top: -10,
              child: Container(
                color: isIdField ? Colors.blue.shade50 : (enabled ? Colors.white : Colors.grey.shade100),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    if (isRequired)
                      const Text(" *", style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>(String label, List<DropdownMenuItem<T>> items, T? currentValue, Function(T?) onChanged, {bool enabled = true, bool isRequired = false}) {
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
                child: DropdownButton<T>(
                  value: currentValue,
                  isExpanded: true,
                  hint: Text("เลือก", style: TextStyle(color: Colors.grey.shade400)),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                  onChanged: enabled ? onChanged : null, 
                  style: const TextStyle(color: Colors.black87),
                  items: items,
                ),
              ),
            ),
            Positioned(
              left: 12, top: -10,
              child: Container(
                color: enabled ? Colors.white : Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    if (isRequired)
                      const Text(" *", style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}