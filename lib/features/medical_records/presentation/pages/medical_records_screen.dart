import 'package:flutter/material.dart';
import 'package:digl/core/config/theme.dart';
import 'package:share_plus/share_plus.dart';

class MedicalRecordsScreen extends StatelessWidget {
  const MedicalRecordsScreen({super.key});

  void _downloadRecord(BuildContext context, String title) {
    // Logic to download the record
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تحميل السجل: $title')),
    );
  }

  void _shareRecord(String title) {
    // Logic to share the record
    Share.share('مشاركة السجل الطبي: $title');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('السجل الطبي'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('الفحوصات والتحاليل',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildRecordCard(
            context,
            title: 'فحص دم شامل',
            date: '2024-06-01',
            doctor: 'د. أحمد محمد',
            diagnosis: 'نتائج طبيعية',
            medications: ['فيتامين د', 'حديد'],
            recommendations: ['تناول مكملات الحديد', 'إعادة الفحص بعد 3 أشهر'],
          ),
          _buildRecordCard(
            context,
            title: 'تحليل سكر',
            date: '2024-05-15',
            doctor: 'د. سارة أحمد',
            diagnosis: 'ارتفاع بسيط في السكر',
            medications: ['ميتفورمين'],
            recommendations: ['تقليل السكريات', 'ممارسة الرياضة'],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(
    BuildContext context, {
    required String title,
    required String date,
    required String doctor,
    required String diagnosis,
    required List<String> medications,
    required List<String> recommendations,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(title),
        subtitle: Text('بتاريخ $date - $doctor'),
        children: [
          ListTile(
            leading: const Icon(Icons.info, color: AppTheme.primaryBlue),
            title: const Text('التشخيص'),
            subtitle: Text(diagnosis),
          ),
          ListTile(
            leading: const Icon(Icons.medication, color: AppTheme.primaryBlue),
            title: const Text('الأدوية الموصوفة'),
            subtitle: Text(medications.join(', ')),
          ),
          ListTile(
            leading: const Icon(Icons.recommend, color: AppTheme.positiveGreen),
            title: const Text('التوصيات'),
            subtitle: Text(recommendations.join('، ')),
          ),
          OverflowBar(
            children: [
              TextButton.icon(
                onPressed: () => _downloadRecord(context, title),
                icon: const Icon(Icons.download),
                label: const Text('تحميل'),
              ),
              TextButton.icon(
                onPressed: () => _shareRecord(title),
                icon: const Icon(Icons.share),
                label: const Text('مشاركة'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
