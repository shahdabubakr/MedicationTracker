import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// إشعارات نظامية (شريط الإشعارات) لمواعيد الجرعات — يومياً في نفس الساعة.
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  static const String _prefsKeyOptIn = 'dose_reminders_opt_in';

  /// تغيير المعرف إلى v4 ليجبر الأندرويد على قراءة قنوات الصوت المخصصة الجديدة (العربي والإنجليزي).
  static const String _channelId = 'echo_medication_alarms_v4';
  static const String _channelName = 'مواعيد الدواء';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// معرّف إشعار مستقر من [docId] (Firestore / Realtime) ليتطابق الحذف والجدولة.
  static int notificationIdFromDocId(String docId) {
    if (docId.isEmpty) return 1;
    if (docId.length < 6) {
      final h = docId.hashCode & 0x7fffffff;
      return h == 0 ? 1 : h;
    }
    final tail = docId.substring(docId.length - 6);
    final safe =
        tail.replaceAll(RegExp(r'[^0-9]'), '0').padLeft(6, '0');
    var id = int.tryParse(safe) ?? 0;
    if (id == 0) {
      id = docId.hashCode & 0x7fffffff;
      if (id == 0) id = 1;
    }
    return id;
  }

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    await _initLocalTimezone();

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(initSettings);

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'تنبيهات مواعيد جرعات الدواء في شريط الإشعارات',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  /// بعض الأجهزة ترجع اسم منطقة غير معروف لـ timezone — نجرب بدائل شائعة.
  Future<void> _initLocalTimezone() async {
    try {
      final zoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zoneName));
    } catch (e) {
      debugPrint('ECHO: FlutterTimezone failed ($e), trying fallbacks');
      for (final name in <String>[
        'Africa/Cairo',
        'Asia/Riyadh',
        'Asia/Dubai',
        'UTC',
      ]) {
        try {
          tz.setLocalLocation(tz.getLocation(name));
          debugPrint('ECHO: using timezone $name');
          return;
        } catch (_) {}
      }
    }
  }

  /// المستخدم اختار صراحة إيقاف التذكيرات من النافذة أو الإعدادات.
  Future<bool> explicitlyDeclinedReminders() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKeyOptIn) == false;
  }

  /// إذن النظام مُمنوح ولم يُوقف المستخدم التذكيرات من داخل التطبيق.
  Future<bool> areNotificationsEnabled() async {
    await init();
    if (await explicitlyDeclinedReminders()) return false;
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// عرض نافذة "تفعيل الإشعارات" فقط إذا لم يُمنح الإذن ولم يختر المستخدم "لا" سابقاً.
  Future<bool> shouldPromptForPermission() async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefsKeyOptIn) == false) return false;
    final status = await Permission.notification.status;
    return !status.isGranted;
  }

  Future<void> declineNotificationPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyOptIn, false);
  }

  /// طلب إذن النظام + تفعيل التذكيرات في التطبيق.
  Future<bool> enableNotifications() async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyOptIn, true);

    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        return false;
      }
      final alarmPerm = await Permission.scheduleExactAlarm.request();
      if (alarmPerm.isDenied) {
        debugPrint('ECHO: scheduleExactAlarm not granted — alarms may be delayed');
      }
    } else if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
      await Permission.notification.request();
    }

    return (await Permission.notification.status).isGranted;
  }

  Future<void> disableNotifications() async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyOptIn, false);
    await _plugin.cancelAll();
  }

  /// يُستدعى مرة قبل جدولة قائمة الأدوية: يحترم رفض المستخدم ويطلب الإذن إن لزم.
  Future<bool> ensureCanScheduleMedicationReminders() async {
    await init();
    if (await explicitlyDeclinedReminders()) return false;
    if ((await Permission.notification.status).isGranted) return true;
    return await enableNotifications();
  }

  /// جدولة تكرار يومي في [timeHHmm] مع دعم اختيار ملف الصوت والنص بناءً على لغة التطبيق [isAr]
  Future<bool> scheduleNotification(
    int id,
    String medicineName,
    String timeHHmm,
    bool isAr, // أضفنا البارامتر ده هنا عشان نستقبل اللغة ديناميكياً
  ) async {
    await init();
    if (await explicitlyDeclinedReminders()) return false;

    if (!(await Permission.notification.status).isGranted) {
      if (!await enableNotifications()) return false;
    }

    final parts = timeHHmm.split(':');
    if (parts.length != 2) return false;
    final hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour == null || minute == null) return false;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return false;

    await _plugin.cancel(id);

    // اختيار ملف الصوت المخصص بناءً على حالة اللغة
    String soundResource = isAr ? 'notification_ar' : 'notification_en';

    final android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'تنبيهات مواعيد جرعات الدواء',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      ticker: 'ECHO',
      showWhen: true,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundResource), // تمرير الصوت المخصص
      styleInformation: BigTextStyleInformation(
        isAr ? 'حان وقت تناول الدواء: $medicineName' : 'It\'s time for your medicine: $medicineName',
        contentTitle: isAr ? 'ECHO — موعد الدواء' : 'ECHO — Medication Time',
      ),
    );
    
    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(android: android, iOS: darwin);

    final when = _nextInstanceOfTime(hour, minute);

    Future<void> doSchedule(AndroidScheduleMode androidMode) async {
      await _plugin.zonedSchedule(
        id,
        isAr ? 'ECHO — موعد الدواء' : 'ECHO — Medication Time',
        isAr ? 'حان وقت جرعة: $medicineName' : 'Time for your dose: $medicineName',
        when,
        details,
        androidScheduleMode: androidMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: timeHHmm,
      );
    }

    if (Platform.isAndroid) {
      const modes = <AndroidScheduleMode>[
        AndroidScheduleMode.alarmClock,
        AndroidScheduleMode.exactAllowWhileIdle,
        AndroidScheduleMode.inexactAllowWhileIdle,
      ];
      var scheduled = false;
      for (final mode in modes) {
        try {
          await doSchedule(mode);
          scheduled = true;
          break;
        } on PlatformException catch (e, st) {
          debugPrint('ECHO: schedule mode $mode failed: $e $st');
        }
      }
      if (!scheduled) return false;
    } else {
      try {
        await doSchedule(AndroidScheduleMode.exactAllowWhileIdle);
      } on PlatformException catch (e, st) {
        debugPrint('ECHO: schedule failed: $e $st');
        return false;
      }
    }

    return true;
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> cancelNotification(int id) async {
    await init();
    await _plugin.cancel(id);
  }
}