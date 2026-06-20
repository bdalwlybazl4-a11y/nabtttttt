import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:digl/features/consultations/presentation/pages/consultation_screen.dart';
import 'package:digl/features/medications/presentation/pages/medication_details_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  Future<void> _markAsRead(String docId) async {
    await FirebaseFirestore.instance.collection('notifications').doc(docId).update({
      'isRead': true,
      'isViewed': true,
      'viewedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteNotification(String docId, BuildContext context) async {
    await FirebaseFirestore.instance.collection('notifications').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف الإشعار')),
    );
  }

  Future<void> _deleteAllNotifications(BuildContext context) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final collection = FirebaseFirestore.instance.collection('notifications');
    final snapshots = await collection.where('userId', isEqualTo: currentUserId).get();

    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف جميع الإشعارات')),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'message':
        return Icons.chat_bubble_rounded;
      case 'call':
        return Icons.call_rounded;
      case 'medication':
      case 'medication_schedule':
      case 'medication_cancel':
        return Icons.medication_rounded;
      case 'appointment':
      case 'appointment_schedule':
        return Icons.calendar_month_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'message':
        return Colors.blue;
      case 'call':
        return Colors.purple;
      case 'medication':
      case 'medication_schedule':
      case 'medication_cancel':
        return Colors.green;
      case 'appointment':
      case 'appointment_schedule':
        return Colors.orange;
      default:
        return Colors.teal;
    }
  }

  Future<void> _openNotificationTarget(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final type = (data['type'] ?? 'general').toString();
    final payload = data['payload'] is Map
        ? Map<String, dynamic>.from(data['payload'] as Map)
        : <String, dynamic>{};

    if (type.startsWith('medication')) {
      final medicationId = (payload['medicationId'] ?? data['medicationId'])?.toString();
      if (medicationId != null && medicationId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicationDetailsScreen(medicationId: medicationId),
          ),
        );
      }
      return;
    }

    if (type == 'message') {
      final consultationId =
          (payload['consultationId'] ?? data['consultationId'])?.toString();
      if (consultationId == null || consultationId.isEmpty) return;

      final doc = await FirebaseFirestore.instance
          .collection('consultations')
          .doc(consultationId)
          .get();
      final consultation = doc.data();
      if (consultation == null) return;

      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final isDoctor = consultation['doctorId'] == userId;

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConsultationScreen(
            consultationId: consultationId,
            doctorUid: consultation['doctorId'] ?? '',
            patientUid: consultation['userId'] ?? '',
            doctorName: consultation['doctorName'] ?? '',
            patientName: consultation['userName'] ?? '',
            doctorImage: (consultation['doctorImage'] ?? '').toString(),
            userImage: (consultation['userImage'] ?? '').toString(),
            isDoctor: isDoctor,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('يرجى تسجيل الدخول لعرض الإشعارات')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        foregroundColor: Colors.blue,
        elevation: 2,
        title: const Text('الإشعارات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'حذف جميع الإشعارات',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('تأكيد الحذف'),
                  content: const Text('هل أنت متأكد من حذف جميع الإشعارات؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('حذف'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _deleteAllNotifications(context);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ في تحميل الإشعارات'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aCreatedAt = (aData['createdAt'] ?? aData['createdAtClient']) as Timestamp?;
            final bCreatedAt = (bData['createdAt'] ?? bData['createdAtClient']) as Timestamp?;
            return (bCreatedAt?.toDate() ?? DateTime(1970))
                .compareTo(aCreatedAt?.toDate() ?? DateTime(1970));
          });

          if (docs.isEmpty) {
            return const Center(child: Text('لا توجد إشعارات'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['isRead'] ?? false;
              final type = (data['type'] ?? 'general').toString();
              final color = _typeColor(type);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  tileColor: isRead ? theme.cardColor : color.withOpacity(0.08),
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.12),
                    child: Icon(_typeIcon(type), color: color),
                  ),
                  title: Text(data['title'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['body'] ?? ''),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(
                          (data['createdAt'] ?? data['createdAtClient']) as Timestamp?,
                        ),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'حذف الإشعار',
                    onPressed: () => _deleteNotification(doc.id, context),
                  ),
                  onTap: () async {
                    await _markAsRead(doc.id);
                    if (!context.mounted) return;
                    await _openNotificationTarget(context, data);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
