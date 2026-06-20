import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'local_in_app_notification_service.dart';

class PatientMedicationReminderService {
  PatientMedicationReminderService._();
  static const String _medicationChannelId = 'medication_alarm_channel_v2';

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    _medicationChannelId,
    'تنبيهات الأدوية',
    channelDescription: 'تنبيهات لتذكير المريض بتناول الدواء',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    category: AndroidNotificationCategory.alarm,
    fullScreenIntent: true,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );

  static const AndroidNotificationDetails _androidAlarmDetails =
      AndroidNotificationDetails(
    _medicationChannelId,
    'تنبيهات الأدوية',
    channelDescription: 'تنبيهات لتذكير المريض بتناول الدواء',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alarm'),
    enableVibration: true,
    category: AndroidNotificationCategory.alarm,
    fullScreenIntent: true,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );

  static const DarwinNotificationDetails _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    await LocalInAppNotificationService.initialize();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamForCurrentUser() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('medications')
        .where('patientId', isEqualTo: currentUserId)
        .snapshots();
  }

  static Future<void> approveMedication({
    required String medicationId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance.collection('medications').doc(medicationId);

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final patientId = data['patientId'] as String?;
      if (patientId != uid) return;

      txn.update(ref, {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': uid,
      });
    });

    await scheduleMedicationById(medicationId);

    await LocalInAppNotificationService.showAndStore(
      id: medicationId.hashCode & 0x7fffffff,
      title: 'تم تفعيل تذكيرات الدواء',
      body: 'تمت موافقتك على الدواء وسيعمل المنبه حسب المواعيد المحددة.',
      type: 'medication',
      channelId: _medicationChannelId,
      payload: {'medicationId': medicationId, 'type': 'medication'},
      dedupeKey: 'approve-$medicationId',
    );
  }

  static Future<void> rejectMedication({
    required String medicationId,
  }) async {
    await FirebaseFirestore.instance.collection('medications').doc(medicationId).update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await cancelMedicationReminders(medicationId);

    await LocalInAppNotificationService.storeNotification(
      title: 'تم رفض طلب دواء',
      body: 'تم رفض الدواء ولن يتم تشغيل أي منبهات له.',
      type: 'medication',
      payload: {'medicationId': medicationId, 'action': 'rejected'},
      dedupeKey: 'reject-$medicationId',
      channelId: _medicationChannelId,
    );
  }

  static Future<void> rescheduleApprovedForCurrentPatient() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final approved = await FirebaseFirestore.instance
        .collection('medications')
        .where('patientId', isEqualTo: uid)
        .where('status', isEqualTo: 'approved')
        .get();

    for (final doc in approved.docs) {
      await scheduleMedicationById(doc.id);
    }
  }

  static Future<void> scheduleMedicationById(String medicationId) async {
    final doc = await FirebaseFirestore.instance
        .collection('medications')
        .doc(medicationId)
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;
    if (data['status'] != 'approved') return;

    final times = (data['times24'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    if (times.isEmpty) return;

    final medicationName = (data['name'] ?? 'دواء').toString();
    final instructions = (data['schedule'] ?? data['dose'] ?? '').toString();
    final durationDays = _parseDurationDays(data['duration']?.toString());

    final oldIds = (data['scheduledNotificationIds'] as List<dynamic>? ?? [])
        .map((e) => e as int)
        .toList();
    for (final id in oldIds) {
      await _notifications.cancel(id);
    }

    final ids = <int>[];
    final now = tz.TZDateTime.now(tz.local);

    for (int day = 0; day < durationDays; day++) {
      for (int index = 0; index < times.length; index++) {
        final parts = times[index].split(':');
        if (parts.length != 2) continue;
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) continue;

        final id = _buildReminderId(medicationId, day, index);
        ids.add(id);

        final scheduled = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + day,
          hour,
          minute,
        );

        if (scheduled.isBefore(now)) {
          continue;
        }

        final payload =
            '{"type":"medication","medicationId":"$medicationId","day":$day,"time":"${times[index]}"}';

        try {
          await _notifications.zonedSchedule(
            id,
            '⏰ موعد الدواء',
            '$medicationName\n$instructions',
            scheduled,
            const NotificationDetails(
              android: _androidAlarmDetails,
              iOS: _iosDetails,
            ),
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: payload,
          );
        } on PlatformException catch (e) {
          final isMissingAlarmSound = e.code == 'invalid_sound' ||
              (e.message?.toLowerCase().contains('resource alarm could not be found') ??
                  false);
          await _notifications.zonedSchedule(
            id,
            '⏰ موعد الدواء',
            '$medicationName\n$instructions',
            scheduled,
            const NotificationDetails(android: _androidDetails, iOS: _iosDetails),
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: isMissingAlarmSound
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.inexactAllowWhileIdle,
            payload: payload,
          );
        } catch (_) {
          await _notifications.zonedSchedule(
            id,
            '⏰ موعد الدواء',
            '$medicationName\n$instructions',
            scheduled,
            const NotificationDetails(android: _androidDetails, iOS: _iosDetails),
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: payload,
          );
        }
      }
    }

    await doc.reference.update({
      'scheduledNotificationIds': ids,
      'lastScheduledAt': FieldValue.serverTimestamp(),
      'durationDays': durationDays,
      'activeUntil': Timestamp.fromDate(
        DateTime.now().add(Duration(days: durationDays)),
      ),
    });

    await LocalInAppNotificationService.storeNotification(
      title: 'تمت جدولة منبهات الدواء',
      body: 'تمت جدولة ${ids.length} منبه خلال $durationDays يوم.',
      type: 'medication_schedule',
      payload: {
        'medicationId': medicationId,
        'times24': times,
        'durationDays': durationDays,
      },
      dedupeKey: 'schedule-$medicationId-${times.join('-')}',
      channelId: _medicationChannelId,
    );
  }

  static Future<void> cancelMedicationReminders(String medicationId) async {
    final doc = await FirebaseFirestore.instance
        .collection('medications')
        .doc(medicationId)
        .get();

    if (!doc.exists) return;

    final ids = (doc.data()?['scheduledNotificationIds'] as List<dynamic>? ?? [])
        .map((e) => e as int)
        .toList();

    for (final id in ids) {
      await _notifications.cancel(id);
    }

    await doc.reference.update({
      'scheduledNotificationIds': [],
      'lastScheduledAt': FieldValue.serverTimestamp(),
    });

    await LocalInAppNotificationService.storeNotification(
      title: 'تم إيقاف منبهات الدواء',
      body: 'تم إلغاء جميع منبهات الدواء المحدد.',
      type: 'medication_cancel',
      payload: {'medicationId': medicationId},
      dedupeKey: 'cancel-$medicationId',
      channelId: _medicationChannelId,
    );
  }

  static int _parseDurationDays(String? duration) {
    if (duration == null || duration.isEmpty) return 30;
    final digits = RegExp(r'\d+').firstMatch(duration)?.group(0);
    return int.tryParse(digits ?? '') ?? 30;
  }

  static int _buildReminderId(String medicationId, int day, int timeIndex) {
    return ('$medicationId-$day-$timeIndex').hashCode & 0x7fffffff;
  }

  static String formatTime24(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
