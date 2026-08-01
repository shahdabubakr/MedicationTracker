import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_service.dart';
import 'app_provider.dart';
import 'notification_service.dart';
import 'add_medicine_screen.dart';
import 'settings/settings_screen.dart';
import 'MedicineSearchScreen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final int birthYear;
  const HomeScreen({
    super.key,
    required this.userName,
    required this.birthYear,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _notificationPromptShown = false;
  final Map<String, String> _scheduledByDocId = {};
  bool _scheduling = false;

  Future<void> _ensureNotificationsScheduled(
      List<QueryDocumentSnapshot> docs) async {
    if (_scheduling) return;
    _scheduling = true;
    try {
      if (!await NotificationService().ensureCanScheduleMedicationReminders()) {
        return;
      }

      final currentIds = docs.map((d) => d.id).toSet();
      _scheduledByDocId.removeWhere((key, value) => !currentIds.contains(key));

      for (final doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String name = (data['name'] ?? '').toString().trim();
        final String time = (data['time'] ?? '').toString().trim();
        if (name.isEmpty || time.isEmpty) continue;

        final String lastScheduledTime = _scheduledByDocId[doc.id] ?? '';
        if (lastScheduledTime == time) continue;

        final int notifyId =
            NotificationService.notificationIdFromDocId(doc.id);

        // سطر التعديل: استخراج لغة التطبيق الحالية لتمريرها للإشعار
        bool currentIsAr = Provider.of<AppProvider>(context, listen: false)
                .locale
                .languageCode ==
            'ar';

        await NotificationService()
            .scheduleNotification(notifyId, name, time, currentIsAr);
        _scheduledByDocId[doc.id] = time;
      }
    } finally {
      _scheduling = false;
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String docId,
    String name,
    String time,
    String? desc,
    bool isAr,
    bool isDark,
    Color primaryColor,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 40),
            const SizedBox(height: 10),
            Text(
              isAr ? "تأكيد الحذف" : "Confirm Delete",
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr
                  ? "هل أنت متأكد من حذف هذا الدواء؟"
                  : "Are you sure you want to delete this medicine?",
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${isAr ? 'الدواء' : 'Medicine'}: $name",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("${isAr ? 'الموعد' : 'Time'}: $time"),
                  if (desc != null && desc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text("${isAr ? 'الملاحظات' : 'Notes'}: $desc",
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isAr ? "إلغاء" : "Cancel",
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final notifyId =
                  NotificationService.notificationIdFromDocId(docId);
              await NotificationService().cancelNotification(notifyId);
              await FirebaseService().deleteMedicine(docId);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isAr
                        ? "تم حذف الدواء بنجاح"
                        : "Medicine deleted successfully"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text(isAr ? "حذف" : "Delete",
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMedicineDetails(
    BuildContext context,
    String name,
    String? desc,
    String time,
    bool isDark,
    bool isAr,
  ) {
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
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 20,
                ),
                softWrap: true,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${isAr ? 'وقت الجرعة' : 'Dose Time'}: $time",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              const Divider(),
              const SizedBox(height: 10),
              Text(
                isAr ? "الملاحظات:" : "Notes:",
                style: const TextStyle(
                  color: Color(0xFF4A90E2),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (desc == null || desc.isEmpty)
                    ? (isAr ? "لا توجد ملاحظات إضافية" : "No additional notes")
                    : desc,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                softWrap: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isAr ? "إغلاق" : "Close",
              style: const TextStyle(
                color: Color(0xFF4A90E2),
                fontWeight: FontWeight.bold,
              ),
            ),
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

    if (!_notificationPromptShown) {
      _notificationPromptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final prompt = await NotificationService().shouldPromptForPermission();
        if (prompt && mounted) {
          _showNotificationDialog(context, isAr, primaryColor);
        }
      });
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFF),
      body: Column(
        children: [
          _buildHeader(isAr, isDark, primaryColor),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService().getMedicinesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(isAr, isDark, primaryColor);
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _ensureNotificationsScheduled(
                      snapshot.data!.docs.cast<QueryDocumentSnapshot>());
                });

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  padding: const EdgeInsets.all(20),
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data()
                        as Map<String, dynamic>;
                    String docId = snapshot.data!.docs[index].id;
                    return _buildMedicineCard(
                        data, docId, isAr, isDark, primaryColor, context);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          _buildBottomNavigationBar(isAr, isDark, primaryColor),
    );
  }

  Widget _buildMedicineCard(Map data, String docId, bool isAr, bool isDark,
      Color primaryColor, BuildContext context) {
    return GestureDetector(
      onTap: () => _showMedicineDetails(context, data['name'],
          data['description'], data['time'], isDark, isAr),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.8)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.medication_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'],
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${isAr ? 'الموعد' : 'Time'}: ${data['time']}",
                    style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  color: primaryColor.withOpacity(0.7)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMedicineScreen(
                      docId: docId,
                      existingData: Map<String, dynamic>.from(data),
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent),
              onPressed: () => _showDeleteConfirmation(
                  context,
                  docId,
                  data['name'],
                  data['time'],
                  data['description'],
                  isAr,
                  isDark,
                  primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isAr, bool isDark, Color primaryColor) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        String currentName = widget.userName;
        int currentYear = widget.birthYear;

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          currentName = userData['name'] ?? widget.userName;
          currentYear = userData['birthYear'] ?? widget.birthYear;
        }

        // --- التعديل هنا: استخراج الاسم الأول فقط ---
        String firstName = currentName.trim().split(' ')[0];
        // --------------------------------------------

        int age = DateTime.now().year - currentYear;

        return Container(
          padding:
              const EdgeInsets.only(top: 52, left: 24, right: 24, bottom: 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFF4A90E2), const Color(0xFF3B82F6)],
            ),
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? "أهلاً يا $firstName" : "Welcome, $firstName",
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(isAr ? "العمر: $age سنة" : "Age: $age years",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search_rounded,
                    color: Colors.white, size: 28),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            MedicineSearchScreen(isAr: isAr, isDark: isDark))),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isAr, bool isDark, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication_liquid_rounded,
              size: 64, color: primaryColor.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(isAr ? "لا توجد جرعات مضافة" : "No doses added yet",
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.blueGrey,
                  fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(bool isAr, bool isDark, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                  icon: Icons.home_rounded,
                  label: isAr ? "الرئيسية" : "Home",
                  isSelected: true,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () {}),
              _NavItem(
                  icon: Icons.add_circle_rounded,
                  label: isAr ? "إضافة" : "Add",
                  isSelected: false,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddMedicineScreen()))),
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
                              currentYear: widget.birthYear)))),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDialog(
      BuildContext context, bool isAr, Color primaryColor) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: primaryColor),
            const SizedBox(width: 10),
            Text(isAr ? "تفعيل الإشعارات" : "Enable Notifications"),
          ],
        ),
        content: Text(
          isAr
              ? "هل تريد تلقي تنبيهات بمواعيد جرعاتك؟"
              : "Do you want to receive dose reminders?",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await NotificationService().declineNotificationPrompt();
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
              isAr ? "لا" : "No",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () async {
              Navigator.pop(context);
              await NotificationService().enableNotifications();
              if (mounted) setState(() {});
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

  const _NavItem(
      {required this.icon,
      required this.label,
      required this.isSelected,
      required this.primaryColor,
      required this.isDark,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: isSelected
                  ? primaryColor
                  : (isDark ? Colors.white54 : Colors.grey)),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? primaryColor
                      : (isDark ? Colors.white54 : Colors.grey))),
        ],
      ),
    );
  }
}
