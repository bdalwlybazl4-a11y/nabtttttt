import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'dart:async';

/// خدمة متقدمة لجدولة وإدارة تذكيرات الأدوية
class AdvancedMedicationReminderService {
  static final AdvancedMedicationReminderService _instance =
  AdvancedMedicationReminderService._internal();

  factory AdvancedMedicationReminderService() => _instance;

  AdvancedMedicationReminderService._internal();

  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// تخزين معرفات التذكيرات النشطة
  static final Map<String, List<int>> _activeMedicationReminders = {};

  /// تهيئة الخدمة
  static Future<void> initialize() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
      _handleBackgroundNotificationResponse,
    );

    await _requestPermissions();

    print('✅ تم تهيئة خدمة التذكيرات بنجاح');
  }

  /// طلب الأذونات
  static Future<void> _requestPermissions() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// جدولة تذكيرات الدواء
  static Future<void> scheduleMedicationReminders({
    required String medicationId,
    required String medicationName,
    required List<String> times,
    required int durationDays,
  }) async {
    try {
      print('⏰ جدولة تذكيرات للدواء: $medicationName');

      final reminders = <int>[];
      final now = DateTime.now();

      for (int day = 0; day < durationDays; day++) {
        for (int timeIndex = 0; timeIndex < times.length; timeIndex++) {
          final timeStr = times[timeIndex];
          final parts = timeStr.split(':');

          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);

          final reminderId =
          _generateReminderId(medicationId, day, timeIndex);

          reminders.add(reminderId);

          final scheduledTime = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day + day,
            hour,
            minute,
          );

          if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
            continue;
          }

          await _flutterLocalNotificationsPlugin.zonedSchedule(
            reminderId,
            'تذكير الدواء 💊',
            'حان وقت تناول دواء $medicationName',
            scheduledTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'medication_channel',
                'تذكيرات الأدوية',
                channelDescription: 'إشعارات تذكير بمواعيد تناول الأدوية',
                importance: Importance.high,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
              ),
              iOS: DarwinNotificationDetails(
                sound: 'notification.caf',
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          print(
              '✅ تم جدولة تذكير رقم $reminderId للساعة $timeStr في اليوم ${day + 1}');
        }
      }

      _activeMedicationReminders[medicationId] = reminders;

      print('💾 تم حفظ ${reminders.length} تذكير نشط للدواء $medicationId');
    } catch (e) {
      print('❌ خطأ في جدولة التذكيرات: $e');
    }
  }

  /// إلغاء تذكيرات دواء
  static Future<void> cancelMedicationReminders(String medicationId) async {
    try {
      final reminders = _activeMedicationReminders[medicationId] ?? [];

      for (final reminderId in reminders) {
        await _flutterLocalNotificationsPlugin.cancel(reminderId);
      }

      _activeMedicationReminders.remove(medicationId);

      print('✅ تم إلغاء ${reminders.length} تذكير للدواء $medicationId');
    } catch (e) {
      print('❌ خطأ في إلغاء التذكيرات: $e');
    }
  }

  /// إلغاء جميع التذكيرات
  static Future<void> cancelAllReminders() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      _activeMedicationReminders.clear();

      print('✅ تم إلغاء جميع التذكيرات');
    } catch (e) {
      print('❌ خطأ في إلغاء جميع التذكيرات: $e');
    }
  }

  /// إنشاء معرف فريد للتذكير
  static int _generateReminderId(
      String medicationId,
      int dayIndex,
      int timeIndex,
      ) {
    final combined =
    '$medicationId$dayIndex$timeIndex'.replaceAll('-', '');
    return combined.hashCode.abs();
  }

  /// عند الضغط على الإشعار
  static void _handleNotificationResponse(
      NotificationResponse details,
      ) {
    print('📢 تم النقر على الإشعار: ${details.payload}');
  }

  /// عند وصول الإشعار بالخلفية
  @pragma('vm:entry-point')
  static void _handleBackgroundNotificationResponse(
      NotificationResponse details,
      ) {
    print('📢 تم استقبال إشعار في الخلفية: ${details.payload}');
  }

  /// عدد التذكيرات النشطة
  static int getActiveRemindersCount() {
    int total = 0;

    for (final reminders in _activeMedicationReminders.values) {
      total += reminders.length;
    }

    return total;
  }

  /// تفاصيل التذكيرات
  static Map<String, dynamic> getActiveRemindersDetails() {
    return {
      'total': getActiveRemindersCount(),
      'medications': _activeMedicationReminders.keys.toList(),
      'details': _activeMedicationReminders,
    };
  }
}
