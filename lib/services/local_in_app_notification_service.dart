import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalInAppNotificationService {
  LocalInAppNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static final Set<String> _dedupeCache = <String>{};
  static GlobalKey<NavigatorState>? _navigatorKey;

  static void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  @pragma('vm:entry-point')
  static void _onBackgroundTap(NotificationResponse response) {
    // background tap entry point
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _handleNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundTap,
    );

    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    await _createChannels(androidImpl);

    _initialized = true;
  }

  static void _handleNotificationTap(NotificationResponse response) {
    if (_navigatorKey?.currentState == null) return;

    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final type = (data['type'] ?? '').toString();
      final medicationId = data['medicationId']?.toString();
      final consultationId = data['consultationId']?.toString();

      if (medicationId != null && medicationId.isNotEmpty) {
        _navigatorKey!.currentState!.pushNamed(
          '/medication_details',
          arguments: medicationId,
        );
        return;
      }

      if (type == 'message' && consultationId != null && consultationId.isNotEmpty) {
        _navigatorKey!.currentState!.pushNamed('/consultation', arguments: {
          'consultationId': consultationId,
          'doctorId': (data['doctorId'] ?? '').toString(),
          'userId': (data['userId'] ?? '').toString(),
          'doctorName': (data['doctorName'] ?? '').toString(),
          'patientName': (data['patientName'] ?? '').toString(),
          'isDoctor': data['isDoctor'] ?? false,
        });
      }
    } catch (_) {
      // ignore malformed payload
    }
  }

  static Future<void> _createChannels(
    AndroidFlutterLocalNotificationsPlugin? androidImpl,
  ) async {
    if (androidImpl == null) return;

    const channels = [
      AndroidNotificationChannel(
        'medication_channel',
        'تنبيهات الأدوية',
        description: 'تنبيهات مواعيد الأدوية اليومية',
        importance: Importance.max,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'message_channel',
        'تنبيهات الرسائل',
        description: 'تنبيهات الرسائل الفورية',
        importance: Importance.high,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'call_channel',
        'تنبيهات المكالمات',
        description: 'تنبيهات المكالمات الواردة',
        importance: Importance.max,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'appointment_channel',
        'تنبيهات المواعيد',
        description: 'تنبيهات المواعيد الطبية',
        importance: Importance.high,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'general_channel',
        'تنبيهات عامة',
        description: 'تنبيهات عامة داخل التطبيق',
        importance: Importance.high,
        playSound: true,
      ),
    ];

    for (final channel in channels) {
      await androidImpl.createNotificationChannel(channel);
    }
  }

  static Future<void> showAndStore({
    required int id,
    required String title,
    required String body,
    required String type,
    required String channelId,
    String? channelName,
    Map<String, dynamic>? payload,
    String? dedupeKey,
    bool fullScreen = false,
  }) async {
    await initialize();

    if (dedupeKey != null && _dedupeCache.contains(dedupeKey)) {
      await storeNotification(
        title: title,
        body: body,
        type: type,
        payload: payload,
        dedupeKey: dedupeKey,
        notificationId: id,
        channelId: channelId,
      );
      return;
    }

    if (dedupeKey != null) {
      _dedupeCache.add(dedupeKey);
    }

    final payloadString = payload == null ? null : jsonEncode(payload);

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName ?? channelId,
          channelDescription: 'local app notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          category: fullScreen
              ? AndroidNotificationCategory.call
              : AndroidNotificationCategory.reminder,
          fullScreenIntent: fullScreen,
          audioAttributesUsage: fullScreen
              ? AudioAttributesUsage.alarm
              : AudioAttributesUsage.notification,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payloadString,
    );

    await storeNotification(
      title: title,
      body: body,
      type: type,
      payload: payload,
      dedupeKey: dedupeKey,
      notificationId: id,
      channelId: channelId,
    );
  }

  static Future<void> storeNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? payload,
    String? dedupeKey,
    int? notificationId,
    String channelId = 'general_channel',
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final notifications = FirebaseFirestore.instance.collection('notifications');
    final docId = dedupeKey != null ? '$uid-$dedupeKey' : null;

    final data = <String, dynamic>{
      'userId': uid,
      'title': title,
      'body': body,
      'type': type,
      'channelId': channelId,
      'payload': payload,
      'isRead': false,
      'isViewed': false,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtClient': Timestamp.now(),
      'notificationId': notificationId,
      'dedupeKey': dedupeKey,
      'source': 'local',
    };

    if (docId != null) {
      await notifications.doc(docId).set(data, SetOptions(merge: true));
    } else {
      await notifications.add(data);
    }

    debugPrint('🔔 Stored local notification: $title');
  }
}
