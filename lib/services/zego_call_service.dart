import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class ZegoCallService {
  static final ZegoCallService _instance = ZegoCallService._internal();
  factory ZegoCallService() => _instance;
  ZegoCallService._internal();

  // ===== مفاتيح Zego Cloud =====
  static const int _zegoAppId = 266813973;
  static const String _zegoAppSign =
      '048d5c0539537562fb64c1c5013ef2b7bd2b196fc759ac2ba12f913432710e1f';

  static const String _logTag = '📞 [Zego Call Service]';

  // ===== Plugin واحد فقط =====
  static final ZegoUIKitSignalingPlugin _signalingPlugin = ZegoUIKitSignalingPlugin();

  static bool _isInitialized = false;
  static bool _isConnecting = false;

  static bool get isInitialized => _isInitialized;

  // ===== تهيئة Zego =====
  static Future<bool> initialize({
    required String userID,
    required String userName,
  }) async {
    if (_isInitialized) {
      _logSuccess("Zego مهيأ بالفعل");
      return true;
    }

    if (_isConnecting) {
      _logWarning("جاري التهيئة بالفعل...");
      return false;
    }

    try {
      _isConnecting = true;
      _logInfo("🚀 تهيئة Zego للمستخدم: $userID مع الاسم: $userName");

      // ✅ طلب أذونات الكاميرا والميكروفون
      await _requestPermissions();

      // ✅ استدعاء init
      await ZegoUIKitPrebuiltCallInvitationService().init(
        appID: _zegoAppId,
        appSign: _zegoAppSign,
        userID: userID,
        userName: userName,
        plugins: [_signalingPlugin],
      );

      _logDebug("تم استدعاء init بنجاح");

      // ✅ انتظار اتصال signaling
      bool connected = await _waitForSignalingConnection(maxRetries: 3);
      if (!connected) {
        _logError("فشل الاتصال بخدمة signaling بعد التهيئة");
        return false;
      }

      _isInitialized = true;
      _logSuccess("تم تهيئة Zego بنجاح وتم الاتصال بـ signaling");
      return true;
    } catch (e) {
      _logError("خطأ تهيئة Zego: $e");
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  // ===== طلب أذونات =====
  static Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses =
    await [Permission.camera, Permission.microphone].request();

    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        _logWarning("⚠️ تم رفض إذن $permission");
      }
    });
  }

  // ===== انتظار اتصال signaling =====
  static Future<bool> _waitForSignalingConnection({
    int timeoutSeconds = 15,
    int maxRetries = 3
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      _logInfo("⏳ محاولة الاتصال بالـ signaling #$attempt من $maxRetries");

      int elapsed = 0;
      while (_signalingPlugin.getConnectionState() !=
          ZegoSignalingPluginConnectionState.connected &&
          elapsed < timeoutSeconds) {
        await Future.delayed(const Duration(seconds: 1));
        elapsed++;
      }

      final currentState = _signalingPlugin.getConnectionState();
      _logDebug("🔍 حالة الاتصال الحالية: $currentState");

      if (currentState == ZegoSignalingPluginConnectionState.connected) {
        _logSuccess("✅ تم الاتصال بالـ signaling بنجاح!");
        return true;
      } else if (attempt < maxRetries) {
        _logDebug("🔄 إعادة المحاولة بعد 3 ثوان...");
        await Future.delayed(const Duration(seconds: 3));
      }
    }

    _logError("❌ فشل الاتصال بالـ signaling بعد $maxRetries محاولات!");
    return false;
  }

  // ===== حالة signaling =====
  static String getSignalingStatus() {
    final state = _signalingPlugin.getConnectionState();
    return "Initialized: $_isInitialized, State: $state";
  }

  // ===== بدء المكالمة =====
  static Future<void> _startCall({
    required String targetUserId,
    required String targetUserName,
    required String callId,
    required bool isVideoCall,
    required BuildContext context,
  }) async {
    try {
      _logInfo(isVideoCall
          ? "📹 محاولة إرسال دعوة مكالمة فيديو"
          : "📞 محاولة إرسال دعوة مكالمة صوتية");

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnack(context, "يجب تسجيل الدخول أولاً", Colors.red);
        return;
      }

      if (targetUserId == user.uid) {
        _showSnack(context, "لا يمكنك الاتصال بنفسك", Colors.red);
        return;
      }

      if (!_isInitialized) {
        bool ok = await initialize(
          userID: user.uid,
          userName: user.displayName ?? "User_${user.uid.substring(0,5)}",
        );
        if (!ok) {
          _showSnack(context, "فشل الاتصال بخدمة المكالمات", Colors.red);
          return;
        }
      }

      bool connected = await _waitForSignalingConnection(maxRetries: 3);
      if (!connected) {
        _isInitialized = false;
        _showSnack(context, "فشل الاتصال بخدمة المكالمات", Colors.red);
        return;
      }

      // ⚡ بدء البث قبل الدعوة
      // if (isVideoCall) {
      //   await ZegoUIKitPrebuiltCallController().startPreview();
      //   await ZegoUIKitPrebuiltCallController().startPublishingStream();
      // }

      await Future.delayed(const Duration(milliseconds: 500));

      // ✅ إرسال الدعوة
      await ZegoUIKitPrebuiltCallInvitationService().send(
        invitees: [ZegoCallUser(targetUserId, targetUserName)],
        isVideoCall: isVideoCall,
        callID: callId,
      );

      await _saveCallLog(targetUserId, isVideoCall ? "video" : "audio");

      _showSnack(
          context,
          isVideoCall
              ? "✅ تم إرسال دعوة فيديو\n⏳ في انتظار الرد..."
              : "✅ تم إرسال دعوة صوت\n⏳ في انتظار الرد...",
          Colors.green);
    } catch (e, st) {
      _logError("❌ خطأ أثناء إرسال الدعوة: $e\nStack: $st");
      _showSnack(context, "فشل إرسال المكالمة", Colors.red);
    }
  }

  // ===== مكالمات فيديو وصوت =====
  static Future<void> startVideoCall({
    required String targetUserId,
    required String targetUserName,
    required String callId,
    required BuildContext context,
  }) async =>
      await _startCall(
        targetUserId: targetUserId,
        targetUserName: targetUserName,
        callId: callId,
        isVideoCall: true,
        context: context,
      );

  static Future<void> startAudioCall({
    required String targetUserId,
    required String targetUserName,
    required String callId,
    required BuildContext context,
  }) async =>
      await _startCall(
        targetUserId: targetUserId,
        targetUserName: targetUserName,
        callId: callId,
        isVideoCall: false,
        context: context,
      );

  // ===== سجل المكالمات =====
  static Future<void> _saveCallLog(String targetUserId, String callType) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection("call_logs").add({
        "callerId": user.uid,
        "receiverId": targetUserId,
        "callType": callType,
        "timestamp": FieldValue.serverTimestamp(),
        "status": "initiated"
      });
    } catch (e) {
      _logError("خطأ حفظ سجل المكالمة: $e");
    }
  }

  // ===== إظهار Snackbar =====
  static void _showSnack(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // ===== إنهاء المكالمة =====
  static Future<void> endCall(BuildContext context) async {
    try {
      await ZegoUIKitPrebuiltCallController().hangUp(context);
      _logSuccess("✅ تم إنهاء المكالمة بنجاح");
    } catch (e) {
      _logError("خطأ إنهاء المكالمة: $e");
    }
  }

  // ===== إلغاء التهيئة =====
  static Future<void> uninitialize() async {
    try {
      await ZegoUIKitPrebuiltCallInvitationService().uninit();
      _isInitialized = false;
      _logSuccess("✅ تم إيقاف Zego بنجاح");
    } catch (e) {
      _logError("خطأ في إيقاف Zego: $e");
    }
  }

  // ===== Logging =====
  static void _logDebug(String msg) => debugPrint('$_logTag 🔍 $msg');
  static void _logInfo(String msg) => debugPrint('$_logTag ℹ️ $msg');
  static void _logSuccess(String msg) => debugPrint('$_logTag ✅ $msg');
  static void _logWarning(String msg) => debugPrint('$_logTag ⚠️ $msg');
  static void _logError(String msg) => debugPrint('$_logTag ❌ $msg');
}