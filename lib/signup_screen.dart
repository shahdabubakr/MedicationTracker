import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_model.dart';
import 'firebase_service.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();

  // المتغير الجديد لحفظ التاريخ المختار
  DateTime? selectedDate;

  // دالة اختيار التاريخ الكامل (يوم/شهر/سنة)
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      helpText: "اختر تاريخ ميلادك",
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  void _handleSignUp() async {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("يرجى اختيار تاريخ ميلادك")));
      return;
    }

    try {
      UserCredential cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passController.text.trim(),
      );

      UserModel newUser = UserModel(
        uid: cred.user!.uid,
        name: nameController.text.trim(),
        birthYear: selectedDate!.year, // نرسل السنة للموديل الحالي
        email: emailController.text.trim(),
      );

      await FirebaseService().saveUser(newUser);

      if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => HomeScreen(
                    userName: newUser.name, birthYear: newUser.birthYear)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("خطأ: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFF),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Text("إنشاء حساب جديد",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            _buildField(
                nameController, "الاسم الكامل", Icons.person_outline, isDark),
            const SizedBox(height: 20),

            // حقل اختيار التاريخ (اليوم، الشهر، السنة)
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.blue[600]),
                    const SizedBox(width: 12),
                    Text(
                      selectedDate == null
                          ? "اختر تاريخ ميلادك"
                          : "${selectedDate!.day} / ${selectedDate!.month} / ${selectedDate!.year}",
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedDate == null
                            ? Colors.grey[600]
                            : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            _buildField(emailController, "البريد الإلكتروني",
                Icons.email_outlined, isDark),
            const SizedBox(height: 20),
            _buildField(
                passController, "كلمة المرور", Icons.lock_outline, isDark,
                isPass: true),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15))),
              onPressed: _handleSignUp,
              child: const Text("تأكيد وإنشاء حساب",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController ctrl, String label, IconData icon, bool isDark,
      {bool isPass = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPass,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[600]),
        filled: true,
        fillColor: isDark ? Colors.white10 : Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
      ),
    );
  }
}
