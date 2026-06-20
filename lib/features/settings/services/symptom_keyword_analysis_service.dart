import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:digl/features/settings/models/symptom_keyword_analysis_model.dart';

/// محرك قواعد خفيف لتحليل الأعراض بالكلمات المفتاحية وربطها بالتخصص المناسب.
class SymptomKeywordAnalysisService {
  SymptomKeywordAnalysisService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<SymptomKeywordRule> rules = [
    SymptomKeywordRule(
      id: 'respiratory',
      organ: 'الجهاز التنفسي / الرئة',
      specialties: ['صدرية', 'رئة'],
      symptoms: ['ضيق تنفس', 'سعال', 'ألم بالرئة', 'صفير بالتنفس'],
      keywords: ['كحة', 'نهجان', 'صعوبة تنفس', 'صدر', 'بلغم', 'ربو'],
      patientMessage: 'قد تكون لديك مشكلة متعلقة بالجهاز التنفسي',
      icon: Icons.air_rounded,
      color: Color(0xFF2F80ED),
    ),
    SymptomKeywordRule(
      id: 'cardiology',
      organ: 'القلب والدورة الدموية',
      specialties: ['قلب', 'القلب والأوعية الدموية'],
      symptoms: ['خفقان', 'ألم بالقلب', 'ضغط بالصدر', 'تعب عند الحركة'],
      keywords: ['الم صدر', 'ألم الصدر', 'نبض سريع', 'دوخة مع الجهد', 'تعرق'],
      patientMessage: 'قد تكون لديك مشكلة متعلقة بالقلب',
      icon: Icons.favorite_rounded,
      color: Color(0xFFE63946),
    ),
    SymptomKeywordRule(
      id: 'dermatology',
      organ: 'الجلد',
      specialties: ['جلدية'],
      symptoms: ['طفح جلدي', 'حكة', 'احمرار الجلد', 'تقشر'],
      keywords: ['حساسية', 'حبوب', 'اكزيما', 'جلد', 'تورم الجلد'],
      patientMessage: 'قد تكون لديك مشكلة جلدية أو حساسية تحتاج تقييماً متخصصاً',
      icon: Icons.spa_rounded,
      color: Color(0xFF2CB67D),
    ),
    SymptomKeywordRule(
      id: 'ophthalmology',
      organ: 'العين',
      specialties: ['عيون'],
      symptoms: ['ضعف نظر', 'احمرار العين', 'ألم بالعين', 'تشوش الرؤية'],
      keywords: ['زغللة', 'رؤية ضبابية', 'دموع', 'حرقان العين', 'نظر'],
      patientMessage: 'قد تكون لديك مشكلة متعلقة بالعين أو النظر',
      icon: Icons.remove_red_eye_rounded,
      color: Color(0xFF7B61FF),
    ),
  ];

  static List<String> get allSymptoms => rules.expand((rule) => rule.symptoms).toSet().toList();

  static SymptomKeywordAnalysisResult? analyze(List<String> selectedSymptoms) {
    if (selectedSymptoms.isEmpty) return null;

    final scoredRules = rules
        .map((rule) => SymptomKeywordAnalysisResult(
              rule: rule,
              score: rule.matchScore(selectedSymptoms),
              selectedSymptoms: selectedSymptoms,
              createdAt: DateTime.now(),
            ))
        .where((result) => result.score > 0)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scoredRules.isEmpty ? null : scoredRules.first;
  }

  static Future<void> saveResult({
    required String patientId,
    required SymptomKeywordAnalysisResult result,
  }) async {
    await _firestore
        .collection('patients')
        .doc(patientId)
        .collection('health_assessments')
        .add({
      ...result.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'keyword_symptom_analysis',
    });
  }
}
