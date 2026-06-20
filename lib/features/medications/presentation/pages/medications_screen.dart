import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:digl/services/user_role_service.dart';
import 'package:digl/services/patient_medication_reminder_service.dart';

import 'medication_form.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  String? userId;
  bool isLoading = true;
  bool canAddMedications = false;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final user = FirebaseAuth.instance.currentUser;
    final canAdd = await UserRoleService.canAddMedication();

    setState(() {
      userId = user?.uid;
      canAddMedications = canAdd;
      isLoading = false;
    });
  }

  Future<void> _deleteMedication(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content:
        const Text('هل أنت متأكد أنك تريد حذف هذا الدواء؟ لا يمكن التراجع بعد الحذف.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );

    if (confirm == true) {
      await PatientMedicationReminderService.cancelMedicationReminders(docId);
      await FirebaseFirestore.instance.collection('medications').doc(docId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الدواء')));
    }
  }

  Future<void> _approveMedication(String medicationId) async {
    await PatientMedicationReminderService.approveMedication(medicationId: medicationId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ تمت الموافقة وتمت جدولة المنبهات يوميًا')),
    );
  }

  Future<void> _rejectMedication(String medicationId) async {
    await PatientMedicationReminderService.rejectMedication(medicationId: medicationId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم رفض طلب الدواء')),
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'approved':
        return 'موافق عليه';
      case 'rejected':
        return 'مرفوض';
      case 'pending':
      default:
        return 'بانتظار موافقة المريض';
    }
  }



  int _remainingDays(Map<String, dynamic> data) {
    final durationRaw = data['durationDays']?.toString() ?? data['duration']?.toString() ?? '30';
    final days = int.tryParse(RegExp(r'\d+').firstMatch(durationRaw)?.group(0) ?? '30') ?? 30;
    final approvedAt = data['approvedAt'] as Timestamp?;
    final start = approvedAt?.toDate() ?? DateTime.now();
    final end = start.add(Duration(days: days));
    final left = end.difference(DateTime.now()).inDays;
    return left < 0 ? 0 : left;
  }

  String _formatRemainingDays(Map<String, dynamic> data) {
    final d = _remainingDays(data);
    return d == 0 ? 'انتهت المدة' : 'متبقي $d يوم';
  }
  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (userId == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: Text('الرجاء تسجيل الدخول.')),
      );
    }

    Query medicationsQuery = FirebaseFirestore.instance.collection('medications');
    medicationsQuery = canAddMedications
        ? medicationsQuery.where('userId', isEqualTo: userId)
        : medicationsQuery.where('patientId', isEqualTo: userId);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        title: Text(canAddMedications ? 'إدارة الأدوية' : 'أدويتي'),
        actions: [
          if (canAddMedications)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: IconButton.filledTonal(
                icon: const Icon(Icons.add_rounded),
                onPressed: () async {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (context) => MedicationFormScreen(userId: userId!)),
                  );
                  if (updated == true) setState(() {});
                },
              ),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: medicationsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ في تحميل البيانات'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          docs.sort((a, b) {
            final aCreatedAt = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final bCreatedAt = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            return (bCreatedAt?.toDate() ?? DateTime(1970))
                .compareTo(aCreatedAt?.toDate() ?? DateTime(1970));
          });

          if (docs.isEmpty) {
            return _buildEmptyState(
              canAddMedications ? 'لا توجد أدوية مضافة بعد.' : 'لا توجد وصفات أدوية واردة من الطبيب حالياً.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: docs.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) return _buildHeaderCard(docs.length);

                final doc = docs[index - 1];
                final data = doc.data() as Map<String, dynamic>;
                final times = (data['times'] as List<dynamic>? ?? []).cast<String>();
                final status = (data['status'] ?? 'pending').toString();
                final createdAt = data['createdAt'] as Timestamp?;
                return _buildMedicationCard(doc, data, times, status, createdAt);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(int count) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.75)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.onPrimary.withOpacity(0.18),
            child: Icon(Icons.medication_liquid_rounded, color: colorScheme.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(canAddMedications ? 'إدارة وصفات المرضى' : 'خطة أدويتك اليومية', style: TextStyle(color: colorScheme.onPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('$count عنصر مسجل', style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.82))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(DocumentSnapshot doc, Map<String, dynamic> data, List<String> times, String status, Timestamp? createdAt) {
    final docId = doc.id;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _statusColor(status);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: theme.shadowColor.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 8))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: colorScheme.primaryContainer.withOpacity(0.45), borderRadius: BorderRadius.circular(16)),
          child: Icon(Icons.medication_rounded, color: colorScheme.primary),
        ),
        title: Text(data['name'] ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _miniChip('${data['dose'] ?? ''} • ${data['schedule'] ?? ''}', Icons.schedule_rounded, colorScheme.primary),
              _statusChip(status, statusColor),
            ],
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
          onPressed: () => _deleteMedication(docId),
        ),
        children: [
          _detailRow('النوع', data['type'] ?? ''),
          _detailRow('المدة', data['duration'] ?? ''),
          _detailRow('ملاحظات', data['notes'] ?? ''),
          if (status == 'approved') _detailRow('مدة العلاج', _formatRemainingDays(data), valueColor: Colors.green),
          if (createdAt != null) _detailRow('تم الإنشاء', DateFormat('yyyy/MM/dd hh:mm a').format(createdAt.toDate())),
          const SizedBox(height: 8),
          if (times.isNotEmpty) Text('الأوقات اليومية:', style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: times.map((t) => Chip(label: Text(t))).toList()),
          const SizedBox(height: 10),
          if (!canAddMedications && status == 'pending')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveMedication(docId),
                    icon: const Icon(Icons.check),
                    label: const Text('موافقة'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectMedication(docId),
                    icon: const Icon(Icons.close),
                    label: const Text('رفض'),
                    style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
                  ),
                ),
              ],
            ),
          if (canAddMedications)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () async {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (context) => MedicationFormScreen(userId: userId!, doc: doc)),
                  );
                  if (updated == true) setState(() {});
                },
                icon: const Icon(Icons.edit_rounded),
                label: const Text('تعديل'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusChip(String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(99)),
      child: Text(_statusText(status), style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }

  Widget _miniChip(String text, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 14, color: color), const SizedBox(width: 4), Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(.64), fontSize: 12))],
    );
  }

  Widget _detailRow(String label, Object value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 86, child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(.64), fontWeight: FontWeight.w700))),
          Expanded(child: Text(value.toString(), style: TextStyle(color: valueColor ?? Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.medication_outlined, size: 72, color: colorScheme.primary.withOpacity(0.45)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurface.withOpacity(.64), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

}