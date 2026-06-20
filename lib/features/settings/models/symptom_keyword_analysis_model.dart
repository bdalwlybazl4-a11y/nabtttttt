import 'package:flutter/material.dart';
import 'package:digl/features/medical_profile/services/advanced_diagnosis_service.dart';

/// نموذج قابل للتوسعة لربط الأعراض والكلمات المفتاحية بالعضو والتخصص.
/// أضف قاعدة جديدة هنا أو من خدمة خارجية مستقبلاً دون تغيير منطق الشاشة.
class SymptomKeywordRule {
  final String id;
  final String organ;
  final List<String> specialties;
  final List<String> symptoms;
  final List<String> keywords;
  final String patientMessage;
  final IconData icon;
  final Color color;

  const SymptomKeywordRule({
    required this.id,
    required this.organ,
    required this.specialties,
    required this.symptoms,
    required this.keywords,
    required this.patientMessage,
    required this.icon,
    required this.color,
  });

  int matchScore(Iterable<String> selectedSymptoms) {
    final normalizedInputs = selectedSymptoms.map(_normalizeArabic).toList();
    final normalizedKeywords = [...symptoms, ...keywords].map(_normalizeArabic).toList();

    var score = 0;
    for (final input in normalizedInputs) {
      for (final keyword in normalizedKeywords) {
        if (input.contains(keyword) || keyword.contains(input)) {
          score += symptoms.map(_normalizeArabic).contains(keyword) ? 3 : 2;
        }
      }
    }
    return score;
  }

  SpecialtyRecommendation toSpecialtyRecommendation(int score) {
    final percentage = (55 + (score * 9)).clamp(60, 98).toInt();
    return SpecialtyRecommendation(
      name: specialties.first,
      description: '$patientMessage ننصح بمراجعة ${specialties.join(' أو ')}.',
      matchPercentage: percentage,
    );
  }

  static String _normalizeArabic(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[إأآا]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '')
        .replaceAll(RegExp(r'[^\u0600-\u06FFa-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}

class SymptomKeywordAnalysisResult {
  final SymptomKeywordRule rule;
  final int score;
  final List<String> selectedSymptoms;
  final DateTime createdAt;

  SymptomKeywordAnalysisResult({
    required this.rule,
    required this.score,
    required this.selectedSymptoms,
    required this.createdAt,
  });

  SpecialtyRecommendation get primarySpecialty => rule.toSpecialtyRecommendation(score);

  Map<String, dynamic> toFirestore() {
    return {
      'ruleId': rule.id,
      'organ': rule.organ,
      'specialties': rule.specialties,
      'selectedSymptoms': selectedSymptoms,
      'patientMessage': rule.patientMessage,
      'score': score,
      'createdAt': createdAt,
    };
  }
}
