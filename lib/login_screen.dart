import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_service.dart';
import 'user_model.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import 'app_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    try {
      // 1. تسجيل الدخول في FirebaseAuth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passController.text.trim());

      // workaround لمشكلة PigeonUserDetails في بعض إصدارات firebase_auth:
      // نستخدم currentUser مباشرة بدلاً من قراءة user من UserCredential
      User? firebaseUser = FirebaseAuth.instance.currentUser;

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
          final appProvider = Provider.of<AppProvider>(context, listen: false);
          final bool isAr = appProvider.locale.languageCode == 'ar';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(isAr
                    ? "خطأ في البيانات.. يرجى التسجيل من جديد"
                    : "User data error, please sign up again")),
          );
          await FirebaseAuth.instance.signOut();
        }
      }
    } catch (e) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final bool isAr = appProvider.locale.languageCode == 'ar';

      // في بعض الإصدارات يحصل خطأ داخلي (PigeonUserDetails) رغم أن المستخدم تم تسجيل دخوله بنجاح
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null &&
          e.toString().contains('PigeonUserDetails')) {
        try {
          // نكمل تحميل بيانات المستخدم كأن العملية نجحت
          var userData = await FirebaseService().getUserData();
          if (userData.exists) {
            final data = userData.data();
            if (data is Map<String, dynamic>) {
              UserModel user = UserModel.fromMap(data);
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => HomeScreen(
                          userName: user.name, birthYear: user.birthYear)));
              return;
            }
          }
        } catch (_) {
          // لو فشلنا هنا نرجع لرسالة الخطأ العامة بالأسفل
        }
      }

      // رسالة خطأ عامة للمستخدم (أو في حالة credential غير صحيحة)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isAr
                ? "خطأ في تسجيل الدخول.. تأكد من بريدك وكلمة المرور"
                : "Login failed, please check your email and password")),
      );
      print("Login Error: $e");
    }
  }

  Future<void> _handleForgotPassword() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final bool isAr = appProvider.locale.languageCode == 'ar';

    final dialogEmailController = TextEditingController(
      text: emailController.text.trim(),
    );

    try {
      final email = await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            title: Text(isAr ? 'إعادة تعيين كلمة المرور' : 'Reset password'),
            content: TextField(
              controller: dialogEmailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: isAr ? 'اكتب بريدك الإلكتروني' : 'Enter your email',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isAr ? 'إلغاء' : 'Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final value = dialogEmailController.text.trim();
                  if (value.isEmpty) return;
                  Navigator.pop(context, value);
                },
                child: Text(isAr ? 'إرسال' : 'Send'),
              ),
            ],
          );
        },
      );

      if (email == null || email.isEmpty) return;

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك.'
                : 'Password reset link sent to your email.',
          ),
        ),
      );
    } on FirebaseAuthException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'تعذر إرسال الرابط. تأكد من البريد الإلكتروني.'
                : 'Could not send reset link. Please check the email.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'حدث خطأ غير متوقع.' : 'An unexpected error occurred.',
          ),
        ),
      );
    } finally {
      dialogEmailController.dispose();
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [_primary, Color(0xFF60A5FA)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    isAr ? "تسجيل الدخول" : "Sign in",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr ? "ادخل بياناتك للمتابعة" : "Enter your details to continue",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 36),
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
                        _buildInput(
                          emailController,
                          isAr ? "البريد الإلكتروني" : "Email",
                          Icons.email_outlined,
                          isDark,
                        ),
                        const SizedBox(height: 18),
                        _buildInput(
                          passController,
                          isAr ? "كلمة المرور" : "Password",
                          Icons.lock_outline,
                          isDark,
                          isPass: true,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: isAr
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: TextButton(
                            onPressed: _handleForgotPassword,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                            ),
                            child: Text(
                              isAr
                                  ? 'نسيت كلمة المرور؟'
                                  : 'Forgot your password?',
                              style: const TextStyle(
                                color: _primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildButton(isAr ? "دخول" : "Login", _handleLogin),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildSignUpLink(isDark, isAr),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController ctrl,
    String hint,
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
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
        ),
        prefixIcon: Icon(
          icon,
          color: _primary,
          size: 22,
        ),
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

  Widget _buildButton(String text, VoidCallback onTap) {
    return Material(
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
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink(bool isDark, bool isAr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isAr ? "ليس لديك حساب؟ " : "Don't have an account? ",
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF6B7280),
            fontSize: 15,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const SignUpScreen()),
          ),
          child: Text(
            isAr ? "إنشاء حساب" : "Sign up",
            style: const TextStyle(
              color: _primary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}