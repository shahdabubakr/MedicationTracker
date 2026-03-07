import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_provider.dart';
import 'firebase_service.dart';
import 'notification_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String currentName;
  final int currentYear;
  const SettingsScreen(
      {super.key, required this.currentName, required this.currentYear});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController nameController;
  int? selectedYear;
  bool _notificationsOn = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
    selectedYear = widget.currentYear;
    _loadNotif();
  }

  Future<void> _loadNotif() async {
    _notificationsOn = await NotificationService().areNotificationsEnabled();
    if (mounted) setState(() {});
  }

  // دالة التقويم الذكي
  Future<void> _pickYear(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(selectedYear ?? 2000),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year, // لفتح السنين مباشرة
    );
    if (picked != null) setState(() => selectedYear = picked.year);
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
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: [
                    _buildSectionCard(
                      isDark: isDark,
                      title: isAr ? "بيانات الحساب" : "Account Info",
                      icon: Icons.person_rounded,
                      primary: primary,
                      child: Column(
                        children: [
                          TextField(
                            controller: nameController,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: isAr ? "الاسم" : "Name",
                              labelStyle: TextStyle(
                                color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                              ),
                              prefixIcon: const Icon(Icons.person_outline_rounded, color: primary, size: 22),
                              filled: true,
                              fillColor: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: () => _pickYear(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_rounded, color: primary, size: 22),
                                  const SizedBox(width: 14),
                                  Text(
                                    isAr ? "سنة الميلاد" : "Birth Year",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    selectedYear.toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right_rounded, color: primary, size: 24),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Material(
                            borderRadius: BorderRadius.circular(16),
                            shadowColor: primary.withValues(alpha: 0.4),
                            elevation: 6,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                await FirebaseService()
                                    .updateUserProfile(nameController.text, selectedYear!);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                        isAr ? "تم تحديث البيانات" : "Updated Successfully")));
                              },
                              child: Text(
                                isAr ? "تحديث" : "Update",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionCard(
                      isDark: isDark,
                      title: isAr ? "التفضيلات" : "Preferences",
                      icon: Icons.tune_rounded,
                      primary: primary,
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            isDark: isDark,
                            title: isAr ? "الوضع الليلي" : "Dark Mode",
                            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            value: appProvider.themeMode == ThemeMode.dark,
                            onChanged: (val) => appProvider.toggleTheme(val),
                            primary: primary,
                          ),
                          _buildListTile(
                            isDark: isDark,
                            title: isAr ? "اللغة" : "Language",
                            subtitle: isAr ? "العربية" : "English",
                            icon: Icons.translate_rounded,
                            primary: primary,
                            onTap: () => _showLanguageMenu(context, appProvider),
                          ),
                          _buildSwitchTile(
                            isDark: isDark,
                            title: isAr ? "تنبيهات الجرعات" : "Dose reminders",
                            icon: Icons.notifications_active_rounded,
                            value: _notificationsOn,
                            onChanged: (val) async {
                              if (val) {
                                final allowed =
                                    await NotificationService().enableNotifications();
                                _notificationsOn = allowed;
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(allowed
                                        ? (isAr
                                            ? "تم تفعيل التنبيهات بنجاح"
                                            : "Reminders enabled successfully")
                                        : (isAr
                                            ? "لم يتم منح صلاحية الإشعارات من النظام"
                                            : "Notification permission was not granted"))));
                              } else {
                                await NotificationService().disableNotifications();
                                _notificationsOn = false;
                              }
                              if (!mounted) return;
                              setState(() {});
                            },
                            primary: primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent, width: 1.5),
                        foregroundColor: Colors.redAccent,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 22),
                      label: Text(
                        isAr ? "تسجيل الخروج" : "Log out",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
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
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.08)) : null,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: SwitchListTile(
          title: Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1F2937),
              fontWeight: FontWeight.w500,
            ),
          ),
          secondary: Icon(icon, color: primary, size: 22),
          value: value,
          onChanged: onChanged,
          activeColor: primary,
        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: primary, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF4A90E2), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageMenu(BuildContext context, AppProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              provider.locale.languageCode == 'ar' ? "اللغة" : "Language",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            _langOption(context, provider, "العربية", "ar", isDark),
            _langOption(context, provider, "English", "en", isDark),
          ],
        ),
      ),
    );
  }

  Widget _langOption(
      BuildContext context, AppProvider provider, String label, String code, bool isDark) {
    final isSelected = provider.locale.languageCode == code;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Icon(
        Icons.language_rounded,
        color: isSelected ? const Color(0xFF4A90E2) : (isDark ? Colors.white54 : const Color(0xFF6B7280)),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF1F2937),
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4A90E2)) : null,
      onTap: () {
        provider.changeLanguage(code);
        Navigator.pop(context);
      },
    );
  }
}
