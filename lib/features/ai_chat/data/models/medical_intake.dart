class MedicalIntake {
  final String problem;
  final String symptomStart;
  final int age;
  final String gender;
  final String duration;
  final String severity;

  const MedicalIntake({required this.problem, required this.symptomStart, required this.age, required this.gender, required this.duration, required this.severity});

  factory MedicalIntake.fromMap(Map<String, dynamic> map) {
    return MedicalIntake(
      problem: map['problem']?.toString() ?? '',
      symptomStart: map['symptomStart']?.toString() ?? '',
      age: int.tryParse(map['age']?.toString() ?? '') ?? 0,
      gender: map['gender']?.toString() ?? 'ذكر',
      duration: map['duration']?.toString() ?? '',
      severity: map['severity']?.toString() ?? 'متوسطة',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'problem': problem,
      'symptomStart': symptomStart,
      'age': age,
      'gender': gender,
      'duration': duration,
      'severity': severity,
    };
  }

  List<String> get symptoms => problem.split(RegExp(r'[،,\s]+')).where((e) => e.trim().isNotEmpty).toList();

  String toPrompt() => '''
المرض أو المشكلة: $problem
بداية الأعراض: $symptomStart
عمر المريض: $age
الجنس: $gender
المدة: $duration
شدة الحالة: $severity
''';
}
