import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart'; // للربط مع الأردوينو
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

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
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color primaryColor = const Color(0xFF4A90E2);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(
            widget.initialName != null ? "تأكيد الدواء" : "إضافة دواء جديد"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            // حقل الاسم
            _buildTextField(
              controller: nameController,
              hint: "اسم الدواء",
              icon: Icons.medication,
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // حقل الوصف (الكومنت)
            _buildTextField(
              controller: descController,
              hint: "وصف العلاج أو ملاحظات (اختياري)",
              icon: Icons.description,
              isDark: isDark,
              maxLines: 4,
            ),
            const SizedBox(height: 20),

            // اختيار الوقت
            GestureDetector(
              onTap: () async {
                TimeOfDay? picked = await showTimePicker(
                    context: context, initialTime: selectedTime);
                if (picked != null) setState(() => selectedTime = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, color: primaryColor),
                        const SizedBox(width: 15),
                        const Text("وقت الجرعة",
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    Text(
                      selectedTime.format(context),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 50),

            // زر الحفظ بتأثير علامة الصح
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSaving ? Colors.green : primaryColor,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: isSaving ? null : _handleSave,
              child: isSaving
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 10),
                        Text("تم الحفظ بنجاح",
                            style:
                                TextStyle(color: Colors.white, fontSize: 18)),
                      ],
                    )
                  : const Text("حفظ البيانات",
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

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      required bool isDark,
      int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF4A90E2)),
        filled: true,
        fillColor: isDark ? Colors.white10 : Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
      ),
    );
  }
}
