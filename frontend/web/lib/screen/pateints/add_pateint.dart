import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/screen/data/data_store.dart'; 

class AddPatientDialog extends StatefulWidget {
  final PatientInfo? existingPatient;
  final String? generatedId;

  const AddPatientDialog({super.key, this.existingPatient, this.generatedId});

  @override
  State<AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<AddPatientDialog> {
  late bool _isViewMode;

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

  String? _selectedPrefix;
  String? _selectedGender;
  String? _selectedRight;

  final List<String> _prefixes = ['นาย', 'นาง', 'นางสาว'];
  final List<String> _genders = ['ชาย', 'หญิง'];
  final List<String> _rights = ['บัตรทอง', 'สิทธ์ประกันสังคม', 'สิทธิข้าราชการ'];

  @override
  void initState() {
    super.initState();
    _isViewMode = widget.existingPatient != null;

    if (widget.existingPatient != null) {
      final p = widget.existingPatient!;
      _patientIdCtrl.text = p.patientId;
      _idCardCtrl.text = p.idCard;
      _selectedPrefix = _prefixes.contains(p.prefix) ? p.prefix : null;
      _firstNameCtrl.text = p.firstName;
      _lastNameCtrl.text = p.lastName;
      _selectedGender = _genders.contains(p.gender) ? p.gender : null;
      _birthDateCtrl.text = p.birthDate;
      _phoneCtrl.text = p.phone;
      _emailCtrl.text = p.email;
      
      _diseaseCtrl.text = p.disease;
      _allergyCtrl.text = p.allergy;
      _medicationCtrl.text = p.medication;
      _historyCtrl.text = p.history;
      
      _selectedRight = _rights.contains(p.right) ? p.right : null;
      _insuranceCtrl.text = p.insuranceLimit;
      
      _addressCtrl.text = p.address;
      _subDistrictCtrl.text = p.subDistrict;
      _districtCtrl.text = p.district;
      _provinceCtrl.text = p.province;
      _zipCodeCtrl.text = p.zipCode;
    } else {
      _patientIdCtrl.text = widget.generatedId ?? "";
    }
  }

  @override
  void dispose() {
    _patientIdCtrl.dispose();
    _idCardCtrl.dispose(); _firstNameCtrl.dispose(); _lastNameCtrl.dispose();
    _birthDateCtrl.dispose(); _phoneCtrl.dispose(); _emailCtrl.dispose();
    _diseaseCtrl.dispose(); _allergyCtrl.dispose(); _medicationCtrl.dispose();
    _historyCtrl.dispose(); _insuranceCtrl.dispose(); _addressCtrl.dispose();
    _subDistrictCtrl.dispose(); _districtCtrl.dispose(); _provinceCtrl.dispose();
    _zipCodeCtrl.dispose();
    super.dispose();
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
        _birthDateCtrl.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year + 543}";
      });
    }
  }

  void _onRightChanged(String? value) {
    setState(() {
      _selectedRight = value;
      if (value == 'สิทธ์ประกันสังคม') {
        _insuranceCtrl.text = '900 บาท';
      } else {
        _insuranceCtrl.text = '-';
      }
    });
  }

  void _onSave() {
    // --- 💡 ระบบ Validation ตรวจสอบความถูกต้อง ---
    // 1. ตรวจสอบว่ากรอกข้อมูลจำเป็นครบไหม (เพิ่ม _phoneCtrl เข้ามาเช็คด้วย)
    if (_idCardCtrl.text.trim().isEmpty || 
        _firstNameCtrl.text.trim().isEmpty || 
        _lastNameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty) { 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลที่จำเป็น (ที่มีเครื่องหมาย *) ให้ครบถ้วน', style: TextStyle(fontFamily: 'Prompt')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return; 
    }

    // 2. ตรวจสอบเลขบัตรประชาชน (ต้อง 13 หลัก)
    if (_idCardCtrl.text.trim().length != 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกเลขบัตรประจำตัวประชาชนให้ครบ 13 หลัก', style: TextStyle(fontFamily: 'Prompt')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return; 
    }

    // 3. ตรวจสอบเบอร์โทรศัพท์ (อย่างน้อย 9-10 หลัก)
    if (_phoneCtrl.text.trim().length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกเบอร์โทรศัพท์ให้ถูกต้อง (9-10 หลัก)', style: TextStyle(fontFamily: 'Prompt')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return; 
    }
    // ------------------------------------------

    String pId = _patientIdCtrl.text;

    final updatedPatient = PatientInfo(
      patientId: pId,
      idCard: _idCardCtrl.text,
      prefix: _selectedPrefix ?? "-",
      firstName: _firstNameCtrl.text,
      lastName: _lastNameCtrl.text,
      gender: _selectedGender ?? "-",
      birthDate: _birthDateCtrl.text.isEmpty ? "-" : _birthDateCtrl.text,
      phone: _phoneCtrl.text.isEmpty ? "-" : _phoneCtrl.text,
      email: _emailCtrl.text.isEmpty ? "-" : _emailCtrl.text,
      disease: _diseaseCtrl.text.isEmpty ? "-" : _diseaseCtrl.text,
      allergy: _allergyCtrl.text.isEmpty ? "-" : _allergyCtrl.text,
      medication: _medicationCtrl.text.isEmpty ? "-" : _medicationCtrl.text,
      history: _historyCtrl.text.isEmpty ? "-" : _historyCtrl.text,
      right: _selectedRight ?? "-",
      insuranceLimit: _insuranceCtrl.text.isEmpty ? "-" : _insuranceCtrl.text,
      address: _addressCtrl.text.isEmpty ? "-" : _addressCtrl.text,
      subDistrict: _subDistrictCtrl.text.isEmpty ? "-" : _subDistrictCtrl.text,
      district: _districtCtrl.text.isEmpty ? "-" : _districtCtrl.text,
      province: _provinceCtrl.text.isEmpty ? "-" : _provinceCtrl.text,
      zipCode: _zipCodeCtrl.text.isEmpty ? "-" : _zipCodeCtrl.text,
    );

    Navigator.of(context).pop(updatedPatient);
  }

  @override
  Widget build(BuildContext context) {
    String title = "ลงทะเบียนผู้ป่วยใหม่";
    if (widget.existingPatient != null) {
      title = _isViewMode ? "ข้อมูลประจำตัวผู้ป่วย" : "แก้ไขข้อมูลผู้ป่วย";
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
              Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                    child: _buildDropdownField("คำนำหน้า", _prefixes, _selectedPrefix, (val) => setState(() => _selectedPrefix = val), enabled: !_isViewMode)
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
                    child: _buildDropdownField("เพศ", _genders, _selectedGender, (val) => setState(() => _selectedGender = val), enabled: !_isViewMode)
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: _buildTextField("วัน / เดือน / ปีเกิด", "วว/ดด/ปปปป", controller: _birthDateCtrl, icon: Icons.calendar_today_outlined, enabled: !_isViewMode)
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 💡 เพิ่ม isRequired: true ตรงเบอร์โทรศัพท์
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
                  Expanded(child: _buildDropdownField("สิทธิ์การรักษา", _rights, _selectedRight, _onRightChanged, enabled: !_isViewMode)),
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

              // --- ปุ่ม Action ---
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    if (_isViewMode) {
                      setState(() {
                        _isViewMode = false;
                      });
                    } else {
                      _onSave();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: saveButtonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _isViewMode 
                      ? "แก้ไขข้อมูลผู้ป่วย" 
                      : (widget.existingPatient != null ? "บันทึกการแก้ไข" : "บันทึกข้อมูลผู้ป่วย"), 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
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
                  style: const TextStyle(color: Colors.black87),
                  items: items.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(color: Colors.black87)),
                    );
                  }).toList(),
                ),
              ),
            ),
            Positioned(
              left: 12, top: -10,
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