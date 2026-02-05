import 'package:flutter/material.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final _formKey = GlobalKey<FormState>();

  Widget buildField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
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

              buildField("เลขบัตรประชาชน"),
              buildField("คำนำหน้า"),
              buildField("ชื่อจริง"),
              buildField("นามสกุล"),
              buildField("เพศ"),
              buildField("วันเกิด"),
              buildField("เบอร์โทร"),
              buildField("อีเมล"),
              buildField("ที่อยู่"),
              buildField("ตำบล"),
              buildField("อำเภอ"),
              buildField("จังหวัด"),
              buildField("รหัสไปรษณีย์"),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {

                  if (_formKey.currentState!.validate()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OTPScreen(),
                      ),
                    );
                  }
                },
                child: const Text("สมัครสมาชิก"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
