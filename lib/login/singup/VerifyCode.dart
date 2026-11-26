import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '\\app_provider.dart';
import 'login_screen.dart';

class VerifyCode extends StatefulWidget {
  final String otp;
  final String email;

  const VerifyCode({
    Key? key,
    required this.otp,
    required this.email,
  }) : super(key: key);

  @override
  State<VerifyCode> createState() => _VerifyCodeState();
}

class _VerifyCodeState extends State<VerifyCode> {
  TextEditingController pinController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  void _verifyCode(bool isAr) async {
    if (pinController.text.length < 6) return;

    setState(() => _isLoading = true);

    final enteredOtp = pinController.text.trim();

    if (enteredOtp != widget.otp) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(isAr
                ? "الرمز المدخل غير صحيح، يرجى المحاولة مرة أخرى"
                : "Invalid code, please try again"),
          ),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    // الكود صح — نبعت reset link من Firebase
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: widget.email,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(
              isAr ? '✅ تم التحقق بنجاح' : '✅ Verified',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            content: Text(
              isAr
                  ? 'تم إرسال رابط تغيير كلمة المرور إلى بريدك الإلكتروني.\n\n'
                      '1️⃣ افتح إيميلك\n'
                      '2️⃣ اضغط على الرابط\n'
                      '3️⃣ غير كلمة المرور\n'
                      '4️⃣ ارجع وسجل دخول'
                  : 'A password reset link has been sent to your email.\n\n'
                      '1️⃣ Open your email\n'
                      '2️⃣ Click the link\n'
                      '3️⃣ Change your password\n'
                      '4️⃣ Come back and login',
              style: const TextStyle(height: 1.8),
              textAlign: TextAlign.center,
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: Text(
                    isAr ? 'حسناً، سأفتح إيميلي' : 'OK, I\'ll check my email',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    bool isAr = appProvider.locale.languageCode == 'ar';
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color primaryColor = const Color(0xFF4A90E2);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.black, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                isAr ? 'التحقق من الرمز' : 'Verification Code',
                style: GoogleFonts.cairo(
                  textStyle: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isAr
                    ? 'أدخل رمز التحقق الذي تم إرساله إلى\n${widget.email}'
                    : 'Enter the verification code sent to\n${widget.email}',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  textStyle: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 15),
                ),
              ),
              const SizedBox(height: 50),
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: pinController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                autoDisposeControllers: false,
                textStyle: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 20),
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 50,
                  fieldWidth: 40,
                  activeColor: primaryColor,
                  inactiveColor:
                      isDark ? Colors.white24 : Colors.grey.shade300,
                  selectedColor: primaryColor,
                ),
                onChanged: (value) {},
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed:
                      _isLoading ? null : () => _verifyCode(isAr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          isAr ? 'تأكيد الرمز' : 'Verify Code',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}