import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_provider.dart';
import '../login/singup/login_screen.dart';

class AccountScreen extends StatefulWidget {
  final String currentName;
  final int currentYear;

  const AccountScreen({
    super.key,
    required this.currentName,
    required this.currentYear,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late TextEditingController nameController;
  late TextEditingController otherDiseaseController;

  int? selectedYear;
  String? selectedBloodType;
  String? selectedGender;
  List<String> selectedDiseases = [];
  bool showOtherField = false;
  bool isEditing = false;
  bool isLoading = false;
  String userEmail = '';

  final List<String> bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
  ];

  List<String> _getDiseasesList(bool isAr) => isAr
      ? ['السكر', 'الضغط', 'حساسية', 'قلب', 'ربو']
      : ['Diabetes', 'Hypertension', 'Allergy', 'Heart Disease', 'Asthma'];

  final List<String> _diseasesKeys = [
    'Diabetes', 'Hypertension', 'Allergy', 'Heart Disease', 'Asthma'
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
    otherDiseaseController = TextEditingController();
    selectedYear = widget.currentYear;
    _loadUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    otherDiseaseController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userEmail = user.email ?? '';
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null && mounted) {
        final data = doc.data()!;
        setState(() {
          nameController.text = data['name'] ?? widget.currentName;
          selectedYear = data['birthYear'] ?? widget.currentYear;
          selectedBloodType = data['bloodType'];
          selectedGender = data['gender'];
          selectedDiseases = List<String>.from(data['chronicDiseases'] ?? []);
        });
      }
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _saveData(bool isAr) async {
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      List<String> finalDiseases = List<String>.from(selectedDiseases);
      if (showOtherField && otherDiseaseController.text.isNotEmpty) {
        finalDiseases.add(otherDiseaseController.text.trim());
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'name': nameController.text.trim(),
        'birthYear': selectedYear,
        'bloodType': selectedBloodType,
        'gender': selectedGender,
        'chronicDiseases': finalDiseases,
      });

      if (mounted) {
        setState(() => isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? "تم حفظ التعديلات بنجاح" : "Saved successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _deleteAccount(bool isAr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isAr ? "حذف الحساب" : "Delete Account",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(
          isAr
              ? "هل أنت متأكد؟ سيتم حذف حسابك وجميع بياناتك وأدويتك نهائياً."
              : "Are you sure? Your account, data, and medicines will be permanently deleted.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isAr ? "إلغاء" : "Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isAr ? "حذف نهائي" : "Delete",
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. حذف كل الأدوية
      final medicinesSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medicines')
          .get();
      for (final doc in medicinesSnap.docs) {
        await doc.reference.delete();
      }

      // 2. حذف بيانات المستخدم
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // 3. حذف الحساب من Firebase Auth
      await user.delete();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAr
                  ? "يرجى تسجيل الدخول مجدداً ثم حذف الحساب"
                  : "Please login again to delete your account"),
              backgroundColor: Colors.orangeAccent,
            ),
          );
          // نسجل خروج ونرجعه للوجين
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _pickYear(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(selectedYear ?? widget.currentYear),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) setState(() => selectedYear = picked.year);
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    bool isAr = appProvider.locale.languageCode == 'ar';
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primary = Color(0xFF4A90E2);
    final diseasesList = _getDiseasesList(isAr);

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
                  isAr ? "بيانات الحساب" : "Account Info",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 16),
                    child: isLoading
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF4A90E2)),
                          )
                        : TextButton(
                            onPressed: () {
                              if (isEditing) {
                                _saveData(isAr);
                              } else {
                                setState(() => isEditing = true);
                              }
                            },
                            child: Text(
                              isEditing ? (isAr ? "حفظ" : "Save") : (isAr ? "تعديل" : "Edit"),
                              style: const TextStyle(
                                color: Color(0xFF4A90E2),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              Expanded(
                child: isLoading && !isEditing
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A90E2)))
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        children: [
                          Center(
                            child: Container(
                              width: 90, height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4A90E2), Color(0xFF60A5FA)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withOpacity(0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              child: const Icon(Icons.person_rounded, color: Colors.white, size: 48),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ===== البيانات الشخصية =====
                          _buildCard(
                            isDark: isDark,
                            title: isAr ? "البيانات الشخصية" : "Personal Info",
                            icon: Icons.person_rounded,
                            primary: primary,
                            child: Column(
                              children: [
                                _buildField(
                                  label: isAr ? "الاسم" : "Name",
                                  icon: Icons.person_outline_rounded,
                                  controller: nameController,
                                  enabled: isEditing,
                                  isDark: isDark,
                                  primary: primary,
                                ),
                                const SizedBox(height: 14),

                                // الإيميل - غير قابل للتعديل
                                GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isAr
                                            ? "لا يمكن تعديل البريد الإلكتروني"
                                            : "Email cannot be changed"),
                                        backgroundColor: Colors.orangeAccent,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.email_outlined, color: primary.withOpacity(0.5), size: 22),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isAr ? "البريد الإلكتروني" : "Email",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark ? Colors.white38 : Colors.black38,
                                                ),
                                              ),
                                              Text(
                                                userEmail,
                                                style: TextStyle(
                                                  color: isDark ? Colors.white54 : Colors.black54,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.lock_outline_rounded,
                                            color: isDark ? Colors.white24 : Colors.black26, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // الجنس
                                _buildGenderDropdown(isAr, isDark, primary),
                                const SizedBox(height: 14),

                                // سنة الميلاد
                                InkWell(
                                  onTap: isEditing ? () => _pickYear(context) : null,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.08)
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_month_rounded, color: primary, size: 22),
                                        const SizedBox(width: 14),
                                        Text(
                                          isAr ? "سنة الميلاد" : "Birth Year",
                                          style: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                                        ),
                                        const Spacer(),
                                        Text(
                                          selectedYear.toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : primary,
                                          ),
                                        ),
                                        if (isEditing)
                                          Icon(Icons.chevron_right_rounded, color: primary),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ===== البيانات الصحية =====
                          _buildCard(
                            isDark: isDark,
                            title: isAr ? "البيانات الصحية" : "Health Info",
                            icon: Icons.medical_services_rounded,
                            primary: primary,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  value: selectedBloodType,
                                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                  decoration: _inputDecoration(
                                    isAr ? "فصيلة الدم" : "Blood Type",
                                    Icons.bloodtype_rounded, isDark, primary,
                                  ),
                                  items: bloodTypes
                                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                                      .toList(),
                                  onChanged: isEditing
                                      ? (val) => setState(() => selectedBloodType = val)
                                      : null,
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  isAr ? "الأمراض المزمنة:" : "Chronic Diseases:",
                                  style: TextStyle(
                                      color: isDark ? Colors.white70 : Colors.black54, fontSize: 14),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    ...List.generate(diseasesList.length, (i) {
                                      final key = _diseasesKeys[i];
                                      final label = diseasesList[i];
                                      final isSelected = selectedDiseases.contains(key);
                                      return FilterChip(
                                        label: Text(label),
                                        selected: isSelected,
                                        selectedColor: primary.withOpacity(0.2),
                                        checkmarkColor: primary,
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? primary
                                              : (isDark ? Colors.white70 : Colors.black87),
                                        ),
                                        backgroundColor: isDark
                                            ? Colors.white.withOpacity(0.05)
                                            : Colors.grey[200],
                                        onSelected: isEditing
                                            ? (val) => setState(() {
                                                  val
                                                      ? selectedDiseases.add(key)
                                                      : selectedDiseases.remove(key);
                                                })
                                            : null,
                                      );
                                    }),
                                    FilterChip(
                                      label: Text(isAr ? "أخرى" : "Other"),
                                      selected: showOtherField,
                                      selectedColor: primary.withOpacity(0.2),
                                      checkmarkColor: primary,
                                      labelStyle: TextStyle(
                                        color: showOtherField
                                            ? primary
                                            : (isDark ? Colors.white70 : Colors.black87),
                                      ),
                                      backgroundColor: isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.grey[200],
                                      onSelected: isEditing
                                          ? (val) => setState(() {
                                                showOtherField = val;
                                                if (!val) otherDiseaseController.clear();
                                              })
                                          : null,
                                    ),
                                  ],
                                ),
                                if (showOtherField && isEditing) ...[
                                  const SizedBox(height: 12),
                                  _buildField(
                                    label: isAr ? "اكتب المرض هنا" : "Type disease here",
                                    icon: Icons.edit_note_rounded,
                                    controller: otherDiseaseController,
                                    enabled: true,
                                    isDark: isDark,
                                    primary: primary,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // زرار حفظ/تعديل
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (isEditing) {
                                        _saveData(isAr);
                                      } else {
                                        setState(() => isEditing = true);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isEditing ? primary : Colors.transparent,
                                foregroundColor: isEditing ? Colors.white : primary,
                                elevation: isEditing ? 2 : 0,
                                side: BorderSide(color: primary, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24, height: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Text(
                                      isEditing
                                          ? (isAr ? "حفظ التعديلات" : "Save Changes")
                                          : (isAr ? "تعديل البيانات" : "Edit Info"),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // زرار حذف الحساب
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red, width: 1.5),
                                foregroundColor: Colors.red,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: const Icon(Icons.delete_forever_rounded),
                              label: Text(
                                isAr ? "حذف الحساب نهائياً" : "Delete Account",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              onPressed: isLoading ? null : () => _deleteAccount(isAr),
                            ),
                          ),

                          const SizedBox(height: 28),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color primary,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: primary),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool enabled,
    required bool isDark,
    required Color primary,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: _inputDecoration(label, icon, isDark, primary),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, bool isDark, Color primary) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primary, size: 22),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );
  }

  Widget _buildGenderDropdown(bool isAr, bool isDark, Color primary) {
    return DropdownButtonFormField<String>(
      value: selectedGender,
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: _inputDecoration(isAr ? "الجنس" : "Gender", Icons.wc_rounded, isDark, primary),
      hint: Text(
        isAr ? "غير محدد" : "Not specified",
        style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
      ),
      items: [
        DropdownMenuItem(value: "Male", child: Text(isAr ? "ذكر" : "Male")),
        DropdownMenuItem(value: "Female", child: Text(isAr ? "أنثى" : "Female")),
      ],
      onChanged: isEditing ? (val) => setState(() => selectedGender = val) : null,
    );
  }
}