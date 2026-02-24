import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';

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

  // دالة جدولة التنبيه
  Future<void> scheduleNotification(
      int id, String title, String timeString) async {
    // تحويل النص (مثلاً 02:00 PM) لوقت حقيقي
    DateTime now = DateTime.now();
    DateFormat format = DateFormat.jm(); // ده بيفهم تنسيق الـ AM/PM
    DateTime scheduledDate = format.parse(timeString);

    // ظبط التاريخ ليكون النهاردة
    DateTime finalDate = DateTime(
        now.year, now.month, now.day, scheduledDate.hour, scheduledDate.minute);

    // لو الوقت فات، نخليه بكرة
    if (finalDate.isBefore(now)) {
      finalDate = finalDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      'موعد جرعة علاجك 💊',
      'حان الآن وقت أخذ: $title',
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
