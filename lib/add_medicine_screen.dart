import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart'; // للربط مع الأردوينو
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
// import 'firebase_service.dart';
import 'notification_service.dart';
import 'app_provider.dart';

class AddMedicineScreen extends StatefulWidget {
  final String? initialName; // الاسم اللي جاي من البحث
  final String? initialDesc; // الوصف اللي جاي من البحث

  const AddMedicineScreen({super.key, this.initialName, this.initialDesc});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  late TextEditingController nameController;
  late TextEditingController descController;
  TimeOfDay selectedTime = TimeOfDay.now();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    // تعبئة البيانات لو جاية من البحث تلقائياً
    nameController = TextEditingController(text: widget.initialName ?? "");
    descController = TextEditingController(text: widget.initialDesc ?? "");
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    super.dispose();
  }

  // دالة الحفظ المزدوج (فلاتر + أردوينو)
  Future<void> _handleSave() async {
    if (nameController.text.isEmpty) return;

    setState(() => isSaving = true);

    String uid = FirebaseAuth.instance.currentUser!.uid;
    String medId = DateTime.now().millisecondsSinceEpoch.toString();
    // تنسيق الوقت عشان الأردوينو يفهمه بسهولة (مثلاً 14:30)
    String timeStr =
        "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";

    try {
      // 1. الحفظ في Firestore (للأبلكيشن واليوزر)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('medicines')
          .doc(medId)
          .set({
        'name': nameController.text.trim(),
        'description': descController.text.trim(),
        'time': timeStr,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. الحفظ في Realtime Database (عشان مهندسين الكهرباء والـ ESP32)
      DatabaseReference rtRef =
          FirebaseDatabase.instance.ref("devices/$uid/alarms/$medId");
      await rtRef.set({
        'time': timeStr,
        'status': 'pending',
        'medName': nameController.text.trim(),
      });

      // 3. جدولة التنبيه الداخلي للموبايل
      int notifyId = int.parse(medId.substring(medId.length - 6));
      await NotificationService()
          .scheduleNotification(notifyId, nameController.text.trim(), timeStr);

      // تأخير بسيط عشان اليوزر يشوف علامة الصح
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    bool isAr = appProvider.locale.languageCode == 'ar';
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color primaryColor = const Color(0xFF4A90E2);

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
                centerTitle: true,
                title: Text(
                  widget.initialName != null
                      ? (isAr ? "تأكيد الدواء" : "Confirm Medicine")
                      : (isAr ? "إضافة دواء جديد" : "Add New Medicine"),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
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
                            _buildTextField(
                              controller: nameController,
                              hint: isAr ? "اسم الدواء" : "Medicine name",
                              icon: Icons.medication_rounded,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 18),
                            _buildTextField(
                              controller: descController,
                              hint: isAr
                                  ? "وصف العلاج أو ملاحظات (اختياري)"
                                  : "Treatment notes (optional)",
                              icon: Icons.description_outlined,
                              isDark: isDark,
                              maxLines: 4,
                            ),
                            const SizedBox(height: 18),
                            GestureDetector(
                              onTap: () async {
                                TimeOfDay? picked = await showTimePicker(
                                    context: context, initialTime: selectedTime);
                                if (picked != null) setState(() => selectedTime = picked);
                              },
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
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.schedule_rounded,
                                        color: primaryColor,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      isAr ? "وقت الجرعة" : "Dose time",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      selectedTime.format(context),
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: primaryColor,
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Material(
                        borderRadius: BorderRadius.circular(18),
                        shadowColor: primaryColor.withValues(alpha: 0.4),
                        elevation: 8,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSaving ? const Color(0xFF22C55E) : primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 58),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                          onPressed: isSaving ? null : _handleSave,
                          child: isSaving
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_rounded,
                                        color: Colors.white, size: 24),
                                    const SizedBox(width: 10),
                                    Text(
                                      isAr ? "تم الحفظ بنجاح" : "Saved successfully",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 17),
                                    ),
                                  ],
                                )
                              : Text(
                                  isAr ? "حفظ البيانات" : "Save data",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF1F2937),
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
        ),
        prefixIcon: Icon(icon, color: isDark ? Colors.white : const Color(0xFF1F2937), size: 22),
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
