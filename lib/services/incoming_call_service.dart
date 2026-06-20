// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_callkit_incoming/entities/android_params.dart';
// import 'package:flutter_callkit_incoming/entities/call_event.dart';
// import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
// import 'package:flutter_callkit_incoming/entities/ios_params.dart';
// import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
// import 'dart:async';
//
// /// خدمة المكالمات الواردة
// class IncomingCallService {
//   static final IncomingCallService _instance = IncomingCallService._internal();
//   factory IncomingCallService() => _instance;
//   IncomingCallService._internal();
//
//   static bool _isInitialized = false;
//   static StreamSubscription<CallEvent?>? _callKitSubscription;
//
//   /// تهيئة الخدمة
//   static Future<void> initialize() async {
//     if (_isInitialized) return;
//
//     try {
//       print('⏳ جاري تهيئة خدمة المكالمات الواردة...');
//
//       // الاستماع لأحداث CallKit
//       _callKitSubscription = FlutterCallkitIncoming.onEvent.listen((event) {
//         if (event != null) _handleCallKitEvent(event);
//       });
//
//       _isInitialized = true;
//       print('✅ تم تهيئة خدمة المكالمات الواردة');
//
//       _listenForIncomingCalls();
//     } catch (e) {
//       print('❌ خطأ في التهيئة: $e');
//       _isInitialized = false;
//     }
//   }
//
//   /// الاستماع للمكالمات الواردة من Firebase
//   static void _listenForIncomingCalls() {
//     final currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser == null) return;
//
//     FirebaseFirestore.instance
//         .collection('incoming_calls')
//         .where('receiverId', isEqualTo: currentUser.uid)
//         .where('status', isEqualTo: 'pending')
//         .snapshots()
//         .listen((snapshot) {
//       for (var doc in snapshot.docs) {
//         _handleIncomingCallFromFirebase(doc.data(), doc.id);
//       }
//     });
//   }
//
//   /// معالجة المكالمة الواردة
//   static Future<void> _handleIncomingCallFromFirebase(
//       Map<String, dynamic> callData, String callDocId) async {
//     try {
//       final callId = callData['callId'] as String;
//       final callerName = callData['callerName'] as String;
//       final callerImage = callData['callerImage'] as String?;
//       final isVideoCall = callData['isVideoCall'] as bool;
//
//       await showIncomingCallNotification(
//         callId: callId,
//         callerName: callerName,
//         callerImage: callerImage,
//         isVideoCall: isVideoCall,
//       );
//
//       await FirebaseFirestore.instance
//           .collection('incoming_calls')
//           .doc(callDocId)
//           .update({
//         'status': 'ringing',
//         'ringStartTime': FieldValue.serverTimestamp(),
//       });
//     } catch (e) {
//       print('❌ خطأ في معالجة المكالمة: $e');
//     }
//   }
//
//   /// عرض إشعار المكالمة الواردة
//   static Future<void> showIncomingCallNotification({
//     required String callId,
//     required String callerName,
//     String? callerImage,
//     required bool isVideoCall,
//   }) async {
//     try {
//       final params = CallKitParams(
//         id: callId,
//         nameCaller: callerName,
//         appName: 'Digl Medical',
//         avatar: callerImage ?? '',
//         duration: 30000,
//         type: isVideoCall ? 1 : 0,
//         textAccept: 'قبول',
//         textDecline: 'رفض',
//         //textMissedCall: 'مكالمة ملغاة',
//         //textCallback: 'إعادة الاتصال',
//         extra: {'callId': callId, 'isVideo': isVideoCall},
//         headers: {'description': isVideoCall ? 'مكالمة فيديو' : 'مكالمة صوتية'},
//         android: AndroidParams(
//           isCustomNotification: true,
//           ringtonePath: 'system_ringtone_default',
//           backgroundColor: '#0c6986',
//           backgroundUrl: callerImage,
//         ),
//         ios: IOSParams(
//           iconName: 'CallKitLogo',
//           handleType: 'generic',
//           supportsVideo: isVideoCall,
//           maximumCallGroups: 1,
//           maximumCallsPerCallGroup: 1,
//           //muted: false,
//         ),
//       );
//
//       await FlutterCallkitIncoming.showCallkitIncoming(params);
//       print('✅ تم عرض إشعار المكالمة');
//     } catch (e) {
//       print('❌ خطأ في عرض الإشعار: $e');
//     }
//   }
//
//   /// معالجة أحداث CallKit
//   static void _handleCallKitEvent(CallEvent event) {
//     if (event.event == null) return;
//
//     switch (event.event) {
//       case 'callkit.incoming.show':
//         print('📞 عرض شاشة المكالمة الواردة');
//         break;
//
//       case 'callkit.call.accept':
//         _acceptCall(event);
//         break;
//
//       case 'callkit.call.decline':
//         _rejectCall(event);
//         break;
//
//       case 'callkit.call.end':
//         _endCall(event);
//         break;
//
//       default:
//         print('❓ حدث آخر: ${event.event}');
//     }
//   }
//
//   static void _acceptCall(CallEvent event) {
//     final extra = event.body; // الإصدار الجديد يستخدم body بدل extra
//     if (extra is Map) {
//       final callId = extra['callId'];
//       print('📞 تم قبول المكالمة: $callId');
//       _updateCallStatus(callId, 'accepted');
//     }
//   }
//
//   static void _rejectCall(CallEvent event) {
//     final extra = event.body;
//     if (extra is Map) {
//       final callId = extra['callId'];
//       print('❌ تم رفض المكالمة: $callId');
//       _updateCallStatus(callId, 'rejected');
//     }
//   }
//
//   static void _endCall(CallEvent event) {
//     final extra = event.body;
//     if (extra is Map) {
//       final callId = extra['callId'];
//       print('📵 تم إنهاء المكالمة: $callId');
//       _updateCallStatus(callId, 'ended');
//     }
//   }
//
//   static Future<void> _updateCallStatus(String callId, String status) async {
//     await FirebaseFirestore.instance
//         .collection('incoming_calls')
//         .doc(callId)
//         .update({
//       'status': status,
//       'updatedAt': FieldValue.serverTimestamp(),
//     });
//   }
//
//   /// إلغاء التهيئة
//   static Future<void> dispose() async {
//     await _callKitSubscription?.cancel();
//     _isInitialized = false;
//   }
// }