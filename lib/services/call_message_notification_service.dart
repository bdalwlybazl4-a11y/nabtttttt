// lib/services/call_message_notification_service.dart
import 'dart:convert';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'local_in_app_notification_service.dart';

class CallMessageNotificationService {
  static final CallMessageNotificationService _instance =
  CallMessageNotificationService._internal();

  factory CallMessageNotificationService() => _instance;
  CallMessageNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // طلب الأذونات
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // إنشاء قنوات الإشعارات
    await _createNotificationChannels();
    await LocalInAppNotificationService.initialize();

    // معالجة الإشعارات في الخلفية
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // الحصول على token بدون إيقاف تشغيل التطبيق إذا كانت خدمة FCM غير متاحة مؤقتاً.
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveDeviceToken(token);
      }
    } catch (e) {
      print('تعذر الحصول على FCM token حالياً وسيستمر تشغيل التطبيق: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    // قناة المكالمات
    const AndroidNotificationChannel callChannel = AndroidNotificationChannel(
      'call_channel',
      'مكالمات الفيديو',
      description: 'إشعارات المكالمات الفيديو والاستشارات',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // قناة الرسائل
    const AndroidNotificationChannel messageChannel = AndroidNotificationChannel(
      'message_channel',
      'الرسائل الفورية',
      description: 'إشعارات الرسائل والاستشارات',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(callChannel);
    await androidPlugin?.createNotificationChannel(messageChannel);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      _showLocalNotification(
        id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
        title: notification.title ?? 'digl',
        body: notification.body ?? '',
        channel: data['type'] == 'call' ? 'call_channel' : 'message_channel',
        payload: data,
      );
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    // معالجة نقر الإشعار في الخلفية
    _navigateToScreen(message.data);
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required String channel,
    required Map<String, dynamic> payload,
  }) async {
    // 1. تحويل الـ Map إلى String
    final String payloadString = json.encode(payload);

    // 2. استخدام المعلمة channel الديناميكية كمعرف للقناة
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channel, // استخدام المعلمة الديناميكية بدلاً من القيمة الثابتة
      'مكالمات الفيديو',
      channelDescription: 'إشعارات المكالمات الفيديو والاستشارات',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      color: Color(0xFF2196F3),
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(id, title, body, notificationDetails, payload: payloadString);

    await LocalInAppNotificationService.storeNotification(
      title: title,
      body: body,
      type: channel == 'call_channel' ? 'call' : 'message',
      payload: payload,
      dedupeKey: '${channel}-${payload['consultationId'] ?? payload['callId'] ?? id}',
      notificationId: id,
      channelId: channel,
    );
  }
  Future<void> _saveDeviceToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  void _navigateToScreen(Map<String, dynamic> data) {
    // التنقل للشاشة المناسبة بناءً على نوع الإشعار
    final type = data['type'];
    final consultationId = data['consultationId'];
    final callId = data['callId'];

    // يمكنك استخدام Navigator هنا للانتقال للشاشة المناسبة
  }
}