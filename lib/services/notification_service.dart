// lib/services/notification_service.dart
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'appointmentNotificationService.dart';
import 'call_message_notification_service.dart';
import 'medication_notification_service.dart';
import 'local_in_app_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // الخدمات الفرعية
  final MedicationNotificationService _medicationService = MedicationNotificationService();
  final AppointmentNotificationService _appointmentService = AppointmentNotificationService();
  final CallMessageNotificationService _callMessageService = CallMessageNotificationService();

  Future<void> initialize() async {
    // تهيئة جميع الخدمات
    await _medicationService.initialize();
    await _appointmentService.initialize();
    await _callMessageService.initialize();

    // تهيئة الإشعارات المحلية
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initSettings);
    await LocalInAppNotificationService.initialize();

    // إعداد FCM
    await _setupFCM();
  }

  Future<void> _setupFCM() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // معالجة الإشعارات في المقدمة
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleIncomingNotification(message);
    });

    // معالجة نقر الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });
  }

  void _handleIncomingNotification(RemoteMessage message) {
    final type = message.data['type'];

    switch (type) {
      case 'call':
        _showCallNotification(message);
        break;
      case 'message':
        _showMessageNotification(message);
        break;
      case 'appointment':
        _showAppointmentNotification(message);
        break;
      default:
        _showGeneralNotification(message);
    }
  }

  void _showCallNotification(RemoteMessage message) {
    // إشعار المكالمات (يظهر كملء شاشة)
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'call_channel',
      'مكالمات الفيديو',
      channelDescription: 'إشعارات المكالمات الفيديو',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      color: Color(0xFF2196F3),
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    final id = message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;
    _flutterLocalNotificationsPlugin.show(
      id,
      message.notification?.title ?? 'مكالمة فيديو',
      message.notification?.body ?? 'لديك مكالمة فيديو قادمة',
      notificationDetails,
      payload: message.data.toString(),
    );

    LocalInAppNotificationService.storeNotification(
      title: message.notification?.title ?? 'مكالمة فيديو',
      body: message.notification?.body ?? 'لديك مكالمة فيديو قادمة',
      type: 'call',
      payload: message.data,
      dedupeKey: 'call-${message.messageId ?? id}',
      notificationId: id,
      channelId: 'call_channel',
    );
  }

  void _showMessageNotification(RemoteMessage message) {
    // إشعار الرسائل
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'message_channel',
      'الرسائل الفورية',
      channelDescription: 'إشعارات الرسائل والاستشارات',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    final id = message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;
    _flutterLocalNotificationsPlugin.show(
      id,
      message.notification?.title ?? 'رسالة جديدة',
      message.notification?.body ?? 'لديك رسالة جديدة من الطبيب',
      notificationDetails,
      payload: message.data.toString(),
    );

    LocalInAppNotificationService.storeNotification(
      title: message.notification?.title ?? 'رسالة جديدة',
      body: message.notification?.body ?? 'لديك رسالة جديدة من الطبيب',
      type: 'message',
      payload: message.data,
      dedupeKey: 'message-${message.messageId ?? id}',
      notificationId: id,
      channelId: 'message_channel',
    );
  }

  void _showAppointmentNotification(RemoteMessage message) {
    // إشعارات المواعيد (FCM)
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'appointment_channel',
      'تنبيهات المواعيد',
      channelDescription: 'إشعارات تذكير بمواعيد العيادة',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    final id = message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;
    _flutterLocalNotificationsPlugin.show(
      id,
      message.notification?.title ?? 'تذكير بالموعد',
      message.notification?.body ?? 'لديك موعد قريب',
      notificationDetails,
      payload: message.data.toString(),
    );

    LocalInAppNotificationService.storeNotification(
      title: message.notification?.title ?? 'تذكير بالموعد',
      body: message.notification?.body ?? 'لديك موعد قريب',
      type: 'appointment',
      payload: message.data,
      dedupeKey: 'appointment-${message.messageId ?? id}',
      notificationId: id,
      channelId: 'appointment_channel',
    );
  }

  void _showGeneralNotification(RemoteMessage message) {
    // الإشعارات العامة
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'general_channel',
      'إشعارات عامة',
      channelDescription: 'الإشعارات العامة للتطبيق',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    final id = message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;
    _flutterLocalNotificationsPlugin.show(
      id,
      message.notification?.title ?? 'digl',
      message.notification?.body ?? '',
      notificationDetails,
      payload: message.data.toString(),
    );

    LocalInAppNotificationService.storeNotification(
      title: message.notification?.title ?? 'digl',
      body: message.notification?.body ?? '',
      type: 'general',
      payload: message.data,
      dedupeKey: 'general-${message.messageId ?? id}',
      notificationId: id,
      channelId: 'general_channel',
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    // معالجة نقر الإشعار والتنقل للشاشة المناسبة
    final type = message.data['type'];
    final consultationId = message.data['consultationId'];
    final appointmentId = message.data['appointmentId'];

    // استخدام Navigator للانتقال للشاشة المناسبة
  }

  // الحصول على token الجهاز
  Future<String?> getDeviceToken() async {
    return await _firebaseMessaging.getToken();
  }

  // الدوال المساعدة للخدمات الفرعية
  MedicationNotificationService get medication => _medicationService;
  AppointmentNotificationService get appointment => _appointmentService;
  CallMessageNotificationService get callMessage => _callMessageService;
}