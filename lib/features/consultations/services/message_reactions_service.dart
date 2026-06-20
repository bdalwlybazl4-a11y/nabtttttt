import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_reaction_model.dart';

/// خدمة إدارة التفاعلات على الرسائل
class MessageReactionsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// إضافة أو إزالة تفاعل على رسالة
  /// إذا كان المستخدم قد أضاف هذا التفاعل بالفعل، سيتم حذفه
  /// إذا أضاف emoji آخر، سيتم استبداله
  static Future<void> toggleReaction({
    required String consultationId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل دخول');

      // التحقق من أن emoji صحيح
      if (!ReactionEmojis.isValid(emoji)) {
        throw Exception('تفاعل غير صحيح');
      }

      final messageRef = _firestore
          .collection('consultations')
          .doc(consultationId)
          .collection('messages')
          .doc(messageId);

      final messageDoc = await messageRef.get();
      if (!messageDoc.exists) {
        throw Exception('الرسالة غير موجودة');
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;
      final reactions = messageData['reactions'] as Map<String, dynamic>? ?? {};

      // نسخة محدثة من التفاعلات
      final updatedReactions = Map<String, dynamic>.from(reactions);

      // البحث عن تفاعل سابق للمستخدم
      String? previousEmoji;
      for (var entry in updatedReactions.entries) {
        final userIds = List<String>.from(entry.value['userIds'] as List? ?? []);
        if (userIds.contains(user.uid)) {
          previousEmoji = entry.key;
          break;
        }
      }

      // إذا كان للمستخدم تفاعل سابق بنفس الـ emoji، احذفه
      if (previousEmoji == emoji) {
        final userIds = List<String>.from(
          updatedReactions[emoji]['userIds'] as List? ?? [],
        );
        userIds.remove(user.uid);

        if (userIds.isEmpty) {
          // احذف التفاعل كلياً إذا لم يبقَ أحد
          updatedReactions.remove(emoji);
        } else {
          // حدّث قائمة المستخدمين
          updatedReactions[emoji] = {
            'emoji': emoji,
            'userIds': userIds,
            'createdAt': updatedReactions[emoji]['createdAt'],
            'updatedAt': FieldValue.serverTimestamp(),
          };
        }
      } else {
        // إذا كان للمستخدم تفاعل سابق مختلف، احذفه أولاً
        if (previousEmoji != null) {
          final previousUserIds = List<String>.from(
            updatedReactions[previousEmoji]!['userIds'] as List? ?? [],
          );
          previousUserIds.remove(user.uid);

          if (previousUserIds.isEmpty) {
            updatedReactions.remove(previousEmoji);
          } else {
            updatedReactions[previousEmoji] = {
              'emoji': previousEmoji,
              'userIds': previousUserIds,
              'createdAt': updatedReactions[previousEmoji]!['createdAt'],
              'updatedAt': FieldValue.serverTimestamp(),
            };
          }
        }

        // أضف التفاعل الجديد
        if (updatedReactions.containsKey(emoji)) {
          // التفاعل موجود بالفعل
          final userIds = List<String>.from(
            updatedReactions[emoji]['userIds'] as List? ?? [],
          );
          userIds.add(user.uid);
          updatedReactions[emoji] = {
            'emoji': emoji,
            'userIds': userIds,
            'createdAt': updatedReactions[emoji]['createdAt'],
            'updatedAt': FieldValue.serverTimestamp(),
          };
        } else {
          // تفاعل جديد
          updatedReactions[emoji] = {
            'emoji': emoji,
            'userIds': [user.uid],
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };
        }
      }

      // حفظ التفاعلات المحدثة
      await messageRef.update({'reactions': updatedReactions});

      print('✅ تم تحديث التفاعل بنجاح');
    } catch (e) {
      print('❌ خطأ في تحديث التفاعل: $e');
      rethrow;
    }
  }

  /// جلب جميع التفاعلات على رسالة معينة
  static Future<List<MessageReaction>> getReactions({
    required String consultationId,
    required String messageId,
  }) async {
    try {
      final messageDoc = await _firestore
          .collection('consultations')
          .doc(consultationId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        return [];
      }

      final data = messageDoc.data() as Map<String, dynamic>?;
      final reactions = data?['reactions'] as Map<String, dynamic>? ?? {};

      return reactions.entries
          .map((e) => MessageReaction.fromMap(e.value as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ خطأ في جلب التفاعلات: $e');
      return [];
    }
  }

  /// حذف جميع التفاعلات على رسالة (بواسطة المسؤول فقط)
  static Future<void> clearAllReactions({
    required String consultationId,
    required String messageId,
  }) async {
    try {
      await _firestore
          .collection('consultations')
          .doc(consultationId)
          .collection('messages')
          .doc(messageId)
          .update({'reactions': {}});

      print('✅ تم حذف جميع التفاعلات');
    } catch (e) {
      print('❌ خطأ في حذف التفاعلات: $e');
      rethrow;
    }
  }

  /// جلب التفاعل الحالي للمستخدم على رسالة معينة
  static Future<String?> getUserReaction({
    required String consultationId,
    required String messageId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final reactions = await getReactions(
        consultationId: consultationId,
        messageId: messageId,
      );

      // البحث عن التفاعل الذي أضافه المستخدم
      for (var reaction in reactions) {
        if (reaction.hasUserReacted(user.uid)) {
          return reaction.emoji;
        }
      }

      return null;
    } catch (e) {
      print('❌ خطأ في جلب تفاعل المستخدم: $e');
      return null;
    }
  }
}
