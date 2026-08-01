import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '\\app_provider.dart';
import '\\home_screen.dart';
import 'login_screen.dart';

class NewPassword extends StatefulWidget {
  final String email;

  const NewPassword({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<NewPassword> createState() => _NewPasswordState();
}

class _NewPasswordState extends State<NewPassword> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSavePassword(bool isAr) async {
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? "يرجى ملء جميع الحقول" : "Please fill all fields"),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr
            ? "كلمة المرور يجب أن تكون 6 أحرف على الأقل"
            : "Password must be at least 6 characters"),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(isAr ? "كلمات السر غير متطابقة" : "Passwords do not match"),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = FirebaseFirestore.instance;

      // 1. نجيب بيانات المستخدم من Firestore بالإيميل
      final query = await db
          .collection('users')
          .where('email', isEqualTo: widget.email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(isAr ? "لم يتم العثور على الحساب" : "Account not found"),
            backgroundColor: Colors.redAccent,
          ));
          setState(() => _isLoading = false);
        }
        return;
      }

      // 2. نحفظ كل البيانات القديمة
      final oldDoc = query.docs.first;
      final oldUid = oldDoc.id;
      final userData = oldDoc.data();

      // 3. نجيب كل الأدوية
      final medicinesSnap = await db
          .collection('users')
          .doc(oldUid)
          .collection('medicines')
          .get();

      final List<Map<String, dynamic>> medicinesList = medicinesSnap.docs
          .map((doc) => {'id': doc.id, 'data': doc.data()})
          .toList();

      // 4. نحذف الأكاونت القديم من Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.delete();
      }

      // 5. نعمل أكاونت جديد بنفس الإيميل والباسورد الجديد
      final newCred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: password,
      );

      final newUid = newCred.user!.uid;

      // 6. نحفظ كل بيانات المستخدم بالـ uid الجديد
      await db.collection('users').doc(newUid).set({
        ...userData,
        'uid': newUid,
      });

      // 7. ننقل كل الأدوية للـ uid الجديد
      for (final medicine in medicinesList) {
        await db
            .collection('users')
            .doc(newUid)
            .collection('medicines')
            .doc(medicine['id'])
            .set(medicine['data']);
      }

      // 8. نحذف البيانات القديمة
      if (oldUid != newUid) {
        // نحذف الأدوية القديمة
        for (final doc in medicinesSnap.docs) {
          await doc.reference.delete();
        }
        // نحذف الـ doc القديم
        await db.collection('users').doc(oldUid).delete();
      }

      // 9. نجيب الاسم وسنة الميلاد للـ HomeScreen
      final userName = userData['name'] ?? '';
      final birthYear = userData['birthYear'] ?? 2000;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr
              ? "تم تحديث كلمة المرور بنجاح ✓"
              : "Password updated successfully ✓"),
          backgroundColor: Colors.green,
        ));

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userName: userName,
              birthYear: birthYear,
            ),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(e.message ?? (isAr ? "حدث خطأ ما" : "Something went wrong")),
          backgroundColor: Colors.redAccent,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Text(
                  isAr ? 'كلمة سر جديدة' : 'New Password',
                  style: GoogleFonts.cairo(
                    textStyle: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  widget.email,
                  style: GoogleFonts.cairo(
                    textStyle: TextStyle(color: primaryColor, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: isAr ? 'كلمة السر الجديدة' : 'New Password',
                  labelStyle: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: primaryColor),
                    onPressed: () =>
                        setState(() => isPasswordVisible = !isPasswordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: confirmPasswordController,
                obscureText: !isConfirmVisible,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: isAr ? 'تأكيد كلمة السر' : 'Confirm Password',
                  labelStyle: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: Icon(
                        isConfirmVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: primaryColor),
                    onPressed: () =>
                        setState(() => isConfirmVisible = !isConfirmVisible),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed:
                      _isLoading ? null : () => _handleSavePassword(isAr),
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
                          isAr ? 'حفظ ودخول' : 'Save & Enter',
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
