import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_service.dart';
import 'app_provider.dart';
import 'notification_service.dart';
import 'add_medicine_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final int birthYear;
  const HomeScreen(
      {super.key, required this.userName, required this.birthYear});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _notificationPromptShown = false;

  // دالة إظهار تفاصيل الدواء (الكومنت) في Pop-up
  void _showMedicineDetails(BuildContext context, String name, String? desc,
      String time, bool isDark, bool isAr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF4A90E2)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black, fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${isAr ? 'وقت الجرعة' : 'Dose Time'}: $time",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              isAr ? "الملاحظات:" : "Notes:",
              style: const TextStyle(
                  color: Color(0xFF4A90E2), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              (desc == null || desc.isEmpty)
                  ? (isAr ? "لا توجد ملاحظات إضافية" : "No additional notes")
                  : desc,
              style: TextStyle(
                  fontSize: 16, color: isDark ? Colors.white : Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isAr ? "إغلاق" : "Close",
                style: const TextStyle(
                    color: Color(0xFF4A90E2), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    bool isAr = appProvider.locale.languageCode == 'ar';
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color primaryColor = const Color(0xFF4A90E2);

    // أول ما نوصل للهوم، نسأل المستخدم عن تفعيل التنبيهات مرة واحدة
    if (!_notificationPromptShown) {
      _notificationPromptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final enabled = await NotificationService().areNotificationsEnabled();
        if (!enabled && mounted) {
          _showNotificationDialog(context, isAr, primaryColor);
        }
      });
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFF),
      body: Column(
        children: [
          // 1. الجزء العلوي (Header) - كما هو
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              String currentName = widget.userName;
              int currentYear = widget.birthYear;

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                var userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                currentName = userData['name'] ?? widget.userName;
                currentYear = userData['birthYear'] ?? widget.birthYear;
              }

              int age = DateTime.now().year - currentYear;

              return Container(
                padding: const EdgeInsets.only(
                    top: 52, left: 24, right: 24, bottom: 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF1E293B),
                            const Color(0xFF0F172A),
                          ]
                        : [
                            const Color(0xFF4A90E2),
                            const Color(0xFF3B82F6),
                          ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr
                              ? "أهلاً يا $currentName"
                              : "Welcome, $currentName",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isAr ? "العمر: $age سنة" : "Age: $age years",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Material(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsScreen(
                              currentName: currentName,
                              currentYear: currentYear,
                            ),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.settings_rounded,
                            size: 26,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // 2. قائمة الأدوية المحدثة
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService().getMedicinesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            Icons.medication_liquid_rounded,
                            size: 64,
                            color: primaryColor.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          isAr ? "لا توجد جرعات مضافة" : "No doses added yet",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAr ? "اضغط + لإضافة دواء" : "Tap + to add a medicine",
                          style: TextStyle(
                            color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  padding: const EdgeInsets.all(20),
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data()
                        as Map<String, dynamic>;
                    String docId = snapshot.data!.docs[index].id;

                    return GestureDetector(
                      // التعديل هنا: عند الضغط يظهر الـ Pop-up
                      onTap: () => _showMedicineDetails(
                          context,
                          data['name'],
                          data['description'], // الكومنت
                          data['time'],
                          isDark,
                          isAr),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: isDark
                              ? Border.all(
                                  color: Colors.white.withValues(alpha: 0.06))
                              : null,
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        primaryColor,
                                        primaryColor.withValues(alpha: 0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.medication_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['name'],
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${isAr ? 'الموعد' : 'Time'}: ${data['time']}",
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  int notifyId = int.parse(
                                      docId.substring(docId.length - 6));
                                  await NotificationService()
                                      .cancelNotification(notifyId);
                                  FirebaseService().deleteMedicine(docId);
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: isAr ? "الرئيسية" : "Home",
                  isSelected: true,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () {},
                ),
                _NavItem(
                  icon: Icons.add_circle_rounded,
                  label: isAr ? "إضافة" : "Add",
                  isSelected: false,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddMedicineScreen()),
                  ),
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: isAr ? "الإعدادات" : "Settings",
                  isSelected: false,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(
                        currentName: widget.userName,
                        currentYear: widget.birthYear,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationDialog(
      BuildContext context, bool isAr, Color primaryColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.notifications_active, color: primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isAr ? "تفعيل التنبيهات" : "Enable reminders",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          isAr
              ? "هل تريد أن يصلك تنبيه عند موعد كل جرعة دواء؟ يمكنك تغيير هذا لاحقاً من الإعدادات."
              : "Do you want to receive a notification at each dose time? You can change this later from Settings.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isAr ? "لاحقاً" : "Later"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final allowed =
                  await NotificationService().enableNotifications();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(allowed
                      ? (isAr
                          ? "تم تفعيل التنبيهات بنجاح"
                          : "Reminders enabled successfully")
                      : (isAr
                          ? "لم يتم منح صلاحية الإشعارات من النظام"
                          : "Notification permission was not granted"))));
            },
            child: Text(
              isAr ? "تفعيل" : "Enable",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isSelected ? 28 : 26,
              color: isSelected ? primaryColor : (isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryColor : (isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
