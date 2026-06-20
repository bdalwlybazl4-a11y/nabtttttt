import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../features/appointments/presentation/pages/appointment_details_screen.dart';
import '../../features/model.dart';

class UpcomingAppointmentsWidget extends StatefulWidget {
  final List<Appointment> appointments;

  const UpcomingAppointmentsWidget({super.key, required this.appointments});

  @override
  State<UpcomingAppointmentsWidget> createState() => _UpcomingAppointmentsWidgetState();
}

class _UpcomingAppointmentsWidgetState extends State<UpcomingAppointmentsWidget> {
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // تعريب التاريخ
  String formatArabicDate(DateTime date) {
    return '${date.day} ${getArabicMonthName(date.month)} ${date.year}';
  }

  String getArabicMonthName(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(currentUserId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentUserData = snapshot.data!.data() as Map<String, dynamic>;
        final accountType = currentUserData['accountType'];
        final now = DateTime.now();
        final twoDaysAgo = now.subtract(const Duration(days: 2));

        final filteredAppointments = widget.appointments.where((appointment) {
          final appointmentDate = appointment.date.toDate();
          final belongsToUser = accountType == 'doctor'
              ? appointment.doctorId == currentUserId
              : appointment.userId == currentUserId;

          return belongsToUser && appointmentDate.isAfter(twoDaysAgo);
        }).toList();

        if (filteredAppointments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('لا توجد مواعيد قريبة حالياً', style: TextStyle(fontSize: 16)),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    accountType == 'doctor' ? 'مواعيد المرضى القادمة' : 'المواعيد القادمة',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/appointments');
                    },
                    child: const Text('عرض الكل'),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredAppointments.length,
              itemBuilder: (context, index) {
                final appointment = filteredAppointments[index];
                final date = appointment.date.toDate();

                final displayName = accountType == 'doctor'
                    ? appointment.userName
                    : appointment.doctorName;

                final displayImage = accountType == 'doctor'
                    ? appointment.userImageUrl ?? ''
                    : appointment.doctorImageUrl ?? '';

                final specialty = appointment.specialtyName;

                return _buildAppointmentCard(context, displayName, displayImage, appointment, date, specialty: specialty);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentCard(
      BuildContext context,
      String displayName,
      String displayImage,
      Appointment appointment,
      DateTime date, {
        String specialty = '',
      }) {
    final status = appointment.status;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    Color statusColor;

    String getStatusText(String status) {
      switch (status) {
        case 'pending':
          return 'قيد الانتظار';
        case 'confirmed':
          return 'مؤكد';
        case 'in_session':
          return 'داخل المعاينة';
        case 'canceled':
          return 'ملغي';
        default:
          return 'غير معروف';
      }
    }

    switch (status) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'in_session':
        statusColor = Colors.blue;
        break;
      case 'canceled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailsScreen(appointment: appointment),
          ),
        );
      },
      child: Card(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: displayImage.isNotEmpty
                    ? NetworkImage(displayImage)
                    : const AssetImage('assets/images/doctor_placeholder.png') as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (specialty.isNotEmpty) Text(specialty),
                    const SizedBox(height: 8),
                    Text('${formatArabicDate(date)} الساعة ${appointment.formattedTime}'),
                    const SizedBox(height: 8),
                    Text(
                      getStatusText(status),
                      style: TextStyle(color: statusColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
