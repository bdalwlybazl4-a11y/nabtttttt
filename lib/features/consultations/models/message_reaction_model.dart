import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج التفاعل على الرسائل
/// يحتفظ بمعلومات التفاعل (emoji) ومن أضافه
class MessageReaction {
  final String emoji; // 👍 ❤️ 😂 😢 🔥 إلخ
  final List<String> userIds; // قائمة معرفات المستخدمين الذين أضافوا التفاعل
  final Timestamp createdAt; // وقت إضافة أول تفاعل
  final Timestamp updatedAt; // آخر تحديث للتفاعل

  MessageReaction({
    required this.emoji,
    required this.userIds,
    required this.createdAt,
    required this.updatedAt,
  });

  /// تحويل النموذج إلى خريطة للحفظ في Firebase
  Map<String, dynamic> toMap() {
    return {
      'emoji': emoji,
      'userIds': userIds,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// إنشاء النموذج من خريطة Firebase
  factory MessageReaction.fromMap(Map<String, dynamic> data) {
    return MessageReaction(
      emoji: data['emoji'] as String? ?? '',
      userIds: List<String>.from(data['userIds'] as List? ?? []),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  /// عدد المستخدمين الذين أضافوا هذا التفاعل
  int get count => userIds.length;

  /// فحص ما إذا قام مستخدم معين بإضافة هذا التفاعل
  bool hasUserReacted(String userId) => userIds.contains(userId);
}

/// قائمة التفاعلات المتاحة للمستخدمين
class ReactionEmojis {
  static const List<String> available = [
    '👍', // إعجاب
    '❤️', // حب
    '😂', // смех / ضحك
    '😢', // حزن
    '😠', // غضب
    '🔥', // رائع
    '👏', // تصفيق
    '🎉', // احتفالي
  ];

  /// التحقق من أن emoji موجود في القائمة المتاحة
  static bool isValid(String emoji) => available.contains(emoji);
}
