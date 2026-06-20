import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج لتمثيل أعراض المريض
class PatientSymptoms {
  final String id;
  final String patientId;
  final String mainSymptom; // العرض الرئيسي
  final String symptomStartDate; // منذ متى بدأت الأعراض
  final bool hasPain; // هل يوجد ألم
  final String? painLocation; // موقع الألم إن وجد
  final bool hasFeverOrTiredness; // هل يعاني من حمى أو تعب
  final List<String> currentMedications; // الأدوية الحالية
  final DateTime createdAt;
  final DateTime updatedAt;

  PatientSymptoms({
    required this.id,
    required this.patientId,
    required this.mainSymptom,
    required this.symptomStartDate,
    required this.hasPain,
    this.painLocation,
    required this.hasFeverOrTiredness,
    required this.currentMedications,
    required this.createdAt,
    required this.updatedAt,
  });

  /// تحويل البيانات من Firestore إلى النموذج
  factory PatientSymptoms.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PatientSymptoms(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      mainSymptom: data['mainSymptom'] ?? '',
      symptomStartDate: data['symptomStartDate'] ?? '',
      hasPain: data['hasPain'] ?? false,
      painLocation: data['painLocation'],
      hasFeverOrTiredness: data['hasFeverOrTiredness'] ?? false,
      currentMedications: List<String>.from(data['currentMedications'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// تحويل النموذج إلى خريطة للحفظ في Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'mainSymptom': mainSymptom,
      'symptomStartDate': symptomStartDate,
      'hasPain': hasPain,
      'painLocation': painLocation,
      'hasFeverOrTiredness': hasFeverOrTiredness,
      'currentMedications': currentMedications,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// نسخ النموذج مع تعديل بعض الحقول
  PatientSymptoms copyWith({
    String? id,
    String? patientId,
    String? mainSymptom,
    String? symptomStartDate,
    bool? hasPain,
    String? painLocation,
    bool? hasFeverOrTiredness,
    List<String>? currentMedications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatientSymptoms(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      mainSymptom: mainSymptom ?? this.mainSymptom,
      symptomStartDate: symptomStartDate ?? this.symptomStartDate,
      hasPain: hasPain ?? this.hasPain,
      painLocation: painLocation ?? this.painLocation,
      hasFeverOrTiredness: hasFeverOrTiredness ?? this.hasFeverOrTiredness,
      currentMedications: currentMedications ?? this.currentMedications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
