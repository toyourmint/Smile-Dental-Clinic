import 'package:flutter/material.dart';
import 'otp_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // ================= CONTROLLERS =================
  final citizenIdCtrl = TextEditingController();
  final titleCtrl = TextEditingController();
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final genderCtrl = TextEditingController();
  final birthDateCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final subdistrictCtrl = TextEditingController();
  final districtCtrl = TextEditingController();
  final provinceCtrl = TextEditingController();
  final postalCodeCtrl = TextEditingController();

  Widget buildField(String label, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller, // 🔥 สำคัญมาก
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "กรุณากรอกข้อมูล";
        }
        return null;
      },
    ),
  );
}


// ================= REGISTER FUNCTION =================
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      "citizen_id": citizenIdCtrl.text.trim(),
      "title": titleCtrl.text.trim(),
      "first_name": firstNameCtrl.text.trim(),
      "last_name": lastNameCtrl.text.trim(),
      "birth_date": birthDateCtrl.text.trim(),
      "gender": genderCtrl.text.trim(),
      "email": emailCtrl.text.trim(),
      "phone": phoneCtrl.text.trim(),
      "address_line": addressCtrl.text.trim(),
      "subdistrict": subdistrictCtrl.text.trim(),
      "district": districtCtrl.text.trim(),
      "province": provinceCtrl.text.trim(),
      "postal_code": postalCodeCtrl.text.trim(),
    };

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.register(data);

      if (result['statusCode'] == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OTPScreen(email: emailCtrl.text),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['body']['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เชื่อมต่อเซิร์ฟเวอร์ไม่ได้")),
      );
    }

    setState(() => _isLoading = false);
  }

  // ================= DISPOSE =================
  @override
  void dispose() {
    citizenIdCtrl.dispose();
    titleCtrl.dispose();
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    genderCtrl.dispose();
    birthDateCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    addressCtrl.dispose();
    subdistrictCtrl.dispose();
    districtCtrl.dispose();
    provinceCtrl.dispose();
    postalCodeCtrl.dispose();
    super.dispose();
  }

  // ================= UI =================
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
              buildField("เลขบัตรประชาชน", citizenIdCtrl),
              buildField("คำนำหน้า", titleCtrl),
              buildField("ชื่อจริง", firstNameCtrl),
              buildField("นามสกุล", lastNameCtrl),
              buildField("เพศ", genderCtrl),
              buildField("วันเกิด", birthDateCtrl),
              buildField("เบอร์โทร", phoneCtrl),
              buildField("อีเมล", emailCtrl),
              buildField("ที่อยู่", addressCtrl),
              buildField("ตำบล", subdistrictCtrl),
              buildField("อำเภอ", districtCtrl),
              buildField("จังหวัด", provinceCtrl),
              buildField("รหัสไปรษณีย์", postalCodeCtrl),
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
              const SizedBox(height: 12),

              /// ลิงก์ Login
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
