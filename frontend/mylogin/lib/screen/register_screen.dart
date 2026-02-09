import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';
import 'login_screen.dart';

/// =========================
/// ENUMS
/// =========================
enum Gender { male, female, other }
enum TreatmentRight { goldCard, government, socialSecurity, selfPay }

/// =========================
/// EXTENSIONS
/// =========================
extension GenderExt on Gender {
  String get api {
    switch (this) {
      case Gender.male:
        return 'male';
      case Gender.female:
        return 'female';
      case Gender.other:
        return 'other';
    }
  }

  String get labelTH {
    switch (this) {
      case Gender.male:
        return 'ชาย';
      case Gender.female:
        return 'หญิง';
      case Gender.other:
        return 'ไม่ระบุ';
    }
  }
}

extension TreatmentRightExt on TreatmentRight {
  String get api {
    switch (this) {
      case TreatmentRight.goldCard:
        return 'gold_card';
      case TreatmentRight.government:
        return 'government';
      case TreatmentRight.socialSecurity:
        return 'social_security';
      case TreatmentRight.selfPay:
        return 'self_pay';
    }
  }

  String get labelTH {
    switch (this) {
      case TreatmentRight.goldCard:
        return 'บัตรทอง';
      case TreatmentRight.government:
        return 'ข้าราชการ';
      case TreatmentRight.socialSecurity:
        return 'ประกันสังคม';
      case TreatmentRight.selfPay:
        return '-';
    }
  }
}

/// =========================
/// SCREEN
/// =========================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
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
  Gender? gender;
  TreatmentRight? right;

  /// =========================
  /// Text Field Builder
  /// =========================
  Widget buildField(
    String label,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? formatter,
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
        validator: (v) =>
            v == null || v.isEmpty ? "กรุณากรอกข้อมูล" : null,
      ),
    );
  }

  /// =========================
  /// Date Picker
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
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      setState(() {});
    }
  }

  /// =========================
  /// REGISTER
  /// =========================
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      "citizen_id": idCard.text.trim(),
      "title": title,
      "first_name": firstName.text.trim(),
      "last_name": lastName.text.trim(),
      "gender": gender?.api ?? "other",
      "birth_date": birthDate.text.trim(),
      "rights": right?.api ?? "self_pay",
      "email": email.text.trim(),
      "phone": phone.text.trim(),
      "address_line": address.text.trim(),
      "subdistrict": subDistrict.text.trim(),
      "district": district.text.trim(),
      "province": province.text.trim(),
      "postal_code": zip.text.trim(),
    };

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.register(data);

      if (!mounted) return;

      if (result['statusCode'] == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OTPScreen(email: email.text.trim()),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['body']['message'] ?? "เกิดข้อผิดพลาด"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เชื่อมต่อเซิร์ฟเวอร์ไม่ได้")),
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  /// =========================
  /// Dispose
  /// =========================
  @override
  void dispose() {
    idCard.dispose();
    firstName.dispose();
    lastName.dispose();
    birthDate.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
    subDistrict.dispose();
    district.dispose();
    province.dispose();
    zip.dispose();
    super.dispose();
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
              buildField(
                "เลขบัตรประชาชน",
                idCard,
                type: TextInputType.number,
                formatter: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(13),
                ],
              ),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "คำนำหน้า",
                  border: OutlineInputBorder(),
                ),
                items: ["นาย", "นางสาว", "นาง"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => title = v),
                validator: (v) => v == null ? "กรุณาเลือกข้อมูล" : null,
              ),

              buildField("ชื่อจริง", firstName),
              buildField("นามสกุล", lastName),

              DropdownButtonFormField<Gender>(
                decoration: const InputDecoration(
                  labelText: "เพศ",
                  border: OutlineInputBorder(),
                ),
                items: Gender.values
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g.labelTH),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => gender = v),
                validator: (v) => v == null ? "กรุณาเลือกข้อมูล" : null,
              ),

              buildField(
                "วัน/เดือน/ปีเกิด",
                birthDate,
                readOnly: true,
                onTap: pickDate,
              ),

              buildField("เบอร์โทรศัพท์", phone,
                  type: TextInputType.number,
                  formatter: [FilteringTextInputFormatter.digitsOnly]),

              buildField("อีเมล", email,
                  type: TextInputType.emailAddress),

              DropdownButtonFormField<TreatmentRight>(
                decoration: const InputDecoration(
                  labelText: "สิทธิการรักษา",
                  border: OutlineInputBorder(),
                ),
                items: TreatmentRight.values
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r.labelTH),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => right = v),
                validator: (v) => v == null ? "กรุณาเลือกข้อมูล" : null,
              ),

              buildField("ที่อยู่", address),
              buildField("แขวง/ตำบล", subDistrict),
              buildField("เขต/อำเภอ", district),
              buildField("จังหวัด", province),

              buildField(
                "รหัสไปรษณีย์",
                zip,
                type: TextInputType.number,
                formatter: [FilteringTextInputFormatter.digitsOnly],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("สมัครสมาชิก"),
                ),
              ),

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
