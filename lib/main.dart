import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_provider.dart';
import 'notification_service.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. تشغيل الفايربيز (استبدلي ببياناتك الخاصة)
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyCxAD4VF4_DvaXphgzToABdmQssQllqEC0',
      appId: '1:430415978948:android:55bac4ee4fe08af1794491',
      messagingSenderId: '430415978948',
      projectId: 'medicationtracker-31883',
      storageBucket: 'medicationtracker-31883.firebasestorage.app',
    ),
  );

  // 2. تشغيل خدمة التنبيهات
  await NotificationService().init();

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: const MedicationApp(),
    ),
  );
}

class MedicationApp extends StatelessWidget {
  const MedicationApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ECHO',
      themeMode: appProvider.themeMode,
      locale: appProvider.locale,

      // دعم اللغات لقلب واجهة المستخدم
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''),
        Locale('en', ''),
      ],

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: const Color(0xFF4A90E2),
        scaffoldBackgroundColor: const Color(0xFFF8FAFF),
        fontFamily: 'Cairo',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const SplashScreen(),
    );
  }
}
