import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


import '../../../core/config/medical_theme.dart';
import '../../appointments/presentation/pages/appointment_details_screen.dart';
import '../../model.dart';

class AppointmentsScreen extends StatefulWidget {
  final DateTime? initialDate;

  const AppointmentsScreen({super.key, this.initialDate});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> appointments = [];
  String selectedStatus = 'all';
  DateTime? selectedDate;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      isLoading = true;
    });

    final doctorId = _auth.currentUser?.uid;
    if (doctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى تسجيل الدخول لعرض المواعيد'),
          backgroundColor: MedicalTheme.dangerRed,
        ),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      Query query = _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId);

      if (selectedStatus != 'all') {
        query = query.where('status', isEqualTo: selectedStatus);
      }

      if (selectedDate != null) {
        final startOfDay = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, 0, 0, 0);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        query = query
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('date', isLessThan: Timestamp.fromDate(endOfDay));
      }

      final snap = await query.get();

      // تصحيح: طباعة عدد المواعيد وبياناتها
      print('عدد المواعيد: ${snap.size}');

      // فرز محلياً حسب التاريخ (الأحدث أولاً)
      var sortedDocs = snap.docs;
      sortedDocs.sort((a, b) {
        final aDate = (a.data() as Map<String, dynamic>)['date'] as Timestamp?;
        final bDate = (b.data() as Map<String, dynamic>)['date'] as Timestamp?;
        return (bDate?.toDate() ?? DateTime(1970)).compareTo(aDate?.toDate() ?? DateTime(1970));
      });

      for (var doc in sortedDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final date = (data['date'] as Timestamp?)?.toDate();
        print('موعد ID: ${doc.id}, التاريخ: $date, الحالة: ${data['status']}, المريض: ${data['userName']}');
      }

      setState(() {
        appointments = sortedDocs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('خطأ في تحميل المواعيد: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل المواعيد: $e'),
          backgroundColor: MedicalTheme.dangerRed,
        ),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المواعيد'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _loadAppointments,
              child: appointments.isEmpty
                  ? const Center(child: Text('لا توجد مواعيد'))
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final data = appointments[index];
                  final patientName = data['userName'] ?? 'مريض';
                  final reason = data['reason'] ?? 'سبب غير معروف';
                  final time = data['date'] != null
                      ? DateFormat('hh:mm a', 'ar').format((data['date'] as Timestamp).toDate())
                      : 'بدون وقت';
                  final status = data['status'] ?? 'pending';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: data['userImageUrl'] != null
                            ? NetworkImage(data['userImageUrl'])
                            : null,
                        child: data['userImageUrl'] == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(patientName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$time - $reason'),
                          Text(
                            'الحالة: ${status == 'pending' ? 'جديد' : status == 'attended' ? 'تم الحضور' : 'ملغى'}',
                            style: TextStyle(
                                color: status == 'pending'
                                    ? MedicalTheme.pendingYellow
                                    : status == 'attended'
                                    ? MedicalTheme.successGreen
                                    : MedicalTheme.dangerRed),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        try {
                          final appointment = Appointment(
                            id: data['id'] ?? '',
                            userId: data['userId'] ?? '',
                            userName: data['userName'] ?? 'مريض',
                            userImageUrl: data['userImageUrl'],
                            userPhone: data['userPhone'],
                            doctorId: data['doctorId'] ?? '',
                            doctorName: data['doctorName'] ?? 'طبيب',
                            doctorImageUrl: data['doctorImageUrl'],
                            doctorPhone: data['doctorPhone'],
                            specialtyName: data['specialtyName'] ?? '',
                            date: data['date'] ?? Timestamp.now(),
                            time: data['time'] ?? '',
                            workplace: data['workplace'] ?? '',
                            payment: data['payment'] ?? '',
                            status: data['status'] ?? 'pending',
                            createdAt: data['createdAt'] ?? Timestamp.now(),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AppointmentDetailsScreen(
                                  appointment: appointment),
                            ),
                          );
                        } catch (e) {
                          print('خطأ في إنشاء كائن Appointment: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('خطأ في عرض تفاصيل الموعد: $e'),
                              backgroundColor: MedicalTheme.dangerRed,
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedStatus,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('الكل')),
                DropdownMenuItem(value: 'pending', child: Text('جديد')),
                DropdownMenuItem(value: 'attended', child: Text('تم الحضور')),
                DropdownMenuItem(value: 'cancelled', child: Text('ملغى')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedStatus = value!;
                  _loadAppointments();
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: widget.initialDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() {
                  selectedDate = date;
                  _loadAppointments();
                });
              }
            },
            child: Text(
              selectedDate == null
                  ? 'اختر التاريخ'
                  : DateFormat('dd MMM yyyy', 'ar').format(selectedDate!),
            ),
          ),
        ],
      ),
    );
  }
}
