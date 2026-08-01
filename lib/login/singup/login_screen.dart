import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '\\firebase_service.dart';
import '\\home_screen.dart';
import 'signup_screen.dart';
import 'forgetpassword.dart';
import '\\app_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  final Color _primary = const Color(0xFF4A90E2);

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  // ===== دالة مساعدة: الانتقال للهوم =====
  Future<void> _goToHome(User user) async {
    var userDoc = await FirebaseService().getUserData();
    String userName = user.displayName ?? '';
    int birthYear = 2000;

    if (userDoc.exists && userDoc.data() != null) {
      final data = userDoc.data() as Map<String, dynamic>;
      userName = data['name'] ?? userName;
      birthYear = data['birthYear'] ?? 2000;
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            userName: userName,
            birthYear: birthYear,
          ),
        ),
      );
    }
  }

  // ===== تسجيل دخول بالإيميل =====
  void _handleLogin() async {
    if (emailController.text.isEmpty || passController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null && mounted) {
        await _goToHome(user);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = '';
        if (e.code == 'user-not-found' ||
            e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          msg = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
        } else {
          msg = e.message ?? 'حدث خطأ ما';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== تسجيل دخول بجوجل مع Account Linking =====
  void _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isGoogleLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential googleCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      try {
        // محاولة تسجيل دخول عادية
        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(googleCredential);

        if (userCredential.user != null && mounted) {
          await _goToHome(userCredential.user!);
        }
      } on FirebaseAuthException catch (e) {
        // لو نفس الإيميل موجود بـ Email/Password
        if (e.code == 'account-exists-with-different-credential') {
          final email = googleUser.email;

          // نطلب من المستخدم يدخل الباسورد بتاعه
          if (mounted) {
            final password = await _showPasswordDialog(email);
            if (password == null || password.isEmpty) {
              setState(() => _isGoogleLoading = false);
              return;
            }

            // نسجل دخول بالإيميل والباسورد
            final emailCredential = EmailAuthProvider.credential(
              email: email,
              password: password,
            );

            final emailUserCredential = await FirebaseAuth.instance
                .signInWithCredential(emailCredential);

            // نربط الحسابين
            await emailUserCredential.user!
                .linkWithCredential(googleCredential);

            if (mounted) {
              await _goToHome(emailUserCredential.user!);
            }
          }
        } else {
          rethrow;
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Google Sign-In Error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  // ===== Dialog لطلب الباسورد عند الـ Linking =====
  Future<String?> _showPasswordDialog(String email) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final isAr = appProvider.locale.languageCode == 'ar';
    final ctrl = TextEditingController();
    bool visible = false;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isAr ? 'ربط الحسابين' : 'Link Accounts',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr
                    ? 'الإيميل $email مسجل مسبقاً.\nأدخل كلمة المرور لربط حساب جوجل به.'
                    : 'Email $email already exists.\nEnter your password to link Google account.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                obscureText: !visible,
                decoration: InputDecoration(
                  labelText: isAr ? 'كلمة المرور' : 'Password',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon:
                        Icon(visible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setDialogState(() => visible = !visible),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text(
                isAr ? 'ربط' : 'Link',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isAr ? "تسجيل الدخول" : "Login",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildField(
                      emailController,
                      isAr ? "البريد الإلكتروني" : "Email",
                      Icons.email_outlined,
                      isDark),
                  const SizedBox(height: 18),
                  _buildField(passController, isAr ? "كلمة المرور" : "Password",
                      Icons.lock_outline, isDark,
                      isPass: true),
                  const SizedBox(height: 12),
                  Align(
                    alignment:
                        isAr ? Alignment.centerLeft : Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Forgetpassword()),
                      ),
                      child: Text(
                        isAr ? "نسيت كلمة المرور؟" : "Forgot Password?",
                        style: TextStyle(
                            color: _primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : _buildButton(isAr ? "دخول" : "Sign In", _handleLogin),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                          child: Divider(
                              color: isDark ? Colors.white24 : Colors.black12)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          isAr ? "أو" : "OR",
                          style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38),
                        ),
                      ),
                      Expanded(
                          child: Divider(
                              color: isDark ? Colors.white24 : Colors.black12)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
                    child: Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: _isGoogleLoading
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/Images/google.png',
                                  height: 26,
                                  width: 26,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isAr
                                      ? "تسجيل الدخول بجوجل"
                                      : "Sign in with Google",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1F2937),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildSignUpLink(isDark, isAr),
                ],
              ),
            ),
          ),
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
      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1F2937)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: isDark ? Colors.white54 : const Color(0xFF6B7280)),
        prefixIcon: Icon(icon, color: _primary, size: 22),
        filled: true,
        fillColor:
            isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onTap) {
    return Material(
      borderRadius: BorderRadius.circular(18),
      elevation: 4,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 58),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: onTap,
        child: Text(text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              fontSize: 15),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignUpScreen()),
          ),
          child: Text(
            isAr ? "إنشاء حساب" : "Sign up",
            style: TextStyle(
                color: _primary, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
