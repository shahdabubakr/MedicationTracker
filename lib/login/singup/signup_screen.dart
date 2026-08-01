import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '\\firebase_service.dart';
import '\\user_model.dart';
import '\\home_screen.dart';
import '\\app_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  String completePhone = '';
  DateTime? selectedDate;
  bool _isLoading = false;
  bool _isPassVisible = false;

  final Color _primary = const Color(0xFF4A90E2);

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

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
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final bool isAr = appProvider.locale.languageCode == 'ar';

    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passController.text.isEmpty ||
        completePhone.isEmpty ||
        selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr
              ? "برجاء ملء جميع الحقول واختيار تاريخ الميلاد"
              : "Please fill all fields and select birth date"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passController.text.trim(),
      );

      UserModel newUser = UserModel(
        uid: cred.user!.uid,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        birthYear: selectedDate!.year,
        phone: completePhone,
      );

      await FirebaseService().saveUser(newUser);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userName: newUser.name,
              birthYear: newUser.birthYear,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final bool isAr = appProvider.locale.languageCode == 'ar';
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
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
              Align(
                alignment: isAr
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: isDark ? Colors.white : Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        isAr ? "إنشاء حساب جديد" : "Create Account",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // الاسم
                      _buildField(
                          nameController,
                          isAr ? "الاسم بالكامل" : "Full Name",
                          Icons.person_outline_rounded,
                          isDark),
                      const SizedBox(height: 18),

                      // الإيميل
                      _buildField(
                          emailController,
                          isAr ? "البريد الإلكتروني" : "Email",
                          Icons.email_outlined,
                          isDark),
                      const SizedBox(height: 18),

                      // الباسورد مع show/hide
                      TextField(
                        controller: passController,
                        obscureText: !_isPassVisible,
                        style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1F2937)),
                        decoration: InputDecoration(
                          labelText:
                              isAr ? "كلمة المرور" : "Password",
                          labelStyle: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF6B7280)),
                          prefixIcon: Icon(Icons.lock_outline,
                              color: _primary, size: 22),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPassVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: _primary,
                            ),
                            onPressed: () => setState(
                                () => _isPassVisible = !_isPassVisible),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withOpacity(0.08)
                              : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // رقم التليفون
                      IntlPhoneField(
                        initialCountryCode: 'EG',
                        style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1F2937)),
                        dropdownTextStyle: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1F2937)),
                        decoration: InputDecoration(
                          labelText:
                              isAr ? "رقم الهاتف" : "Phone Number",
                          labelStyle: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF6B7280)),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withOpacity(0.08)
                              : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none),
                        ),
                        onChanged: (phone) {
                          completePhone = phone.completeNumber;
                        },
                      ),
                      const SizedBox(height: 18),

                      // تاريخ الميلاد
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 18),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_outlined,
                                  color: _primary, size: 22),
                              const SizedBox(width: 12),
                              Text(
                                selectedDate == null
                                    ? (isAr
                                        ? "تاريخ الميلاد"
                                        : "Birth Date")
                                    : "${selectedDate!.day} / ${selectedDate!.month} / ${selectedDate!.year}",
                                style: TextStyle(
                                  color: selectedDate == null
                                      ? (isDark
                                          ? Colors.white54
                                          : const Color(0xFF6B7280))
                                      : (isDark
                                          ? Colors.white
                                          : Colors.black),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                minimumSize:
                                    const Size(double.infinity, 58),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(18)),
                              ),
                              onPressed: _handleSignUp,
                              child: Text(
                                isAr ? "تسجيل" : "Sign Up",
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                      const SizedBox(height: 24),
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

  Widget _buildField(TextEditingController ctrl, String label,
      IconData icon, bool isDark,
      {bool isPass = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPass,
      style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1F2937)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color:
                isDark ? Colors.white54 : const Color(0xFF6B7280)),
        prefixIcon: Icon(icon, color: _primary, size: 22),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.08)
            : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
      ),
    );
  }
}