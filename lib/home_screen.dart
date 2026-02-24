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
                    top: 60, left: 25, right: 25, bottom: 25),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
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
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isAr ? "العمر: $age سنة" : "Age: $age years",
                          style: TextStyle(
                              color: primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon:
                          Icon(Icons.person_pin, size: 35, color: primaryColor),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsScreen(
                            currentName: currentName,
                            currentYear: currentYear,
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
                        Icon(
                          Icons.medication_liquid_sharp,
                          size: 130,
                          color: isDark ? Colors.white10 : Colors.grey[200],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isAr ? "لا توجد جرعات مضافة" : "No doses added yet",
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 18),
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
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.medication,
                                      color: primaryColor),
                                ),
                                const SizedBox(width: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['name'],
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "${isAr ? 'الموعد' : 'Time'}: ${data['time']}",
                                      style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              onPressed: () async {
                                int notifyId = int.parse(
                                    docId.substring(docId.length - 6));
                                await NotificationService()
                                    .cancelNotification(notifyId);
                                FirebaseService().deleteMedicine(docId);
                              },
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

      // 3. البار السفلي - كما هو
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AddMedicineScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsScreen(
                  currentName: widget.userName,
                  currentYear: widget.birthYear,
                ),
              ),
            );
          }
        },
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_filled, size: 28), label: ""),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 45, color: Color(0xFF4A90E2)),
            label: "",
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded, size: 28), label: ""),
        ],
      ),
    );
  }
}
