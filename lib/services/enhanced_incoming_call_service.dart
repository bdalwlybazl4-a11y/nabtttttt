import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

/// خدمة محسّنة لاستقبال الاتصالات الواردة من أي مكان في التطبيق
/// - تدعم الاتصالات في الخلفية (Background)
/// - تدعم الاتصالات في المقدمة (Foreground)
/// - تعمل خارج شاشة المحادثة
class EnhancedIncomingCallService {
  static final EnhancedIncomingCallService _instance =
      EnhancedIncomingCallService._internal();

  factory EnhancedIncomingCallService() => _instance;
  EnhancedIncomingCallService._internal();

  static bool _isInitialized = false;
  static const String _logTag = '📞 [Enhanced Call Service]';

  // Callback للتعامل مع الاتصال الوارد
  static Function(Map<String, dynamic> callData)? _onIncomingCall;

  /// تهيئة الخدمة - يجب استدعاؤها في main.dart
  static Future<void> initialize({
    Function(Map<String, dynamic> callData)? onIncomingCall,
  }) async {
    if (_isInitialized) {
      _logDebug('الخدمة مهيأة بالفعل');
      return;
    }

    try {
      _logInfo('جاري تهيئة خدمة استقبال الاتصالات المحسّنة...');
      
      _onIncomingCall = onIncomingCall;

      // ✅ معالج الرسائل في المقدمة (Foreground)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // ✅ معالج الرسائل عند فتح التطبيق من الإشعار
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // ✅ طلب الأذونات
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      _isInitialized = true;
      _logSuccess('تم تهيئة خدمة استقبال الاتصالات بنجاح');
    } catch (e) {
      _logError('فشل التهيئة: $e');
    }
  }

  /// معالجة الرسائل في المقدمة (عندما يكون التطبيق مفتوحاً)
  static void _handleForegroundMessage(RemoteMessage message) {
    try {
      _logDebug('استقبال رسالة في المقدمة: ${message.data}');

      final data = message.data;
      final type = data['type'] ?? '';

      // إذا كانت رسالة استدعاء اتصال
      if (type == 'call' || type == 'incoming_call') {
        _logInfo('📞 استقبال دعوة اتصال');
        _processIncomingCall(data);
      }
    } catch (e) {
      _logError('خطأ في معالجة الرسالة: $e');
    }
  }

  /// معالجة فتح التطبيق من الإشعار
  static void _handleMessageOpenedApp(RemoteMessage message) {
    try {
      _logDebug('فتح التطبيق من إشعار: ${message.data}');

      final data = message.data;
      final type = data['type'] ?? '';

      if (type == 'call' || type == 'incoming_call') {
        _logInfo('📞 المستخدم نقر على إشعار المكالمة');
        _processIncomingCall(data);
      }
    } catch (e) {
      _logError('خطأ في معالجة النقر على الإشعار: $e');
    }
  }

  /// معالجة دعوة الاتصال
  static void _processIncomingCall(Map<String, dynamic> data) {
    try {
      _logDebug('معالجة دعوة الاتصال...');

      final callData = {
        'callId': data['callId'] ?? '',
        'consultationId': data['consultationId'] ?? '',
        'callerId': data['callerId'] ?? '',
        'callerName': data['callerName'] ?? '',
        'callerImage': data['callerImage'] ?? '',
        'isVideoCall': (data['isVideoCall'] ?? 'true').toString().toLowerCase() == 'true',
        'doctorId': data['doctorId'] ?? '',
        'patientId': data['patientId'] ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      _logInfo('بيانات الاتصال: $callData');

      // استدعاء callback إذا كان موجوداً
      if (_onIncomingCall != null) {
        _onIncomingCall!(callData);
      }

      _logSuccess('تم معالجة دعوة الاتصال بنجاح');
    } catch (e) {
      _logError('خطأ في معالجة الاتصال: $e');
    }
  }

  /// حفظ المكالمة الحالية في Firestore (اختياري للتتبع)
  static Future<void> logMissedCall({
    required String callerId,
    required String callerName,
    required String receiverId,
    required bool isVideoCall,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('call_logs').add({
        'callerId': callerId,
        'callerName': callerName,
        'receiverId': receiverId,
        'type': isVideoCall ? 'video' : 'audio',
        'status': 'missed',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _logSuccess('تم تسجيل المكالمة الملغاة');
    } catch (e) {
      _logError('خطأ في تسجيل المكالمة: $e');
    }
  }

  /// إرسال إشعار FCM للمستخدم عند وجود اتصال وارد
  /// (يُستخدم من الـ backend أو Cloud Functions)
  static Future<void> sendCallNotification({
    required String targetUserId,
    required String callerId,
    required String callerName,
    required String callerImage,
    required String consultationId,
    required bool isVideoCall,
  }) async {
    try {
      _logDebug('إرسال إشعار مكالمة...');

      // جلب FCM token المستخدم الهدف
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .get();

      final fcmToken = userDoc['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        _logWarning('لا يوجد FCM token للمستخدم');
        return;
      }

      // في تطبيق حقيقي، ستحتاج إلى استدعاء Cloud Function أو API خلفي
      // لإرسال الإشعار باستخدام Admin SDK
      _logInfo('سيتم إرسال الإشعار للـ token: ${fcmToken.substring(0, 20)}...');
    } catch (e) {
      _logError('خطأ في إرسال الإشعار: $e');
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

  /// التحقق من حالة التهيئة
  static bool get isInitialized => _isInitialized;

  /// إلغاء التهيئة
  static void dispose() {
    _isInitialized = false;
    _onIncomingCall = null;
    _logDebug('تم إلغاء تهيئة الخدمة');
  }
}
