import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'user_model.dart';
import 'firebase_service.dart';
import 'home_screen.dart';
import 'app_provider.dart';

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  void _handleSignUp() async {
    if (selectedDate == null) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final bool isAr = appProvider.locale.languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr
              ? "يرجى اختيار تاريخ ميلادك"
              : "Please select your birth date")));
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
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final bool isAr = appProvider.locale.languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr
              ? "خطأ في إنشاء الحساب: ${e.toString()}"
              : "Sign up error: ${e.toString()}")));
    }
  }

  static const Color _primary = Color(0xFF4A90E2);

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final bool isAr = appProvider.locale.languageCode == 'ar';
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF020617)]
                : [const Color(0xFFEEF2FF), const Color(0xFFE0F2FE)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                    size: 22,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [_primary, Color(0xFF60A5FA)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isAr ? "إنشاء حساب جديد" : "Create a new account",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAr ? "أدخل بياناتك للبدء" : "Enter your details to get started",
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 28),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: isDark
                              ? Border.all(
                                  color: Colors.white.withValues(alpha: 0.08))
                              : null,
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 28,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                        ),
                        child: Column(
                          children: [
                            _buildField(
                              nameController,
                              isAr ? "الاسم الكامل" : "Full name",
                              Icons.person_outline,
                              isDark,
                            ),
                            const SizedBox(height: 18),
                            GestureDetector(
                              onTap: () => _selectDate(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      color: _primary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 14),
                                    Text(
                                      selectedDate == null
                                          ? (isAr
                                              ? "اختر تاريخ ميلادك"
                                              : "Select your birth date")
                                          : "${selectedDate!.day} / ${selectedDate!.month} / ${selectedDate!.year}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: selectedDate == null
                                            ? (isDark
                                                ? Colors.white38
                                                : const Color(0xFF9CA3AF))
                                            : (isDark
                                                ? Colors.white
                                                : const Color(0xFF1F2937)),
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: _primary,
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _buildField(
                              emailController,
                              isAr ? "البريد الإلكتروني" : "Email",
                              Icons.email_outlined,
                              isDark,
                            ),
                            const SizedBox(height: 18),
                            _buildField(
                              passController,
                              isAr ? "كلمة المرور" : "Password",
                              Icons.lock_outline,
                              isDark,
                              isPass: true,
                            ),
                            const SizedBox(height: 28),
                            Material(
                              borderRadius: BorderRadius.circular(18),
                              shadowColor: _primary.withValues(alpha: 0.4),
                              elevation: 8,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 58),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _handleSignUp,
                                child: Text(
                                  isAr ? "تأكيد وإنشاء حساب" : "Confirm & Create account",
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    bool isDark, {
    bool isPass = false,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: isPass,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF1F2937),
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white54 : const Color(0xFF6B7280),
        ),
        prefixIcon: Icon(icon, color: _primary, size: 22),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}
