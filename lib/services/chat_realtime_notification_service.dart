import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'local_in_app_notification_service.dart';

class ChatRealtimeNotificationService {
  ChatRealtimeNotificationService._();
  static final ChatRealtimeNotificationService _instance =
      ChatRealtimeNotificationService._();

  factory ChatRealtimeNotificationService() => _instance;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _consultationsSub;
  final Set<String> _seenMessageKeys = <String>{};

  void start() {
    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _consultationsSub?.cancel();
      if (user != null) {
        _listenForIncomingMessages(user.uid);
      }
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _listenForIncomingMessages(currentUser.uid);
    }
  }

  void _listenForIncomingMessages(String userId) {
    _consultationsSub?.cancel();

    _consultationsSub = FirebaseFirestore.instance
        .collection('consultations')
        .where('newMessageFor', isEqualTo: userId)
        .where('hasNewMessage', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) continue;
        _notifyForLatestMessage(change.doc.id, userId);
      }
    });
  }

  Future<void> _notifyForLatestMessage(String consultationId, String userId) async {
    final messages = await FirebaseFirestore.instance
        .collection('consultations')
        .doc(consultationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (messages.docs.isEmpty) return;

    final messageDoc = messages.docs.first;
    final message = messageDoc.data();
    if ((message['senderId'] ?? '') == userId) return;

    final messageKey = '$consultationId-${messageDoc.id}';
    if (_seenMessageKeys.contains(messageKey)) return;
    _seenMessageKeys.add(messageKey);

    final consultationDoc = await FirebaseFirestore.instance
        .collection('consultations')
        .doc(consultationId)
        .get();
    final consultation = consultationDoc.data() ?? {};

    final senderName = (message['senderName'] ?? 'رسالة جديدة').toString();
    final text = (message['text'] ?? '').toString();
    final messageType = (message['type'] ?? 'text').toString();

    final body = text.isNotEmpty
        ? text
        : (messageType == 'audio' || messageType == 'audio_inline')
            ? 'رسالة صوتية جديدة'
            : 'رسالة جديدة';

    await LocalInAppNotificationService.showAndStore(
      id: messageKey.hashCode & 0x7fffffff,
      title: 'رسالة من $senderName',
      body: body,
      type: 'message',
      channelId: 'message_channel',
      payload: {
        'consultationId': consultationId,
        'messageId': messageDoc.id,
        'type': 'message',
        'doctorId': consultation['doctorId'] ?? '',
        'userId': consultation['userId'] ?? '',
        'doctorName': consultation['doctorName'] ?? '',
        'patientName': consultation['userName'] ?? '',
        'isDoctor': consultation['doctorId'] == userId,
      },
      dedupeKey: 'chat-$messageKey',
    );
  }
}
