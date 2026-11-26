import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_provider.dart';
import '../login/singup/login_screen.dart';
import 'account_screen.dart';
import 'meal_times_setup_dialog.dart';
import 'link_machine_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String currentName;
  final int currentYear;

  const SettingsScreen({
    super.key,
    required this.currentName,
    required this.currentYear,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = '';
  String _userEmail = '';
  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 21, minute: 0);

  @override
  void initState() {
    super.initState();
    _userName = widget.currentName;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _userName = data['name'] ?? widget.currentName;
          _userEmail = data['email'] ?? user.email ?? '';

          // نحمل أوقات الوجبات
          final mealTimes = data['mealTimes'] as Map<String, dynamic>?;
          if (mealTimes != null) {
            _breakfastTime = _parseTime(mealTimes['breakfast'] ?? '08:00');
            _lunchTime = _parseTime(mealTimes['lunch'] ?? '14:00');
            _dinnerTime = _parseTime(mealTimes['dinner'] ?? '21:00');
          }
        });
      }
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
        hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _saveMealTimes() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'mealTimes': {
        'breakfast':
            '${_breakfastTime.hour.toString().padLeft(2, '0')}:${_breakfastTime.minute.toString().padLeft(2, '0')}',
        'lunch':
            '${_lunchTime.hour.toString().padLeft(2, '0')}:${_lunchTime.minute.toString().padLeft(2, '0')}',
        'dinner':
            '${_dinnerTime.hour.toString().padLeft(2, '0')}:${_dinnerTime.minute.toString().padLeft(2, '0')}',
      },
      'mealTimesSet': true,
    });
  }

  Future<void> _pickTime(String meal, bool isAr) async {
    final initial = meal == 'breakfast'
        ? _breakfastTime
        : meal == 'lunch'
            ? _lunchTime
            : _dinnerTime;

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      setState(() {
        if (meal == 'breakfast') _breakfastTime = picked;
        if (meal == 'lunch') _lunchTime = picked;
        if (meal == 'dinner') _dinnerTime = picked;
      });
      await _saveMealTimes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم حفظ الوقت ✓' : 'Time saved ✓'),
            backgroundColor: Colors.green,
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
    const Color primary = Color(0xFF4A90E2);

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
                  isAr ? "الإعدادات" : "Settings",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 22),
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 8),
                  children: [
                    // ===== بروفايل =====
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AccountScreen(
                              currentName: _userName,
                              currentYear: widget.currentYear,
                            ),
                          ),
                        );
                        _loadUserData();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  )
                                ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4A90E2),
                                    Color(0xFF60A5FA)
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: const Icon(Icons.person_rounded,
                                  color: Colors.white, size: 34),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _userName.isEmpty
                                        ? (isAr ? "المستخدم" : "User")
                                        : _userName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _userEmail.isEmpty
                                        ? (isAr
                                            ? "لا يوجد إيميل"
                                            : "No email")
                                        : _userEmail,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black45,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isAr
                                        ? "اضغط لتعديل بياناتك"
                                        : "Tap to edit your profile",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF4A90E2),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 18, color: Color(0xFF4A90E2)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ===== التفضيلات =====
                    _buildSectionCard(
                      isDark: isDark,
                      title: isAr ? "التفضيلات" : "Preferences",
                      icon: Icons.tune_rounded,
                      primary: primary,
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            isDark: isDark,
                            title:
                                isAr ? "الوضع الليلي" : "Dark Mode",
                            icon: isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            value: appProvider.themeMode ==
                                ThemeMode.dark,
                            onChanged: (val) =>
                                appProvider.toggleTheme(val),
                            primary: primary,
                          ),
                          const SizedBox(height: 8),
                          _buildListTile(
                            isDark: isDark,
                            title: isAr ? "اللغة" : "Language",
                            subtitle: isAr ? "العربية" : "English",
                            icon: Icons.translate_rounded,
                            primary: primary,
                            onTap: () => _showLanguageMenu(
                                context, appProvider),
                          ),
                          const SizedBox(height: 8),
                          // ===== زر ربط الماكينة الجديد =====
                          _buildListTile(
                            isDark: isDark,
                            title: isAr ? "ربط الماكينة" : "Link Machine",
                            subtitle: isAr ? "اربط ماكينة الدواء بحسابك" : "Link your pill dispenser",
                            icon: Icons.medication_liquid_rounded,
                            primary: primary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LinkMachineScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ===== أوقات الوجبات =====
                    _buildSectionCard(
                      isDark: isDark,
                      title:
                          isAr ? "أوقات الوجبات" : "Meal Times",
                      icon: Icons.restaurant_rounded,
                      primary: primary,
                      child: Column(
                        children: [
                          _mealTimeTile(
                            emoji: '🌅',
                            label: isAr ? 'الفطار' : 'Breakfast',
                            time: _breakfastTime,
                            primary: primary,
                            isDark: isDark,
                            onTap: () =>
                                _pickTime('breakfast', isAr),
                          ),
                          Divider(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.black12),
                          _mealTimeTile(
                            emoji: '☀️',
                            label: isAr ? 'الغداء' : 'Lunch',
                            time: _lunchTime,
                            primary: primary,
                            isDark: isDark,
                            onTap: () => _pickTime('lunch', isAr),
                          ),
                          Divider(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.black12),
                          _mealTimeTile(
                            emoji: '🌙',
                            label: isAr ? 'العشاء' : 'Dinner',
                            time: _dinnerTime,
                            primary: primary,
                            isDark: isDark,
                            onTap: () =>
                                _pickTime('dinner', isAr),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ===== زرار اللوجاوت =====
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Colors.redAccent),
                        foregroundColor: Colors.redAccent,
                        minimumSize:
                            const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(
                          isAr ? "تسجيل الخروج" : "Log out"),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (!mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) =>
                                  const LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mealTimeTile({
    required String emoji,
    required String label,
    required TimeOfDay time,
    required Color primary,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                time.format(context),
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : Colors.black26,
                size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color primary,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: primary),
            const SizedBox(width: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required bool isDark,
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color primary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        title: Text(title),
        secondary: Icon(icon, color: primary),
        value: value,
        onChanged: onChanged,
        activeColor: primary,
      ),
    );
  }

  Widget _buildListTile({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color primary,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark
          ? Colors.white.withOpacity(0.06)
          : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          child: Row(children: [
            Icon(icon, color: primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.grey),
          ]),
        ),
      ),
    );
  }

  void _showLanguageMenu(
      BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child:
            Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            title: const Text("العربية"),
            onTap: () {
              provider.changeLanguage('ar');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text("English"),
            onTap: () {
              provider.changeLanguage('en');
              Navigator.pop(context);
            },
          ),
        ]),
      ),
    );
  }
}