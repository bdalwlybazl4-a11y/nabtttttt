import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// خدمة موحدة لإدارة جميع الإشعارات (مواعيد + أدوية)
/// توفر:
/// - إنشاء قنوات إشعارات Android محسّنة
/// - جدولة إشعارات المواعيد والأدوية بشكل موحد
/// - تنظيف الإشعارات المنتهية
/// - تتبع حالة الإشعارات
class EnhancedNotificationsService {
  static final EnhancedNotificationsService _instance =
  EnhancedNotificationsService._internal();

  factory EnhancedNotificationsService() => _instance;
  EnhancedNotificationsService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _logTag = '🔔 [Enhanced Notifications]';

  // Notification IDs لتتبع الإشعارات
  static const int appointmentChannelId = 1000;
  static const int medicationChannelId = 2000;

  /// تهيئة الخدمة مع جميع القنوات
  Future<void> initialize() async {
    try {
      _logInfo('جاري تهيئة خدمة الإشعارات المحسّنة...');
      // ✅ إنشاء قنوات Android محسّنة
      await _createNotificationChannels();
      _logSuccess('تم تهيئة خدمة الإشعارات بنجاح');
    } catch (e) {
      _logError('فشل التهيئة: $e');
    }
  }

  /// إنشاء قنوات الإشعارات على Android
  Future<void> _createNotificationChannels() async {
    try {
      _logDebug('إنشاء قنوات الإشعارات...');

      // قناة المواعيد
      final AndroidNotificationChannel appointmentChannel =
      AndroidNotificationChannel(
        'appointment_channel',
        'تنبيهات المواعيد',
        description: 'إشعارات تذكير بمواعيد العيادة والاستشارات',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
      );

      // قناة الأدوية
      final AndroidNotificationChannel medicationChannel =
      AndroidNotificationChannel(
        'medication_channel',
        'تنبيهات الأدوية',
        description: 'إشعارات تذكير بمواعيد تناول الأدوية',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 200, 200, 200]),
      );

      // قناة المكالمات
      final AndroidNotificationChannel callChannel =
          AndroidNotificationChannel(
        'call_channel',
        'إشعارات المكالمات',
        description: 'إشعارات المكالمات الواردة والرسائل الفورية',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      );

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(appointmentChannel);
      await androidPlugin?.createNotificationChannel(medicationChannel);
      await androidPlugin?.createNotificationChannel(callChannel);

      _logSuccess('تم إنشاء جميع القنوات بنجاح');
    } catch (e) {
      _logError('خطأ في إنشاء القنوات: $e');
    }
  }

