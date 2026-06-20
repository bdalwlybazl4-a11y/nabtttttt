import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../model.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final Appointment appointment;

  const AppointmentDetailsScreen({Key? key, required this.appointment}) : super(key: key);

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  bool isDoctor = false;
  bool isLoading = true;
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.appointment.status;
    _checkUserType();
  }

  Future<void> _markInSession() async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointment.id)
          .update({'status': 'in_session'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إدخال المريض إلى المعاينة')),
      );

      setState(() {
        _status = 'in_session';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في التحديث: $e')),
      );
    }
  }

  Future<void> _checkUserType() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        isDoctor = userData['accountType'] == 'doctor';
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Error checking user type: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.appointment.date.toDate();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        title: const Text('تفاصيل الموعد'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.35),
              colorScheme.surface,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: colorScheme.primaryContainer,
                        backgroundImage: _contactImageUrl()?.isNotEmpty == true
                            ? NetworkImage(_contactImageUrl()!)
                            : null,
                        child: _contactImageUrl()?.isNotEmpty == true
                            ? null
                            : Icon(Icons.person_rounded, color: colorScheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDoctor ? widget.appointment.userName : widget.appointment.doctorName,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isDoctor ? 'المريض' : widget.appointment.specialtyName,
                              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary),
                            ),
                            const SizedBox(height: 10),
                            _buildInfoChip(
                              context,
                              icon: Icons.phone,
                              text:
                                  'رقم الهاتف: ${isDoctor ? widget.appointment.userPhone ?? "غير متوفر" : widget.appointment.doctorPhone ?? "غير متوفر"}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _buildDetailRow(context, Icons.location_on_outlined, 'المكان', widget.appointment.workplace),
                      _buildDetailRow(context, Icons.calendar_month_rounded, 'التاريخ', formatArabicDate(date)),
                      _buildDetailRow(context, Icons.schedule_rounded, 'الوقت', widget.appointment.time),
                      _buildDetailRow(context, Icons.payments_outlined, 'طريقة الدفع', widget.appointment.payment),
                      _buildDetailRow(context, Icons.price_check_rounded, 'حالة الدفع', _translatePaymentStatus(widget.appointment.paymentStatus)),
                      _buildDetailRow(
                        context,
                        Icons.local_hospital_outlined,
                        'الحالة',
                        _translateStatus(_status),
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: colorScheme.secondaryContainer.withOpacity(0.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.medical_information_rounded, color: colorScheme.secondary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('يمكنك متابعة حالة الموعد وتحديثه فوراً من هذه الشاشة.'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _confirmCancel(context),
                      icon: const Icon(Icons.cancel_rounded),
                      label: const Text('إلغاء الموعد'),
                      style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                    ),
                  ),
                  if (isDoctor && _status == 'pending') ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _confirmAppointment,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('الموافقة'),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              if (isDoctor && _status == 'confirmed')
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _markInSession,
                    icon: const Icon(Icons.medical_services_rounded),
                    label: const Text('المريض داخل المعاينة'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _contactImageUrl() {
    return isDoctor ? widget.appointment.userImageUrl : widget.appointment.doctorImageUrl;
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String title,
    String value, {
    bool isLast = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value.isNotEmpty ? value : '—',
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
      ],
    );
  }

  Widget _buildInfoChip(BuildContext context, {required IconData icon, required String text}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.primaryContainer.withOpacity(0.45),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  String formatArabicDate(DateTime date) {
    return '${date.day} ${getArabicMonthName(date.month)} ${date.year}';
  }

  String getArabicMonthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return months[month - 1];
  }

  String _translatePaymentStatus(String status) {
    switch (status) {
      case 'pending_at_visit': return 'الدفع عند المقابلة';
      case 'pending_on_delivery': return 'الدفع عند المقابلة';
      case 'paid': return 'مدفوع';
      case 'unpaid': return 'غير مدفوع';
      default: return status;
    }
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'confirmed':
        return 'مؤكد';
      case 'in_session':
        return 'داخل المعاينة';
      case 'canceled':
      case 'cancelled':
        return 'ملغي';
      default:
        return 'قيد الانتظار';
    }
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الإلغاء'),
        content: const Text('هل أنت متأكد أنك تريد إلغاء هذا الموعد؟'),
        actions: [
          TextButton(
            child: const Text('تراجع'),
            onPressed: () => Navigator.pop(ctx),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('نعم، إلغاء'),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('appointments')
                    .doc(widget.appointment.id)
                    .delete();

                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إلغاء الموعد بنجاح')),
                );
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('فشل في إلغاء الموعد: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAppointment() async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointment.id)
          .update({'status': 'confirmed'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت الموافقة على الموعد')),
      );

      setState(() {
        _status = 'confirmed';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في الموافقة: $e')),
      );
    }
  }
}
