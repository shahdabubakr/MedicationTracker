import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';
import 'firebase_service.dart';

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

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
    selectedYear = widget.currentYear;
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

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(isAr ? "الإعدادات" : "Settings"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(25),
        children: [
          _buildHeader(isAr ? "بيانات الحساب" : "Account Info"),
          const SizedBox(height: 15),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: isAr ? "الاسم" : "Name",
              prefixIcon:
                  const Icon(Icons.person_outline, color: Color(0xFF4A90E2)),
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 15),

          // حقل التقويم الجديد بدلاً من الـ TextField
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading:
                  const Icon(Icons.calendar_month, color: Color(0xFF4A90E2)),
              title: Text(isAr ? "سنة الميلاد" : "Birth Year"),
              subtitle: Text(selectedYear.toString()),
              trailing: const Icon(Icons.edit, size: 20),
              onTap: () => _pickYear(context),
            ),
          ),

          const SizedBox(height: 25),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () async {
              await FirebaseService()
                  .updateUserProfile(nameController.text, selectedYear!);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      isAr ? "تم تحديث البيانات" : "Updated Successfully")));
            },
            child: Text(isAr ? "تحديث" : "Update",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 50),
          _buildHeader(isAr ? "التفضيلات" : "Preferences"),
          SwitchListTile(
            title: Text(isAr ? "الوضع الليلي" : "Dark Mode"),
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                color: const Color(0xFF4A90E2)),
            value: appProvider.themeMode == ThemeMode.dark,
            onChanged: (val) => appProvider.toggleTheme(val),
          ),
          ListTile(
            title: Text(isAr ? "اللغة" : "Language"),
            leading: const Icon(Icons.translate, color: Color(0xFF4A90E2)),
            subtitle: Text(isAr ? "العربية" : "English"),
            onTap: () => _showLanguageMenu(context, appProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) => Text(title,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A90E2)));

  void _showLanguageMenu(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                title: const Text("العربية"),
                onTap: () {
                  provider.changeLanguage('ar');
                  Navigator.pop(context);
                }),
            ListTile(
                title: const Text("English"),
                onTap: () {
                  provider.changeLanguage('en');
                  Navigator.pop(context);
                }),
          ],
        ),
      ),
    );
  }
}
