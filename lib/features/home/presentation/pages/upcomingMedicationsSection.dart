import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class UpcomingMedicationsSection extends StatefulWidget {
  final List<Map<String, dynamic>> medications;

  const UpcomingMedicationsSection({super.key, required this.medications});

  @override
  State<UpcomingMedicationsSection> createState() => _UpcomingMedicationsSectionState();
}

class _UpcomingMedicationsSectionState extends State<UpcomingMedicationsSection> {
  final Set<String> takenMedications = {};

  Future<void> _markMedicationAsTaken(String medicationId) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('medications').doc(medicationId);
      final now = Timestamp.now();

      await docRef.update({
        'history': FieldValue.arrayUnion([now]),
      });

      setState(() {
        takenMedications.add(medicationId);
      });
    } catch (e) {
      debugPrint('Error updating medication history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ حدث خطأ أثناء تسجيل الجرعة')),
        );
      }
    }
  }

  String? getClosestTime(List<String> times) {
    final now = DateTime.now();
    final parsedTimes = times.map((t) {
      try {
        final dt = DateFormat('hh:mm a').parse(t);
        return DateTime(now.year, now.month, now.day, dt.hour, dt.minute);
      } catch (e) {
        debugPrint('❌ خطأ في تنسيق الوقت: $t - $e');
        return null;
      }
    }).where((t) => t != null).cast<DateTime>().toList();

    if (parsedTimes.isEmpty) return null;

    final futureToday = parsedTimes.where((t) => t.isAfter(now)).toList();

    if (futureToday.isNotEmpty) {
      futureToday.sort();
      return DateFormat('dd/MM/yyyy hh:mm a').format(futureToday.first);
    }

    final firstTomorrow = parsedTimes.first.add(const Duration(days: 1));
    return DateFormat('hh:mm a').format(firstTomorrow);
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "الرجاء تسجيل الدخول لعرض الأدوية.",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final userMeds = widget.medications.where((med) => med['userId'] == currentUserId).toList();

    if (userMeds.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.medication_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              "لا توجد أدوية مضافة بعد.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🩺 الأدوية القادمة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/medications');
                },
                child: const Text('عرض الكل'),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: userMeds.length,
          itemBuilder: (context, index) {
            final medication = userMeds[index];
            final medId = medication['id'] as String;
            final isTaken = takenMedications.contains(medId);

            final List<String> times = List<String>.from(medication['times'] ?? []);
            final closestTime = getClosestTime(times);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode?Colors.grey[900]:Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.medication_liquid_rounded, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                medication['name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.local_activity, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text('الجرعة: ${medication['dose'] ?? 'غير محدد'}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text('الوقت القادم: ${closestTime ?? 'لا يوجد'}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: isTaken
                            ? null
                            : () async {
                          await _markMedicationAsTaken(medId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✅ تم تسجيل الجرعة')),
                            );
                          }
                        },
                        icon: Icon(
                          isTaken ? Icons.check_circle : Icons.check_circle_outline,
                          color: Colors.white,
                        ),
                        label: Text(isTaken ? 'تم التناول' : 'تسجيل التناول'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTaken ? Colors.blue.shade700 : Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
