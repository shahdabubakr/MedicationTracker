import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // إعدادات الأندرويد
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings);
    tz.initializeTimeZones(); // تفعيل المناطق الزمنية
  }

  /// تفعيل التنبيهات وحفظ الاختيار في SharedPreferences
  Future<bool> enableNotifications() async {
    await init();

    // طلب صلاحية الإشعارات على أندرويد (API 33+) إن توفرت
    bool allowed = true;
    final androidImpl =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final didAllow = await androidImpl.requestPermission();
      allowed = didAllow ?? false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', allowed);

    return allowed;
  }

  /// إلغاء تفعيل التنبيهات
  Future<void> disableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', false);
    await _notifications.cancelAll();
  }

  /// التحقق إن المستخدم فعّل التنبيهات من قبل
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? false;
  }

  // دالة جدولة التنبيه
  Future<void> scheduleNotification(
      int id, String title, String timeString) async {
    // لا نقوم بالجدولة إذا كان المستخدم لم يفعّل التنبيهات
    if (!await areNotificationsEnabled()) return;

    // تحويل النص (مثلاً 14:30) لوقت حقيقي
    DateTime now = DateTime.now();

    // Parse the time string in HH:mm format
    List<String> timeParts = timeString.split(':');
    if (timeParts.length != 2) return;

    int hour = int.tryParse(timeParts[0]) ?? 0;
    int minute = int.tryParse(timeParts[1]) ?? 0;

    // ضبط التاريخ ليكون اليوم
    DateTime finalDate = DateTime(now.year, now.month, now.day, hour, minute);

    // لو الوقت فات، نخليه بكرة
    if (finalDate.isBefore(now)) {
      finalDate = finalDate.add(const Duration(days: 1));
    }

    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('lang') ?? 'ar';
    final bool isAr = lang == 'ar';

    final String notifTitle =
        isAr ? 'موعد جرعة علاجك 💊' : 'Time for your dose 💊';
    final String notifBody = isAr
        ? 'حان الآن وقت أخذ: $title'
        : 'It\'s time to take: $title';

    await _notifications.zonedSchedule(
      id,
      notifTitle,
      notifBody,
      tz.TZDateTime.from(finalDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'med_channel',
          'Medicine Reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.time, // يكرر التنبيه كل يوم في نفس الوقت
    );
  }

  // إلغاء تنبيه (لو مسحنا العلاج)
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}
