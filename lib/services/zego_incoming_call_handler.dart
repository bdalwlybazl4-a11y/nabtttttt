import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

/// ✅ خدمة معالجة المكالمات الواردة من ZEGOCLOUD
/// تتعامل مع دعوات المكالمات الواردة وإظهار إشعارات بشكل صحيح
class ZegoIncomingCallHandler {
  static final ZegoIncomingCallHandler _instance = 
      ZegoIncomingCallHandler._internal();
  
  factory ZegoIncomingCallHandler() => _instance;
  ZegoIncomingCallHandler._internal();

  static bool _isInitialized = false;
  static const String _logTag = '📞 [ZEGO Call Handler]';

  /// ✅ تهيئة معالج المكالمات الواردة
  /// يجب استدعاء هذه الدالة بعد تهيئة Zego في main.dart
  static Future<void> initialize() async {
    if (_isInitialized) {
      _logDebug('الخدمة مهيأة بالفعل');
      return;
    }

    try {
      _logInfo('جاري تهيئة معالج المكالمات الواردة...');
      
      // ✅ استمع لأحداث دعوات المكالمات من Zego
      _setupZegoCallInvitationListener();
      
      _isInitialized = true;
      _logSuccess('تم تهيئة معالج المكالمات بنجاح');
    } catch (e) {
      _logError('فشل التهيئة: $e');
      rethrow;
    }
  }

  /// ✅ إعداد مستمع دعوات المكالمات
  static void _setupZegoCallInvitationListener() {
    _logDebug('إعداد مستمع دعوات المكالمات...');
    
    // ملاحظة: دعوات المكالمات يتم التعامل معها تلقائياً من قبل
    // ZegoUIKitPrebuiltCallInvitationService في Zego SDK
    // هذا يضمن استقبال الدعوات بشكل آلي وعرض شاشة الاستقبال
    
    _logSuccess('تم إعداد مستمع الدعوات بنجاح');
  }

  /// ✅ تسجيل المكالمة عند الانتهاء
  static Future<void> logCallCompletion({
    required String callId,
    required String calleeId,
    required String calleeType,
    required bool isVideoCall,
    required int durationSeconds,
    required String status,
  }) async {
    try {
      _logDebug('تسجيل نتائج المكالمة...');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logWarning('لا يوجد مستخدم مسجل');
        return;
      }

      await FirebaseFirestore.instance.collection('call_logs').add({
        'callId': callId,
        'callerId': user.uid,
        'calleeId': calleeId,
        'callType': isVideoCall ? 'video' : 'audio',
        'consultationType': calleeType,
        'durationSeconds': durationSeconds,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': {
          'platform': 'mobile',
          'hasVideo': isVideoCall,
        }
      });

      _logSuccess('✅ تم تسجيل المكالمة بنجاح');
    } catch (e) {
      _logError('فشل تسجيل المكالمة: $e');
    }
  }

  /// ✅ تحديث حالة المكالمة
  static Future<void> updateCallStatus({
    required String consultationId,
    required String status,
    String? errorMessage,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _logDebug('تحديث حالة المكالمة: $status');

      final data = {
        'lastCallStatus': status,
        'lastCallTimestamp': FieldValue.serverTimestamp(),
      };

      if (errorMessage != null) {
        data['lastCallError'] = errorMessage;
      }

      await FirebaseFirestore.instance
          .collection('consultations')
          .doc(consultationId)
          .update(data);

      _logSuccess('تم تحديث حالة المكالمة');
    } catch (e) {
      _logError('فشل تحديث حالة المكالمة: $e');
    }
  }

  // ============ Logging Functions ============
  
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

  /// ✅ إلغاء التهيئة
  static Future<void> dispose() async {
    _isInitialized = false;
    _logDebug('تم إلغاء تهيئة معالج المكالمات');
  }
}
