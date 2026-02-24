import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('ar');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  AppProvider() {
    _loadSettings();
  }

  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // تحميل الثيم
    bool? isDark = prefs.getBool('isDark');
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    }

    // تحميل اللغة
    String? lang = prefs.getString('lang');
    if (lang != null) {
      _locale = Locale(lang);
    }
    notifyListeners();
  }

  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDark', isDark);
    notifyListeners();
  }

  void changeLanguage(String langCode) async {
    _locale = Locale(langCode);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('lang', langCode);
    notifyListeners(); // هذا السطر هو من يُخبر MaterialApp بتغيير اللغة
  }
}