// بقية كود الخدمة يبقى كما هو

  /// جدولة إشعار موعد طبي
  Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required String doctorName,
    required String location,
    required DateTime appointmentDate,
    required int hoursBeforeAppointment,
  }) async {
    try {
      _logDebug('جدولة إشعار موعد: $appointmentId');

      final scheduledDate =
          appointmentDate.subtract(Duration(hours: hoursBeforeAppointment));
      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

      if (tzDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
        _logWarning('الموعد المجدول في الماضي، تخطي الإشعار');
        return;
      }

      final title = hoursBeforeAppointment == 1
          ? 'تذكير: الموعد بعد ساعة'
          : hoursBeforeAppointment == 6
              ? 'تذكير: الموعد بعد 6 ساعات'
              : 'تذكير: الموعد غداً';

      final body =
          'موعد مع د. $doctorName في $location\nالوقت: ${appointmentDate.hour}:${appointmentDate.minute.toString().padLeft(2, '0')}';

      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'appointment_channel',
          'تنبيهات المواعيد',
          channelDescription: 'إشعارات تذكير بمواعيد العيادة والاستشارات',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          color: Color(0xFF2196F3),
        ),
        iOS: DarwinNotificationDetails(
          sound: 'notification.caf',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      final reminderId =
          (appointmentId.hashCode + hoursBeforeAppointment).abs();

      await _notifications.zonedSchedule(
        reminderId,
        title,
        body,
        tzDateTime,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      // حفظ تتبع الإشعار في Firestore
      await _logNotificationScheduled(appointmentId, 'appointment', reminderId);

      _logSuccess('تم جدولة إشعار الموعد: $reminderId');
    } catch (e) {
      _logError('خطأ في جدولة إشعار الموعد: $e');
    }
  }

  /// جدولة إشعار تناول دواء
  Future<void> scheduleMedicationReminder({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required DateTime scheduleTime,
    required List<int> repeatDays,
  }) async {
    try {
      _logDebug('جدولة إشعار دواء: $medicationId');

      if (repeatDays.isEmpty) {
        // جدولة لمرة واحدة
        await _scheduleOnceMedicationReminder(
          medicationId: medicationId,
          medicationName: medicationName,
          dosage: dosage,
          scheduleTime: scheduleTime,
        );
      } else {
        // جدولة متكررة
        for (int day in repeatDays) {
          final tzDateTime = tz.TZDateTime.from(scheduleTime, tz.local);

          // تعديل اليوم
          var adjustedTime = tzDateTime;
          while (adjustedTime.weekday != day) {
            adjustedTime = adjustedTime.add(const Duration(days: 1));
          }

          if (adjustedTime.isBefore(tz.TZDateTime.now(tz.local))) {
            adjustedTime = adjustedTime.add(const Duration(days: 7));
          }

          const notificationDetails = NotificationDetails(
            android: AndroidNotificationDetails(
              'medication_channel',
              'تنبيهات الأدوية',
              channelDescription:
                  'إشعارات تذكير بمواعيد تناول الأدوية',
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              color: Color(0xFF4CAF50),
            ),
            iOS: DarwinNotificationDetails(
              sound: 'notification.caf',
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          );

          final reminderId = (medicationId.hashCode + day).abs();

          await _notifications.zonedSchedule(
            reminderId,
            'تذكير: تناول الدواء 💊',
            'حان وقت تناول $medicationName - الجرعة: $dosage',
            adjustedTime,
            notificationDetails,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );

          await _logNotificationScheduled(
              medicationId, 'medication', reminderId);

          _logSuccess('تم جدولة إشعار الدواء لليوم $day: $reminderId');
        }
      }
    } catch (e) {
      _logError('خطأ في جدولة إشعار الدواء: $e');
    }
  }

  /// جدولة إشعار دواء لمرة واحدة
  Future<void> _scheduleOnceMedicationReminder({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required DateTime scheduleTime,
  }) async {
    try {
      final tzDateTime = tz.TZDateTime.from(scheduleTime, tz.local);

      if (tzDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
        _logWarning('وقت الجدولة في الماضي، تخطي الإشعار');
        return;
      }

      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel',
          'تنبيهات الأدوية',
          channelDescription: 'إشعارات تذكير بمواعيد تناول الأدوية',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          color: Color(0xFF4CAF50),
        ),
        iOS: DarwinNotificationDetails(
          sound: 'notification.caf',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      final reminderId = medicationId.hashCode.abs();

      await _notifications.zonedSchedule(
        reminderId,
        'تذكير: تناول الدواء 💊',
        'حان وقت تناول $medicationName - الجرعة: $dosage',
        tzDateTime,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      await _logNotificationScheduled(medicationId, 'medication', reminderId);
      _logSuccess('تم جدولة إشعار الدواء: $reminderId');
    } catch (e) {
      _logError('خطأ في جدولة إشعار الدواء: $e');
    }
  }

  /// حذف إشعار محدد
  Future<void> cancelNotification(int notificationId) async {
    try {
      await _notifications.cancel(notificationId);
      _logSuccess('تم حذف الإشعار: $notificationId');
    } catch (e) {
      _logError('خطأ في حذف الإشعار: $e');
    }
  }

  /// حذف جميع الإشعارات
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      _logSuccess('تم حذف جميع الإشعارات');
    } catch (e) {
      _logError('خطأ في حذف الإشعارات: $e');
    }
  }

  /// حفظ تتبع الإشعار في Firestore
  Future<void> _logNotificationScheduled(
    String itemId,
    String type,
    int notificationId,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('notification_logs')
          .add({
            'userId': user.uid,
            'itemId': itemId,
            'type': type,
            'notificationId': notificationId,
            'scheduledAt': FieldValue.serverTimestamp(),
            'status': 'scheduled',
          });
    } catch (e) {
      _logError('خطأ في حفظ تتبع الإشعار: $e');
    }
  }

  // ============ Logging Helpers ============

  static void _logDebug(String message) {
    debugPrint('$_logTag 🔍 $message');
  }

  static void _logInfo(String message) {
    debugPrint('$_logTag ℹ️ $message');
  }

  static void _logSuccess(String message) {
    debugPrint('$_logTag ✅ $message');
  }

  static void _logWarning(String message) {
    debugPrint('$_logTag ⚠️ $message');
  }

  static void _logError(String message) {
    debugPrint('$_logTag ❌ $message');
  }
}
