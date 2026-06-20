import 'package:cloud_firestore/cloud_firestore.dart';

class AiChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime createdAt;
  final String? attachmentPath;
  final String? attachmentType;

  const AiChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.createdAt,
    this.attachmentPath,
    this.attachmentType,
  });

  factory AiChatMessage.fromMap(String id, Map<String, dynamic> map) => AiChatMessage(
        id: id,
        content: (map['content'] ?? '').toString(),
        isUser: map['isUser'] == true,
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.tryParse((map['createdAt'] ?? '').toString()) ?? DateTime.now(),
        attachmentPath: map['attachmentPath']?.toString(),
        attachmentType: map['attachmentType']?.toString(),
      );

  Map<String, dynamic> toMap({bool firestore = true}) => {
        'content': content,
        'isUser': isUser,
        'createdAt': firestore ? Timestamp.fromDate(createdAt) : createdAt.toIso8601String(),
        if (attachmentPath != null) 'attachmentPath': attachmentPath,
        if (attachmentType != null) 'attachmentType': attachmentType,
      };
}
