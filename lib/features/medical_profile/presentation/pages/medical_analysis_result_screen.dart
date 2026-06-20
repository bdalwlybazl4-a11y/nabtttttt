import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digl/features/medical_profile/services/advanced_diagnosis_service.dart';
import 'package:digl/features/medical_profile/services/doctor_matching_service.dart';
import 'package:digl/features/medical_profile/models/doctor_recommendation_model.dart';
import 'package:digl/core/config/theme.dart';

/// 📊 شاشة عرض نتائج التحليل الطبي والتوصيات المتقدمة
/// تعرض النتائج بشكل احترافي وطبي مع توصيات الأدوية والأطباء
class MedicalAnalysisResultScreen extends StatefulWidget {
  final MedicalAnalysisResult analysisResult;
  final String patientName;

  const MedicalAnalysisResultScreen({
    Key? key,
    required this.analysisResult,
    required this.patientName,
  }) : super(key: key);

  @override
  State<MedicalAnalysisResultScreen> createState() =>
      _MedicalAnalysisResultScreenState();
}

class _MedicalAnalysisResultScreenState
    extends State<MedicalAnalysisResultScreen> {
  bool _isSavingResults = false;
  List<DoctorRecommendation> _recommendedDoctors = [];
  bool _loadingDoctors = false;

  @override
  void initState() {
    super.initState();
    _saveAnalysisResults();
    _loadRecommendedDoctors();
  }

  /// ✅ جلب الأطباء الموصى بهم بناءً على التخصصات
  Future<void> _loadRecommendedDoctors() async {
    setState(() => _loadingDoctors = true);
    try {
      final doctors = await DoctorMatchingService.findMatchingDoctors(
        recommendedSpecialties: widget.analysisResult.recommendedSpecialties,
        symptoms: widget.analysisResult.matchedSymptoms,
        returnCount: 5,
      );
      setState(() => _recommendedDoctors = doctors);
      print('✅ تم تحميل ${doctors.length} طبيب موصى به');
    } catch (e) {
      print('❌ خطأ في تحميل الأطباء: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingDoctors = false);
      }
    }
  }

  /// ✅ حفظ نتائج التحليل في Firestore
  Future<void> _saveAnalysisResults() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await AdvancedDiagnosisService.saveMedicalAnalysis(
          user.uid,
          widget.analysisResult,
        );
        print('✅ تم حفظ نتائج التحليل');
      }
    } catch (e) {
      print('❌ خطأ في حفظ النتائج: $e');
    }
  }

  /// ✅ الحصول على لون الخطورة
  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'high':
        return const Color(0xFFFF6B6B);
      case 'medium':
        return const Color(0xFFFFA500);
      case 'low':
        return const Color(0xFF4CC9A7);
      default:
        return Colors.grey;
    }
  }

  /// ✅ الحصول على نص الخطورة
  String _getSeverityText(String severity) {
    switch (severity) {
      case 'high':
        return 'خطر عالي - يُنصح بزيارة فورية';
      case 'medium':
        return 'خطر متوسط - يُنصح بزيارة قريباً';
      case 'low':
        return 'خطر منخفض - راقب الأعراض';
      default:
        return 'غير محدد';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ AppBar بتصميم احترافي
      appBar: AppBar(
        title: const Text('نتائج التحليل الطبي'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ بطاقة معلومات المريض
            _buildPatientInfoCard(),

            const SizedBox(height: 24),

            // ✅ بطاقة تقييم الخطورة
            _buildSeverityCard(),

            const SizedBox(height: 24),

            // ✅ قسم الأعراض المكتشفة
            _buildSymptomsSection(),

            const SizedBox(height: 24),

            // ✅ قسم توصيات الأدوية
            _buildMedicinesSection(),

            const SizedBox(height: 24),

            // ✅ قسم التخصصات الطبية المقترحة
            _buildSpecialtiesSection(),

            const SizedBox(height: 24),

            // ✅ قسم الأطباء الموصى بهم
            _buildRecommendedDoctorsSection(),

            const SizedBox(height: 24),

            // ✅ قسم الإجراءات الفورية
            _buildImmediateActionsSection(),

            const SizedBox(height: 24),

            // ✅ التحليل المفصل
            _buildDetailedAnalysisSection(),

            const SizedBox(height: 24),

            // ✅ أزرار الإجراءات
            _buildActionButtons(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ✅ بطاقة معلومات المريض
  Widget _buildPatientInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryBlue, Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patientName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📅 ${DateTime.now().toString().split(' ')[0]}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ بطاقة تقييم الخطورة
  Widget _buildSeverityCard() {
    final color = _getSeverityColor(widget.analysisResult.severity);
    final text = _getSeverityText(widget.analysisResult.severity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getWarningIcon(widget.analysisResult.severity),
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تقييم الخطورة',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ الحصول على أيقونة التحذير
  IconData _getWarningIcon(String severity) {
    switch (severity) {
      case 'high':
        return Icons.error;
      case 'medium':
        return Icons.warning;
      case 'low':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  // ✅ قسم الأعراض المكتشفة
  Widget _buildSymptomsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🔍 الأعراض المكتشفة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.analysisResult.matchedSymptoms.asMap().entries.map(
            (entry) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  entry.value,
                  style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ],
    );
  }

  // ✅ قسم توصيات الأدوية
  Widget _buildMedicinesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💊 الأدوية المقترحة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.analysisResult.recommendedMedicines.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'لا توجد أدوية مقترحة في الوقت الحالي',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.analysisResult.recommendedMedicines.length,
            itemBuilder: (context, index) {
              final medicine =
                  widget.analysisResult.recommendedMedicines[index];
              return _buildMedicineCard(medicine, index + 1);
            },
          ),
      ],
    );
  }

  // ✅ بطاقة الدواء الواحد
  Widget _buildMedicineCard(
    MedicineRecommendation medicine,
    int index,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        medicine.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.positiveGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'التطابق: ${medicine.matchPercentage}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.positiveGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildMedicineDetail('💉 المادة الفعالة', medicine.activeIngredient),
            const SizedBox(height: 8),
            _buildMedicineDetail('📏 الجرعة', medicine.dose),
            if (medicine.sideEffects.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildMedicineDetail('⚠️ الآثار الجانبية', medicine.sideEffects.join('، ')),
            ],
            if (medicine.warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildMedicineDetail('🔔 تحذيرات', medicine.warnings.join('، ')),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ تفصيل الدواء
  Widget _buildMedicineDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ✅ قسم التخصصات الطبية
  Widget _buildSpecialtiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '👨‍⚕️ التخصصات الطبية المقترحة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.analysisResult.recommendedSpecialties.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'لا توجد تخصصات مقترحة في الوقت الحالي',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount:
                widget.analysisResult.recommendedSpecialties.length,
            itemBuilder: (context, index) {
              final specialty =
                  widget.analysisResult.recommendedSpecialties[index];
              return _buildSpecialtyCard(specialty, index + 1);
            },
          ),
      ],
    );
  }

  // ✅ بطاقة التخصص الواحد
  Widget _buildSpecialtyCard(
    SpecialtyRecommendation specialty,
    int index,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryBlue, Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        specialty.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialty.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: specialty.matchPercentage / 100,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
            const SizedBox(height: 4),
            Text(
              'التطابق: ${specialty.matchPercentage}%',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ قسم الأطباء الموصى بهم
  Widget _buildRecommendedDoctorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '👨‍⚕️ الأطباء الموصى بهم',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingDoctors)
          const Center(
            child: CircularProgressIndicator(),
          )
        else if (_recommendedDoctors.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'لا يوجد أطباء متاحون في الوقت الحالي',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recommendedDoctors.length,
            itemBuilder: (context, index) {
              final doctor = _recommendedDoctors[index];
              return _buildDoctorCard(doctor, index + 1);
            },
          ),
      ],
    );
  }

  // ✅ بطاقة الطبيب الواحد
  Widget _buildDoctorCard(DoctorRecommendation doctor, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الترتيب والاسم والتخصص
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryBlue, Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '#$index',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor.specialtyName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // التقييم والخبرة والتطابق
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'التقييم',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${doctor.rating.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الاستشارات',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor.consultationCount.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'التطابق',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.positiveGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${doctor.matchPercentage}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.positiveGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (doctor.reasonsForRecommendation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'أسباب التوصية:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...doctor.reasonsForRecommendation.map((reason) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• $reason',
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // سيتم إضافة الربط مع الاستشارة
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'سيتم إضافة ميزة الاستشارة المباشرة مع ${doctor.fullName}',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.phone, size: 18),
                label: const Text('استشارة الآن'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ قسم الإجراءات الفورية
  Widget _buildImmediateActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚡ الإجراءات الفورية',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3CD).withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFC107).withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              widget.analysisResult.immediateActions.length,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: index < widget.analysisResult.immediateActions.length - 1 ? 12 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text(
                          '✓',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.analysisResult.immediateActions[index],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ التحليل المفصل
  Widget _buildDetailedAnalysisSection() {
    return ExpansionTile(
      title: const Text(
        '📋 التحليل المفصل',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.analysisResult.detailedAnalysis,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.6,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  // ✅ أزرار الإجراءات
  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          },
          icon: const Icon(Icons.home),
          label: const Text('العودة للصفحة الرئيسية'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).pushNamed('/book_appointment');
          },
          icon: const Icon(Icons.calendar_today),
          label: const Text('حجز موعد مع طبيب'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryBlue,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: const BorderSide(color: AppTheme.primaryBlue),
          ),
        ),
      ],
    );
  }
}
