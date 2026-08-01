import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login/singup/login_screen.dart';
import 'app_provider.dart';
import 'notification_service.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  _OnBoardingScreenState createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _notifOn = false;
  bool _notifLoading = false;

  Future<void> _toggleNotifications(bool value, bool isAr) async {
    setState(() {
      _notifLoading = true;
    });

    if (value) {
      final allowed = await NotificationService().enableNotifications();
      if (!mounted) return;
      setState(() {
        _notifOn = allowed;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            allowed
                ? (isAr
                    ? "تم تفعيل تنبيهات مواعيد الأدوية"
                    : "Medicine reminders enabled successfully")
                : (isAr
                    ? "لم يتم منح صلاحية الإشعارات من النظام"
                    : "Notification permission was not granted by the system"),
          ),
        ),
      );
    } else {
      await NotificationService().disableNotifications();
      if (!mounted) return;
      setState(() {
        _notifOn = false;
      });
    }

    if (!mounted) return;
    setState(() {
      _notifLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final bool isAr = appProvider.locale.languageCode == 'ar';
    // التصحيح الأول: استخدمنا Directionality.of بدل Localizations.directionOf
    bool isRtl = Directionality.of(context) == TextDirection.rtl;
    const int totalPages = 3;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF020617)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Stack(
            children: [
              PageView(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  buildPage(
                    title: isAr ? "MedUP" : "MedUP",
                    desc: isAr
                        ? "تطبيقك الطبي المتكامل لإدارة الأدوية والمواعيد بدقة وسهولة."
                        : "Your smart medical app to manage medicines and schedules easily and accurately.",
                    icon: Icons.health_and_safety_outlined,
                  ),
                  buildPage(
                    title: isAr ? "سياسة الخصوصية" : "Privacy Policy",
                    desc: isAr
                        ? "نحن نهتم بخصوصيتك. بياناتك الطبية مشفرة تماماً ومخزنة بأمان."
                        : "We care about your privacy. Your medical data is fully encrypted and securely stored.",
                    icon: Icons.security_outlined,
                  ),
                  buildNotificationsPage(isAr),
                ],
              ),
              Positioned(
                bottom: 60,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                          totalPages, (index) => buildDot(index)),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        elevation: 6,
                        shadowColor: Colors.black.withOpacity(0.4),
                      ),
                      onPressed: () {
                        if (_currentPage == totalPages - 1) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()),
                          );
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Text(
                        _currentPage == totalPages - 1
                            ? (isAr ? "ابدأ الآن" : "Start now")
                            : (isAr ? "التالي" : "Next"),
                        style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
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

  Widget buildPage(
      {required String title, required String desc, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF22C1C3)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Icon(icon, size: 70, color: Colors.white),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              color: Colors.white.withOpacity(0.78),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 5),
      height: 10,
      width: _currentPage == index ? 25 : 10,
      decoration: BoxDecoration(
        color:
            _currentPage == index ? const Color(0xFF4A90E2) : Colors.white24,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget buildNotificationsPage(bool isAr) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF22C55E), Color(0xFF4ADE80)],
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isAr ? "لا تفوّت جرعتك" : "Never miss a dose",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isAr
                      ? "قم بتفعيل تنبيهات الجرعات ليصلك تنبيه في وقت كل دواء، حتى لو كان التطبيق مغلقاً."
                      : "Turn on smart reminders so we can notify you right on time for every medicine, even when the app is closed.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _notifLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: CircularProgressIndicator(
                            color: Color(0xFF4A90E2),
                          ),
                        )
                      : SwitchListTile(
                          value: _notifOn,
                          onChanged: (val) =>
                              _toggleNotifications(val, isAr),
                          activeColor: const Color(0xFF22C55E),
                          title: Text(
                            isAr
                                ? "تفعيل تنبيهات مواعيد الأدوية"
                                : "Enable medicine reminders",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            isAr
                                ? "يمكنك تغيير الإعداد لاحقاً من صفحة الإعدادات."
                                : "You can always change this later from Settings.",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
