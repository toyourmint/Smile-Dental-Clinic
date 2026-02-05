import 'package:flutter/material.dart';
import 'login_screen.dart';

class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {

  final passController = TextEditingController();
  final confirmController = TextEditingController();

  bool obscure1 = true;
  bool obscure2 = true;

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("สร้างรหัสผ่าน")),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Form(
          key: _formKey,

          child: Column(
            children: [

              /// Password
              TextFormField(
                controller: passController,
                obscureText: obscure1,

                decoration: InputDecoration(
                  labelText: "รหัสผ่าน",
                  border: const OutlineInputBorder(),

                  suffixIcon: IconButton(
                    icon: Icon(
                        obscure1 ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        obscure1 = !obscure1;
                      });
                    },
                  ),
                ),

                validator: (value) {
                  if (value == null || value.length < 6) {
                    return "รหัสผ่านอย่างน้อย 6 ตัว";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// Confirm Password
              TextFormField(
                controller: confirmController,
                obscureText: obscure2,

                decoration: InputDecoration(
                  labelText: "ยืนยันรหัสผ่าน",
                  border: const OutlineInputBorder(),

                  suffixIcon: IconButton(
                    icon: Icon(
                        obscure2 ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        obscure2 = !obscure2;
                      });
                    },
                  ),
                ),

                validator: (value) {
                  if (value != passController.text) {
                    return "รหัสผ่านไม่ตรงกัน";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              /// Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  child: const Text("ยืนยัน"),
                  onPressed: () {

                    if (_formKey.currentState!.validate()) {

                      /// กลับหน้า Login และล้าง history
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
