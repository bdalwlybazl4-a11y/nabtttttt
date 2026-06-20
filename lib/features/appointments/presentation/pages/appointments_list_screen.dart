import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../services/appointment_service.dart';
import '../../../model.dart';
import 'appointment_details_screen.dart';

class AppointmentsListScreen extends StatefulWidget {
  const AppointmentsListScreen({super.key});

  @override
  State<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen> {
  String selectedStatus = 'الكل';
  DateTime? selectedDate;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final appointmentService = Provider.of<AppointmentService>(context);
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        elevation: 1,
        title: const Text('جميع المواعيد'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(currentUserId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final accountType = userData['accountType'];

          return StreamBuilder<List<Appointment>>(
            stream: appointmentService.getAppointments(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('حدث خطأ أثناء تحميل المواعيد'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('لا توجد مواعيد'));
              }

              var appointments = snapshot.data!
                  .where((appointment) => accountType == 'doctor'
                      ? appointment.doctorId == currentUserId
                      : appointment.userId == currentUserId)
                  .toList();

              if (selectedStatus != 'الكل') {
                appointments =
                    appointments.where((a) => a.status == selectedStatus).toList();
              }

              if (selectedDate != null) {
                appointments = appointments.where((a) {
                  final date = a.date.toDate();
                  return date.year == selectedDate!.year &&
                      date.month == selectedDate!.month &&
                      date.day == selectedDate!.day;
                }).toList();
              }

              if (appointments.isEmpty) {
                return const Center(child: Text('لا توجد مواعيد مطابقة'));
              }

              appointments.sort((a, b) => a.date.toDate().compareTo(b.date.toDate()));

              final grouped = <String, List<Appointment>>{};
              for (final appointment in appointments) {
                final key = DateFormat('yyyy-MM-dd').format(appointment.date.toDate());
                grouped.putIfAbsent(key, () => []).add(appointment);
              }

              final keys = grouped.keys.toList()..sort();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                itemCount: keys.length,
                itemBuilder: (context, index) {
                  final dayKey = keys[index];
                  final dayAppointments = grouped[dayKey]!;
                  return _buildDaySection(
                    context,
                    dayAppointments,
                    accountType,
                    dayKey,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDaySection(
    BuildContext context,
    List<Appointment> dayAppointments,
    String accountType,
    String dayKey,
  ) {
    final date = DateTime.parse(dayKey);
    final title = DateFormat('EEEE، d MMMM yyyy', 'ar').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8, top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.45),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...dayAppointments.map((appointment) => _buildAppointmentCard(
              context,
              appointment,
              accountType,
            )),
      ],
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    Appointment appointment,
    String accountType,
  ) {
    final theme = Theme.of(context);
    final displayName =
        accountType == 'doctor' ? (appointment.userName) : (appointment.doctorName);

    final displayImageUrl = accountType == 'doctor'
        ? (appointment.userImageUrl ?? '')
        : (appointment.doctorImageUrl ?? '');

    final date = appointment.date.toDate();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AppointmentDetailsScreen(appointment: appointment),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: displayImageUrl.isNotEmpty
                    ? NetworkImage(displayImageUrl)
                    : const AssetImage('assets/images/doctor_placeholder.png')
                        as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _infoChip(Icons.access_time_rounded,
                            DateFormat('hh:mm a', 'en').format(date)),
                        _infoChip(Icons.event_rounded,
                            DateFormat('dd/MM/yyyy').format(date)),
                        _statusChip(context, appointment.status),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_forever, color: theme.colorScheme.error),
                tooltip: 'إلغاء الموعد',
                onPressed: _isDeleting
                    ? null
                    : () => _confirmDelete(context, appointment.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.withOpacity(0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blueGrey),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _statusChip(BuildContext context, String status) {
    final color = _statusColor(context, status);
    final label = statusLabels[status] ?? status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.15),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String appointmentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الإلغاء'),
        content: const Text('هل أنت متأكد من إلغاء هذا الموعد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _deleteAppointment(appointmentId);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    setState(() => _isDeleting = true);
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إلغاء الموعد بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الإلغاء: $e')),
      );
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  final Map<String, String> statusLabels = {
    'الكل': 'الكل',
    'pending': 'قيد الانتظار',
    'confirmed': 'مؤكد',
    'in_session': 'داخل المعاينة',
    'canceled': 'ملغي',
  };

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تصفية حسب الحالة:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: statusLabels.entries.map((entry) {
                final statusKey = entry.key;
                final statusLabel = entry.value;

                return ChoiceChip(
                  label: Text(statusLabel),
                  selected: selectedStatus == statusKey,
                  onSelected: (_) {
                    setState(() => selectedStatus = statusKey);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(selectedDate == null
                  ? 'اختيار تاريخ'
                  : DateFormat('yyyy-MM-dd').format(selectedDate!)),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                  Navigator.pop(context);
                }
              },
            ),
            if (selectedDate != null)
              TextButton(
                child: const Text('إزالة التاريخ'),
                onPressed: () {
                  setState(() => selectedDate = null);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'canceled':
        return scheme.error;
      default:
        return scheme.primary;
    }
  }
}
