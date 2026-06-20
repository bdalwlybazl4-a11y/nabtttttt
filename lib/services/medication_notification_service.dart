// lib/services/medication_notification_service.dart
import 'dart:ui';

import 'package:flutter/foundation.dart'; // لاستخدام debugPrint
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class MedicationNotificationService {
  static final MedicationNotificationService _instance =
  MedicationNotificationService._internal();

  factory MedicationNotificationService() => _instance;
  MedicationNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);

    // إنشاء قناة إشعارات الأدوية
    const AndroidNotificationChannel medicationChannel = AndroidNotificationChannel(
      'medication_channel',
      'تنبيهات الأدوية',
      description: 'إشعارات تذكير بتناول الأدوية',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(medicationChannel);
  }

  Future<void> scheduleMedicationReminder({
    required int id,
    required String medicationName,
    required String dosage,
    required DateTime scheduleTime,
    required List<int> repeatDays, // [1,2,3,4,5,6,7] حيث 1=الإثنين
  }) async {
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduleTime, tz.local);

    final NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_channel',
        'تنبيهات الأدوية',
        channelDescription: 'إشعارات تذكير بتناول الأدوية',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: null,
        colorized: true,
        color: const Color(0xFF2196F3),
      ),
    );

    if (repeatDays.isNotEmpty) {
      // جدولة متكررة
      for (int day in repeatDays) {
        await _notifications.zonedSchedule(
          id + day, // ID فريد لكل يوم
          'موعد تناول الدواء',
          'حان وقت تناول $medicationName - الجرعة: $dosage',
          _nextInstanceOfTime(scheduledDate, day),
          notificationDetails,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    } else {
      // جدولة لمرة واحدة
      await _notifications.zonedSchedule(
        id,
        'موعد تناول الدواء',
        'حان وقت تناول $medicationName - الجرعة: $dosage',
        scheduledDate,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfTime(tz.TZDateTime scheduledTime, int dayOfWeek) {
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate.isBefore(tz.TZDateTime.now(tz.local))
        ? scheduledDate.add(const Duration(days: 7))
        : scheduledDate;
  }

  Future<void> cancelMedicationReminder(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllMedicationReminders() async {
    await _notifications.cancelAll();
  }
}
