import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../language_selection_screen.dart';
import '../../home_screen.dart';
import '../../app_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fillController;
  late AnimationController _pulseController;
  late Animation<double> _fillAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // انيميشن الامتلاء (5 ثواني)
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // انيميشن النبض
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _fillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fillController.forward();
    _fillController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAuth();
      }
    });
  }

  @override
  void dispose() {
    _fillController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    if (!mounted) return;
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const HomeScreen(userName: "User", birthYear: 2000),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const LanguageSelectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final bool isAr = appProvider.locale.languageCode == 'ar';
    bool isDark = Theme.of(context).brightness == Brightness.dark;

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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // القلب المتملي
              AnimatedBuilder(
                animation: Listenable.merge([_fillAnimation, _pulseAnimation]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: CustomPaint(
                        painter: HeartFillPainter(
                          fillProgress: _fillAnimation.value,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              Text(
                "ECHO",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 16),

              // بار تحت النص يوضح البروجريس
              AnimatedBuilder(
                animation: _fillAnimation,
                builder: (context, child) {
                  return Column(
                    children: [
                      SizedBox(
                        width: 160,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _fillAnimation.value,
                            minHeight: 4,
                            backgroundColor: isDark
                                ? Colors.white12
                                : Colors.black12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF4A90E2)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isAr ? "انتظر لحظة..." : "Please wait...",
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// رسام القلب المتملي
class HeartFillPainter extends CustomPainter {
  final double fillProgress;
  final bool isDark;

  HeartFillPainter({required this.fillProgress, required this.isDark});

  Path _heartPath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, h * 0.85);
    path.cubicTo(w * 0.1, h * 0.6, 0, h * 0.4, w * 0.1, h * 0.25);
    path.cubicTo(w * 0.2, h * 0.1, w * 0.4, h * 0.1, w * 0.5, h * 0.28);
    path.cubicTo(w * 0.6, h * 0.1, w * 0.8, h * 0.1, w * 0.9, h * 0.25);
    path.cubicTo(w, h * 0.4, w * 0.9, h * 0.6, w * 0.5, h * 0.85);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final heartPath = _heartPath(size);

    // الخلفية (القلب الفارغ)
    final bgPaint = Paint()
      ..color = isDark ? Colors.white12 : Colors.black12
      ..style = PaintingStyle.fill;
    canvas.drawPath(heartPath, bgPaint);

    // الامتلاء من الأسفل للأعلى
    final fillHeight = size.height * (1 - fillProgress);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, fillHeight, size.width, size.height));

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFF4A90E2),
          const Color(0xFF60A5FA),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(heartPath, fillPaint);
    canvas.restore();

    // الإطار الخارجي للقلب
    final borderPaint = Paint()
      ..color = const Color(0xFF4A90E2).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(heartPath, borderPaint);
  }

  @override
  bool shouldRepaint(HeartFillPainter oldDelegate) =>
      oldDelegate.fillProgress != fillProgress;
}