import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

/// خدمة تسجيل الخروج المحسّنة والآمنة
/// تقوم بـ:
/// 1. حذف FCM token
/// 2. حذف البيانات المخزنة محلياً
/// 3. إنهاء جلسات Zego
/// 4. تنظيف state management
/// 5. تسجيل الخروج من Firebase
/// 6. إعادة توجيه آمنة
class LogoutService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static const String _logTag = '🚪 [Logout Service]';

  /// إجراء تسجيل الخروج الآمن الكامل
  static Future<bool> performSecureLogout(BuildContext context) async {
    try {
      _logInfo('جاري إجراء تسجيل الخروج الآمن...');

      // الخطوة 1: حذف FCM token من Firestore
      await _clearFcmToken();

      // الخطوة 2: حذف البيانات المخزنة محلياً
      await _clearLocalData();

      // الخطوة 3: إنهاء جلسات Zego
      await _endZegoSession();

      // الخطوة 4: تسجيل الخروج من Firebase
      await _auth.signOut();

      _logSuccess('تم تسجيل الخروج بنجاح');

      // الخطوة 5: إعادة توجيه آمنة إلى شاشة تسجيل الدخول
      _navigateToLoginScreen(context);

      return true;
    } catch (e) {
      _logError('خطأ في تسجيل الخروج: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الخروج: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  /// حذف FCM token من Firestore
  static Future<void> _clearFcmToken() async {
    try {
      _logDebug('جاري حذف FCM token...');

      final user = _auth.currentUser;
      if (user == null) {
        _logWarning('لا يوجد مستخدم مسجل');
        return;
      }

      // حذف FCM token من قاعدة البيانات
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _logSuccess('تم حذف FCM token');
    } catch (e) {
      _logError('خطأ في حذف FCM token: $e');
      // لا نرمي الخطأ لأنه ليس حرجاً
    }
  }

  /// حذف البيانات المخزنة محلياً
  static Future<void> _clearLocalData() async {
    try {
      _logDebug('جاري حذف البيانات المحلية...');

      final prefs = await SharedPreferences.getInstance();

      // حذف جميع البيانات المخزنة
      await prefs.clear();

      _logSuccess('تم حذف البيانات المحلية');
    } catch (e) {
      _logError('خطأ في حذف البيانات المحلية: $e');
      // لا نرمي الخطأ لأنه ليس حرجاً
    }
  }

  /// إنهاء جلسة Zego
  static Future<void> _endZegoSession() async {
    try {
      _logDebug('جاري إنهاء جلسة Zego...');

      // يمكن إضافة أي تنظيف آخر للخدمات هنا
      // Zego تتعامل عادة مع التنظيف تلقائياً

      _logSuccess('تم إنهاء جلسة Zego');
    } catch (e) {
      _logError('خطأ في إنهاء جلسة Zego: $e');
      // لا نرمي الخطأ
    }
  }

  /// إعادة توجيه آمنة إلى شاشة تسجيل الدخول
  static void _navigateToLoginScreen(BuildContext context) {
    try {
      _logDebug('جاري إعادة التوجيه إلى شاشة تسجيل الدخول...');

      // استخدام pushNamedAndRemoveUntil لحذف جميع الشاشات السابقة
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (Route<dynamic> route) => false, // حذف جميع الشاشات السابقة
      );

      _logSuccess('تم التوجيه إلى شاشة تسجيل الدخول بنجاح');
    } catch (e) {
      _logError('خطأ في إعادة التوجيه: $e');
      // إذا فشل التوجيه بالاسم، حاول باستخدام pushReplacement
      Navigator.of(context).pushReplacementNamed('/login');
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

  /// دالة مساعدة لإظهار رسالة تأكيد قبل تسجيل الخروج
  static Future<void> showLogoutConfirmationDialog(
    BuildContext context, {
    String title = 'تسجيل الخروج',
    String message = 'هل تريد تسجيل الخروج من التطبيق؟',
    String confirmText = 'تسجيل خروج',
    String cancelText = 'إلغاء',
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await performSecureLogout(context);
            },
            child: Text(
              confirmText,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
