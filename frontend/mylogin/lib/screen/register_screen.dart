import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'otp_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  /// Controllers
  final idCard = TextEditingController();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final birthDate = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();
  final subDistrict = TextEditingController();
  final district = TextEditingController();
  final province = TextEditingController();
  final zip = TextEditingController();

  String? title;
  String? gender;

  final thaiRegex = RegExp(r'^[ก-๙\s]+$');

  /// =========================
  /// buildField
  /// =========================
  Widget buildField(
    String label,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? formatter,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        inputFormatters: formatter,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: validator ??
            (v) {
              if (v == null || v.isEmpty) return "กรุณากรอกข้อมูล";
              return null;
            },
      ),
    );
  }

  /// =========================
  /// Dropdown
  /// =========================
  Widget buildDropdown(
      String label, List<String> items, String? value, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? "กรุณาเลือกข้อมูล" : null,
      ),
    );
  }

  /// =========================
  /// Date picker
  /// =========================
  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: DateTime(2000),
    );

    if (date != null) {
      birthDate.text =
          "${date.day}/${date.month}/${date.year}";
      setState(() {});
    }
  }

  /// =========================
  /// UI
  /// =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ลงทะเบียน")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,
          child: Column(
            children: [

              /// บัตรประชาชน
              buildField(
                "เลขบัตรประชาชน",
                idCard,
                type: TextInputType.number,
                formatter: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(13),
                ],
                validator: (v) =>
                    v!.length != 13 ? "ต้อง 13 หลัก" : null,
              ),

              /// คำนำหน้า
              buildDropdown(
                "คำนำหน้า",
                ["นาย", "นางสาว", "นาง"],
                title,
                (v) => setState(() => title = v),
              ),

              /// ชื่อไทย
              buildField(
                "ชื่อจริง",
                firstName,
                type: TextInputType.text,
                validator: (v) {
                  if (v == null || v.isEmpty) return "กรุณากรอก";
                  if (!thaiRegex.hasMatch(v)) return "ภาษาไทยเท่านั้น";
                  return null;
                },
              ),

              buildField(
                "นามสกุล",
                lastName,
                type: TextInputType.text,
                validator: (v) {
                  if (v == null || v.isEmpty) return "กรุณากรอก";
                  if (!thaiRegex.hasMatch(v)) return "ภาษาไทยเท่านั้น";
                  return null;
                },
              ),

              /// เพศ
              buildDropdown(
                "เพศ",
                ["ชาย", "หญิง", "ไม่ระบุ"],
                gender,
                (v) => setState(() => gender = v),
              ),

              /// วันเกิด (date picker)
              buildField(
                "วัน/เดือน/ปีเกิด",
                birthDate,
                readOnly: true,
                onTap: pickDate,
              ),

              /// เบอร์
              buildField(
                "เบอร์โทรศัพท์",
                phone,
                type: TextInputType.number,
                formatter: [FilteringTextInputFormatter.digitsOnly],
              ),

              /// email
              buildField(
                "อีเมล",
                email,
                type: TextInputType.emailAddress,
              ),

              /// ที่อยู่ (ไทยพิมพ์ได้)
              buildField("ที่อยู่", address),
              buildField("แขวง/ตำบล", subDistrict),
              buildField("เขต/อำเภอ", district),
              buildField("จังหวัด", province),

              /// ไปรษณีย์
              buildField(
                "รหัสไปรษณีย์",
                zip,
                type: TextInputType.number,
                formatter: [FilteringTextInputFormatter.digitsOnly],
              ),

              const SizedBox(height: 20),

              /// ปุ่มสมัคร
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  child: const Text("สมัครสมาชิก"),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {

                      Map<String, dynamic> data = {
                        "id_card": idCard.text,
                        "title": title,
                        "first_name": firstName.text,
                        "last_name": lastName.text,
                        "gender": gender,
                        "birth_date": birthDate.text,
                        "phone": phone.text,
                        "email": email.text,
                      };

                      print(data);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OTPScreen(),
                        ),
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("มีบัญชีอยู่แล้ว ? "),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text("เข้าสู่ระบบ"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
