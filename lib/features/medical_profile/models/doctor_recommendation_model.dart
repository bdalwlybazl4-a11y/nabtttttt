import 'package:cloud_firestore/cloud_firestore.dart';

/// 👨‍⚕️ نموذج للطبيب الموصى به بناءً على حالة المريض
class DoctorRecommendation {
  final String doctorId;
  final String fullName;
  final String specialty;
  final String specialtyName;
  final double rating;
  final int consultationCount;
  final bool isAvailable;
  final bool isOnline;
  final String? photoURL;
  final String? licenseNumber;
  final int yearsOfExperience;
  final int matchPercentage; // نسبة التطابق مع احتياجات المريض
  final List<String> reasonsForRecommendation; // أسباب التوصية

  DoctorRecommendation({
    required this.doctorId,
    required this.fullName,
    required this.specialty,
    required this.specialtyName,
    required this.rating,
    required this.consultationCount,
    required this.isAvailable,
    required this.isOnline,
    this.photoURL,
    this.licenseNumber,
    this.yearsOfExperience = 0,
    required this.matchPercentage,
    required this.reasonsForRecommendation,
  });

  /// تحويل البيانات من Firestore إلى النموذج
  factory DoctorRecommendation.fromFirestore(
    DocumentSnapshot doc, {
    required int matchPercentage,
    required List<String> reasons,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    return DoctorRecommendation(
      doctorId: doc.id,
      fullName: data['fullName'] ?? 'دكتور',
      specialty: data['specialty'] ?? '',
      specialtyName: data['specialtyName'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      consultationCount: data['consultationCount'] ?? 0,
      isAvailable: data['isAvailable'] ?? false,
      isOnline: data['isOnline'] ?? false,
      photoURL: data['photoURL'],
      licenseNumber: data['licenseNumber'],
      yearsOfExperience: int.tryParse((data['yearsOfExperience'] ?? data['experienceYears'] ?? '0').toString()) ?? 0,
      matchPercentage: matchPercentage,
      reasonsForRecommendation: reasons,
    );
  }

  /// تحويل النموذج إلى خريطة للحفظ في Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'doctorId': doctorId,
      'fullName': fullName,
      'specialty': specialty,
      'specialtyName': specialtyName,
      'rating': rating,
      'consultationCount': consultationCount,
      'isAvailable': isAvailable,
      'isOnline': isOnline,
      'photoURL': photoURL,
      'licenseNumber': licenseNumber,
      'yearsOfExperience': yearsOfExperience,
      'matchPercentage': matchPercentage,
      'reasonsForRecommendation': reasonsForRecommendation,
    };
  }

  /// حساب درجة التقييم النهائية بناءً على الخبرة والتقييم
  double get overallScore {
    // 60% التقييم + 40% عدد الاستشارات (معايرة)
    final consultationScore = (consultationCount / 100).clamp(0, 1) * 5;
    final experienceScore = (yearsOfExperience / 15).clamp(0, 1) * 5;
    return (rating * 0.55) + (consultationScore * 0.25) + (experienceScore * 0.20);
  }

  /// الحصول على نصاً وصفياً عن درجة التقييم
  String get ratingText {
    if (rating >= 4.5) return 'متميز جداً';
    if (rating >= 4.0) return 'ممتاز';
    if (rating >= 3.5) return 'جيد جداً';
    if (rating >= 3.0) return 'جيد';
    return 'مقبول';
  }
}
