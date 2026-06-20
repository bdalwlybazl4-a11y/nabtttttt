import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digl/features/medical_profile/models/doctor_recommendation_model.dart';
import 'package:digl/features/medical_profile/services/advanced_diagnosis_service.dart';

/// 👨‍⚕️ خدمة اختيار الطبيب المناسب بناءً على احتياجات المريض.
class DoctorMatchingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🎯 الحصول على أفضل الأطباء المناسبين للحالة.
  static Future<List<DoctorRecommendation>> findMatchingDoctors({
    required List<SpecialtyRecommendation> recommendedSpecialties,
    required List<String> symptoms,
    int returnCount = 3,
  }) async {
    try {
      if (recommendedSpecialties.isEmpty) return [];

      final matchedDoctors = <String, DoctorRecommendation>{};
      for (final specialty in recommendedSpecialties) {
        final doctors = await _searchDoctorsBySpecialty(specialty.name, symptoms);
        for (final doctor in doctors) {
          final existing = matchedDoctors[doctor.doctorId];
          if (existing == null || doctor.matchPercentage > existing.matchPercentage) {
            matchedDoctors[doctor.doctorId] = doctor;
          }
        }
      }

      final sortedDoctors = matchedDoctors.values.toList()
        ..sort((a, b) {
          final comparison = b.matchPercentage.compareTo(a.matchPercentage);
          if (comparison != 0) return comparison;
          return b.overallScore.compareTo(a.overallScore);
        });

      if (sortedDoctors.isNotEmpty) return sortedDoctors.take(returnCount).toList();

      final fallbackDoctors = await getAllVerifiedDoctors();
      fallbackDoctors.sort((a, b) => b.overallScore.compareTo(a.overallScore));
      return fallbackDoctors.take(returnCount).toList();
    } catch (e) {
      print('❌ خطأ في البحث عن الأطباء: $e');
      rethrow;
    }
  }

  /// 🔎 البحث المرن عن الأطباء حسب التخصص، مع دعم أسماء تخصصات متعددة مثل صدرية/رئة.
  static Future<List<DoctorRecommendation>> _searchDoctorsBySpecialty(
    String specialty,
    List<String> symptoms,
  ) async {
    try {
      final normalizedWanted = _normalizeSpecialty(specialty);
      final aliases = _specialtyAliases(normalizedWanted);
      final querySnapshot = await _firestore
          .collection('users')
          .where('accountType', isEqualTo: 'doctor')
          .where('isVerified', isEqualTo: true)
          .get();

      final doctors = <DoctorRecommendation>[];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final specialtyFields = [
          data['specialty'],
          data['specialtyName'],
          ...(data['specialties'] is List ? data['specialties'] as List : const []),
        ].whereType<Object>().map((value) => value.toString()).toList();

        final hasMatch = specialtyFields.any((field) {
          final normalizedField = _normalizeSpecialty(field);
          return aliases.any((alias) => normalizedField.contains(alias) || alias.contains(normalizedField));
        });
        if (!hasMatch) continue;

        final doctorSpecialty = (data['specialtyName'] ?? data['specialty'] ?? specialty).toString();
        final matchPercentage = _calculateMatchPercentage(
          specialty,
          symptoms,
          doctorSpecialty,
          isOnline: data['isOnline'] ?? false,
          isAvailable: data['isAvailable'] ?? false,
          rating: (data['rating'] as num?)?.toDouble() ?? 0,
          yearsOfExperience: int.tryParse((data['yearsOfExperience'] ?? data['experienceYears'] ?? '0').toString()) ?? 0,
        );

        doctors.add(DoctorRecommendation.fromFirestore(
          doc,
          matchPercentage: matchPercentage,
          reasons: _generateRecommendationReasons(
            specialty,
            matchPercentage,
            data['isOnline'] ?? false,
            data['isAvailable'] ?? false,
          ),
        ));
      }

      doctors.sort((a, b) => b.overallScore.compareTo(a.overallScore));
      return doctors;
    } catch (e) {
      print('⚠️ خطأ في البحث عن الأطباء حسب التخصص: $e');
      return [];
    }
  }

  static int _calculateMatchPercentage(
    String requiredSpecialty,
    List<String> symptoms,
    String doctorSpecialty, {
    required bool isOnline,
    required bool isAvailable,
    required double rating,
    required int yearsOfExperience,
  }) {
    var matchScore = 0;
    final aliases = _specialtyAliases(_normalizeSpecialty(requiredSpecialty));
    final normalizedDoctor = _normalizeSpecialty(doctorSpecialty);

    if (aliases.any((alias) => normalizedDoctor.contains(alias) || alias.contains(normalizedDoctor))) {
      matchScore += 55;
    }
    if (isAvailable) matchScore += 12;
    if (isOnline) matchScore += 8;
    matchScore += (rating.clamp(0, 5) * 3).round();
    matchScore += yearsOfExperience.clamp(0, 20) ~/ 2;
    if (symptoms.length >= 2) matchScore += 5;

    return matchScore.clamp(45, 100).toInt();
  }

  static List<String> _generateRecommendationReasons(
    String specialty,
    int matchPercentage,
    bool isOnline,
    bool isAvailable,
  ) {
    final reasons = <String>['متخصص في $specialty'];
    if (isAvailable) reasons.add('متاح الآن للاستشارة');
    if (isOnline) reasons.add('متصل الآن');
    if (matchPercentage >= 85) {
      reasons.add('أفضل تطابق مع الأعراض المختارة');
    } else if (matchPercentage >= 70) {
      reasons.add('تطابق جيد مع احتياجاتك');
    }
    return reasons;
  }

  static Future<DoctorRecommendation?> getDoctorDetails(String doctorId) async {
    try {
      final doc = await _firestore.collection('users').doc(doctorId).get();
      if (!doc.exists || doc['accountType'] != 'doctor') return null;
      return DoctorRecommendation.fromFirestore(doc, matchPercentage: 100, reasons: ['الملف الشامل']);
    } catch (e) {
      print('❌ خطأ في جلب تفاصيل الطبيب: $e');
      return null;
    }
  }

  static Future<List<DoctorRecommendation>> getAllVerifiedDoctors() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('accountType', isEqualTo: 'doctor')
          .where('isVerified', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => DoctorRecommendation.fromFirestore(doc, matchPercentage: 50, reasons: ['طبيب متحقق']))
          .toList();
    } catch (e) {
      print('❌ خطأ في جلب الأطباء: $e');
      return [];
    }
  }

  static Future<void> saveDoctorRecommendation(
    String patientId,
    List<DoctorRecommendation> recommendations,
  ) async {
    try {
      await _firestore.collection('patients').doc(patientId).collection('doctor_recommendations').add({
        'recommendations': recommendations.map((d) => d.toFirestore()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ خطأ في حفظ التوصيات: $e');
    }
  }

  static List<String> _specialtyAliases(String specialty) {
    const aliases = {
      'صدريه': ['صدريه', 'رئه', 'تنفسي', 'امراض الصدر', 'صدر'],
      'رئه': ['صدريه', 'رئه', 'تنفسي', 'امراض الصدر', 'صدر'],
      'قلب': ['قلب', 'القلب والاوعيه الدمويه', 'اوعيه دمويه'],
      'جلديه': ['جلديه', 'جلد', 'حساسيه'],
      'عيون': ['عيون', 'عين', 'رمد', 'بصريات'],
    };
    return aliases[specialty] ?? [specialty];
  }

  static String _normalizeSpecialty(String value) {
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
