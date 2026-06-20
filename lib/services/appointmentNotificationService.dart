// lib/services/appointment_notification_service.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'local_in_app_notification_service.dart';

class AppointmentNotificationService {
  static final AppointmentNotificationService _instance =
      AppointmentNotificationService._internal();

  factory AppointmentNotificationService() => _instance;
  AppointmentNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _appointmentsSub;

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    final AndroidNotificationChannel appointmentChannel = AndroidNotificationChannel(
      'appointment_channel',
      'تنبيهات المواعيد',
      description: 'إشعارات تذكير بمواعيد العيادة',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(appointmentChannel);

    await LocalInAppNotificationService.initialize();

    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _appointmentsSub?.cancel();
      if (user != null) {
        listenToUserAppointments(user.uid);
      }
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      listenToUserAppointments(currentUser.uid);
    }

    debugPrint('✅ تم تهيئة قناة إشعارات المواعيد');
  }

  Future<void> scheduleAppointmentReminders(String appointmentId) async {
    final appointmentDoc =
        await _firestore.collection('appointments').doc(appointmentId).get();

    if (!appointmentDoc.exists) return;

    final data = appointmentDoc.data()!;
    final DateTime appointmentDate = (data['date'] as Timestamp).toDate();
    final String doctorName = data['doctorName'] ?? 'الطبيب';
    final String location = data['workplace'] ?? 'العيادة';

    await _scheduleSingleReminder(
      id: appointmentId.hashCode + 1,
      title: 'تذكير بالموعد غداً',
      body: 'لديك موعد غداً مع د. $doctorName في $location',
      scheduledDate: appointmentDate.subtract(const Duration(days: 1)),
      dedupeKey: 'appointment-$appointmentId-1day',
    );

    await _scheduleSingleReminder(
      id: appointmentId.hashCode + 2,
      title: 'تذكير بالموعد بعد 6 ساعات',
      body: 'لديك موعد بعد 6 ساعات مع د. $doctorName',
      scheduledDate: appointmentDate.subtract(const Duration(hours: 6)),
      dedupeKey: 'appointment-$appointmentId-6hours',
    );

    await _scheduleSingleReminder(
      id: appointmentId.hashCode + 3,
      title: 'تذكير بالموعد بعد ساعة',
      body: 'لديك موعد بعد ساعة مع د. $doctorName في $location',
      scheduledDate: appointmentDate.subtract(const Duration(hours: 1)),
      dedupeKey: 'appointment-$appointmentId-1hour',
    );

    await _firestore.collection('appointments').doc(appointmentId).update({
      'notified': {
        '1day': true,
        '6hours': true,
        '1hour': true,
      },
      'reminderScheduled': true,
      'reminderScheduledAt': FieldValue.serverTimestamp(),
    });

    await LocalInAppNotificationService.storeNotification(
      title: 'تم تفعيل تذكيرات الموعد',
      body:
          'تم ضبط تذكيرات الموعد (${DateFormat('yyyy/MM/dd hh:mm a').format(appointmentDate)}).',
      type: 'appointment_schedule',
      dedupeKey: 'appointment-schedule-$appointmentId',
      channelId: 'appointment_channel',
      payload: {'appointmentId': appointmentId},
    );
  }

  Future<void> _scheduleSingleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String dedupeKey,
  }) async {
    try {
      final tz.TZDateTime scheduledTzDate =
          tz.TZDateTime.from(scheduledDate, tz.local);

      if (scheduledTzDate.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint('⚠️ الوقت المجدول في الماضي، تخطي الإشعار');
        return;
      }

      final NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'appointment_channel',
          'تنبيهات المواعيد',
          channelDescription: 'إشعارات تذكير بمواعيد العيادة',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          color: const Color(0xFF2196F3),
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'notification.caf',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTzDate,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      await LocalInAppNotificationService.storeNotification(
        title: 'تمت جدولة تذكير موعد',
        body: '$title - $body',
        type: 'appointment_schedule',
        dedupeKey: dedupeKey,
        channelId: 'appointment_channel',
      );

      debugPrint('✅ تم جدولة إشعار الموعد برقم $id');
    } catch (e) {
      debugPrint('❌ خطأ في جدولة الإشعار: $e');
    }
  }

  void listenToUserAppointments(String userId) {
    _appointmentsSub?.cancel();
    _appointmentsSub = _firestore
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;
        final status = (data['status'] ?? '').toString();
        final alreadyScheduled = data['reminderScheduled'] == true;

        if ((change.type == DocumentChangeType.added ||
                change.type == DocumentChangeType.modified) &&
            !alreadyScheduled &&
            (status == 'pending' || status == 'confirmed')) {
          scheduleAppointmentReminders(change.doc.id);
        }
      }
    });
  }
}
