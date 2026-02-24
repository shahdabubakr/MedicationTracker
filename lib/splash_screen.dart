import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // تأكدي إن الاسم هنا مطابق تماماً
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnBoardingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // هنا أجبرنا اللون اللي في فيجما عشان ميظهرش أبيض صريح
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : Color.fromARGB(255, 249, 252, 251),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // اللوجو والاسم في سطر واحد
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/Images/Logo.png',
                  width: 60,
                  color: isDark ? Colors.white : Colors.black,
                  colorBlendMode: BlendMode.srcIn,
                ),
                const SizedBox(width: 15),
                Text(
                  "ECHO",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 80),

            const CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF4A90E2),
            ),
            const SizedBox(height: 20),

            Text(
              "انتظر لحظة...",
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
