import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج يمثل الملف الصحي للمريض
class HealthProfile {
  final String id;
  final String patientId;
  final int age;
  final String gender; // male, female
  final bool hasChronicDisease;
  final String? chronicDiseaseDetails;
  final String symptoms;
  final String? illnessDuration;
  final String symptomStartDate;
  final int painLevel; // 1-10
  final DateTime createdAt;
  final DateTime updatedAt;

  HealthProfile({
    required this.id,
    required this.patientId,
    required this.age,
    required this.gender,
    required this.hasChronicDisease,
    this.chronicDiseaseDetails,
    required this.symptoms,
    this.illnessDuration,
    required this.symptomStartDate,
    required this.painLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  /// تحويل البيانات من Firestore إلى النموذج
  factory HealthProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HealthProfile(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? 'male',
      hasChronicDisease: data['hasChronicDisease'] ?? false,
      chronicDiseaseDetails: data['chronicDiseaseDetails'],
      symptoms: data['symptoms'] ?? '',
      illnessDuration: data['illnessDuration'],
      symptomStartDate: data['symptomStartDate'] ?? '',
      painLevel: data['painLevel'] ?? 5,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// تحويل النموذج إلى خريطة للحفظ في Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'age': age,
      'gender': gender,
      'hasChronicDisease': hasChronicDisease,
      'chronicDiseaseDetails': chronicDiseaseDetails,
      'symptoms': symptoms,
      'illnessDuration': illnessDuration,
      'symptomStartDate': symptomStartDate,
      'painLevel': painLevel,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// نسخ النموذج مع تعديل بعض الحقول
  HealthProfile copyWith({
    String? id,
    String? patientId,
    int? age,
    String? gender,
    bool? hasChronicDisease,
    String? chronicDiseaseDetails,
    String? symptoms,
    String? illnessDuration,
    String? symptomStartDate,
    int? painLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthProfile(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      hasChronicDisease: hasChronicDisease ?? this.hasChronicDisease,
      chronicDiseaseDetails: chronicDiseaseDetails ?? this.chronicDiseaseDetails,
      symptoms: symptoms ?? this.symptoms,
      illnessDuration: illnessDuration ?? this.illnessDuration,
      symptomStartDate: symptomStartDate ?? this.symptomStartDate,
      painLevel: painLevel ?? this.painLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// نموذج للتشخيص المبدئي
class DiagnosisResult {
  final String diagnosisType; // simple, moderate, serious
  final String title;
  final String description;
  final List<String> immediateActions;
  final List<String> suggestedSpecialties;
  final String severity; // low, medium, high
  final DateTime createdAt;

  DiagnosisResult({
    required this.diagnosisType,
    required this.title,
    required this.description,
    required this.immediateActions,
    required this.suggestedSpecialties,
    required this.severity,
    required this.createdAt,
  });

  /// تحويل البيانات من Firestore إلى النموذج
  factory DiagnosisResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiagnosisResult(
      diagnosisType: data['diagnosisType'] ?? 'simple',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      immediateActions: List<String>.from(data['immediateActions'] ?? []),
      suggestedSpecialties: List<String>.from(data['suggestedSpecialties'] ?? []),
      severity: data['severity'] ?? 'low',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// تحويل النموذج إلى خريطة للحفظ في Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'diagnosisType': diagnosisType,
      'title': title,
      'description': description,
      'immediateActions': immediateActions,
      'suggestedSpecialties': suggestedSpecialties,
      'severity': severity,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
