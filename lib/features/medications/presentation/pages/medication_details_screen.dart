import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MedicationDetailsScreen extends StatelessWidget {
  final String medicationId;

  const MedicationDetailsScreen({super.key, required this.medicationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الدواء'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('medications')
            .doc(medicationId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data();
          if (data == null) {
            return const Center(child: Text('لم يتم العثور على الدواء'));
          }

          final times = (data['times'] as List<dynamic>? ?? []).cast<String>();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _tile('اسم الدواء', data['name'] ?? '—', Icons.medication_rounded),
              _tile('الجرعة', data['dose'] ?? '—', Icons.local_pharmacy_rounded),
              _tile('التعليمات', data['schedule'] ?? '—', Icons.schedule_rounded),
              _tile('المدة', data['duration'] ?? '—', Icons.timelapse_rounded),
              _tile('الحالة', data['status'] ?? '—', Icons.flag_rounded),
              _tile('ملاحظات الطبيب', data['notes'] ?? '—', Icons.note_alt_rounded),
              const SizedBox(height: 12),
              const Text('الأوقات اليومية',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: times.map((t) => Chip(label: Text(t))).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}
