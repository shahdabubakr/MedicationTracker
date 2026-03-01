import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';
import 'user_model.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  void _handleLogin() async {
    try {
      // 1. تسجيل الدخول في FirebaseAuth
      UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passController.text.trim());

      User? firebaseUser = credential.user;

      if (firebaseUser != null) {
        // 2. جلب البيانات من Firestore باستخدام UID
        var userData = await FirebaseService().getUserData();

        if (userData.exists) {
          final data = userData.data();
          if (data is Map<String, dynamic>) {
            UserModel user = UserModel.fromMap(data);

            // 3. الانتقال للهوم بالبيانات الحقيقية
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        HomeScreen(userName: user.name, birthYear: user.birthYear)));
          } else {
            throw Exception("بيانات المستخدم غير صالحة");
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("خطأ في البيانات.. يرجى التسجيل من جديد")),
          );
          await FirebaseAuth.instance.signOut();
        }
      }
    } catch (e) {
      // رسالة خطأ عامة للمستخدم
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("خطأ في تسجيل الدخول.. تأكد من بياناتك")),
      );
      print("Login Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              Icon(Icons.shield_outlined, size: 100, color: Colors.blue[600]),
              const SizedBox(height: 50),
              _buildInput(emailController, "البريد الإلكتروني",
                  Icons.email_outlined, isDark),
              const SizedBox(height: 20),
              _buildInput(passController, "كلمة المرور", Icons.lock_outline, isDark,
                  isPass: true),
              const SizedBox(height: 40),
              _buildButton("دخول", _handleLogin),
              const SizedBox(height: 20),
              _buildSignUpLink(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
      TextEditingController ctrl, String hint, IconData icon, bool isDark,
      {bool isPass = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPass,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue[600]),
        filled: true,
        fillColor: isDark ? Colors.white10 : Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          minimumSize: const Size(double.infinity, 60),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      onPressed: onTap,
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSignUpLink(bool isDark) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text("ليس لديك حساب؟ ",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
      GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const SignUpScreen())),
        child: Text("إنشاء حساب",
            style: TextStyle(
                color: Colors.blue[600], fontWeight: FontWeight.bold)),
      ),
    ]);
  }
}