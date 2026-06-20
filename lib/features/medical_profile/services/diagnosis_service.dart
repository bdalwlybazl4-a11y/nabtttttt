import 'package:digl/features/medical_profile/models/health_profile_model.dart';

/// خدمة التشخيص المبدئي - تحلل إجابات المريض وتعطيه تشخيص مبدئي
class DiagnosisService {
  /// تحليل إجابات الأسئلة الصحية
  static DiagnosisResult analyzeSymptons({
    required int age,
    required String gender,
    required bool hasChronicDisease,
    required String chronicDiseaseDetails,
    required String symptoms,
    required String symptomStartDate,
    required int painLevel,
  }) {
    // حساب درجة الخطورة
    int severityScore = 0;
    List<String> suggestedSpecialties = [];

    // 1. عمر المريض
    if (age < 5 || age > 75) {
      severityScore += 2;
    }

    // 2. مستوى الألم
    if (painLevel >= 8) {
      severityScore += 3;
    } else if (painLevel >= 5) {
      severityScore += 2;
    }

    // 3. وجود مرض مزمن
    if (hasChronicDisease) {
      severityScore += 2;
      if (chronicDiseaseDetails != null && chronicDiseaseDetails.isNotEmpty) {
        severityScore += _analyzeChronicDisease(chronicDiseaseDetails);
      }
    }

    // 4. تحليل الأعراض
    severityScore += _analyzeSymptoms(symptoms, suggestedSpecialties);

    // 5. مدة الأعراض
    if (_isSymptomDurationLong(symptomStartDate)) {
      severityScore += 1;
    }

    return _generateDiagnosisResult(
      severityScore: severityScore,
      symptoms: symptoms,
      suggestedSpecialties: suggestedSpecialties,
      age: age,
      gender: gender,
      hasChronicDisease: hasChronicDisease,
    );
  }

  /// تحليل الأمراض المزمنة
  static int _analyzeChronicDisease(String disease) {
    final lowerDisease = disease.toLowerCase();

    // أمراض خطيرة
    if (lowerDisease.contains('قلب') ||
        lowerDisease.contains('سكري') ||
        lowerDisease.contains('ضغط دم') ||
        lowerDisease.contains('سرطان')) {
      return 3;
    }

    // أمراض متوسطة
    if (lowerDisease.contains('ربو') ||
        lowerDisease.contains('حساسية') ||
        lowerDisease.contains('التهاب')) {
      return 2;
    }

    return 1;
  }

  /// تحليل الأعراض
  static int _analyzeSymptoms(
      String symptoms, List<String> suggestedSpecialties) {
    int score = 0;
    final lowerSymptoms = symptoms.toLowerCase();

    // أعراض خطيرة جداً
    if (lowerSymptoms.contains('صعوبة تنفس') ||
        lowerSymptoms.contains('ألم في الصدر') ||
        lowerSymptoms.contains('فقدان الوعي') ||
        lowerSymptoms.contains('نزيف')) {
      score += 5;
      suggestedSpecialties.add('طبيب طوارئ');
      suggestedSpecialties.add('طبيب باطنة');
      return score;
    }

    // أعراض تنفسية
    if (lowerSymptoms.contains('سعال') ||
        lowerSymptoms.contains('البرد') ||
        lowerSymptoms.contains('احتقان') ||
        lowerSymptoms.contains('انفلونزا')) {
      score += 2;
      if (!suggestedSpecialties.contains('طبيب أنف وأذن وحلق')) {
        suggestedSpecialties.add('طبيب أنف وأذن وحلق');
      }
    }

    // أعراض معدية
    if (lowerSymptoms.contains('غثيان') ||
        lowerSymptoms.contains('قيء') ||
        lowerSymptoms.contains('إسهال') ||
        lowerSymptoms.contains('معدة')) {
      score += 2;
      if (!suggestedSpecialties.contains('طبيب الجهاز الهضمي')) {
        suggestedSpecialties.add('طبيب الجهاز الهضمي');
      }
    }

    // أعراض جلدية
    if (lowerSymptoms.contains('طفح') ||
        lowerSymptoms.contains('حكة') ||
        lowerSymptoms.contains('احمرار') ||
        lowerSymptoms.contains('جلد')) {
      score += 1;
      if (!suggestedSpecialties.contains('طبيب الجلدية')) {
        suggestedSpecialties.add('طبيب الجلدية');
      }
    }

    // أعراض قلبية
    if (lowerSymptoms.contains('خفقان') ||
        lowerSymptoms.contains('ضعف') ||
        lowerSymptoms.contains('دوخة')) {
      score += 3;
      if (!suggestedSpecialties.contains('طبيب القلب')) {
        suggestedSpecialties.add('طبيب القلب');
      }
    }

    // أعراض عامة
    if (lowerSymptoms.contains('حمى') ||
        lowerSymptoms.contains('ارتفاع الحرارة')) {
      score += 2;
      if (!suggestedSpecialties.contains('طبيب عام')) {
        suggestedSpecialties.add('طبيب عام');
      }
    }

    // إذا لم يتم اقتراح تخصص، اقترح طبيب عام
    if (suggestedSpecialties.isEmpty) {
      suggestedSpecialties.add('طبيب عام');
    }

    return score;
  }

  /// التحقق من مدة الأعراض
  static bool _isSymptomDurationLong(String symptomStartDate) {
    try {
      final startDate = DateTime.parse(symptomStartDate);
      final now = DateTime.now();
      final difference = now.difference(startDate).inDays;
      return difference > 7; // إذا استمرت أكثر من أسبوع
    } catch (e) {
      return false;
    }
  }

  /// توليد نتيجة التشخيص
  static DiagnosisResult _generateDiagnosisResult({
    required int severityScore,
    required String symptoms,
    required List<String> suggestedSpecialties,
    required int age,
    required String gender,
    required bool hasChronicDisease,
  }) {
    late String diagnosisType;
    late String title;
    late String description;
    late List<String> immediateActions;
    late String severity;

    if (severityScore >= 10) {
      // حالة خطيرة جداً
      diagnosisType = 'serious';
      severity = 'high';
      title = '⚠️ حالة تحتاج عناية فورية';
      description =
          'بناءً على الأعراض التي أدخلتها، قد تكون حالتك تحتاج إلى عناية طبية فورية. يرجى التوجه إلى الطوارئ أو استشارة طبيب متخصص بسرعة.';
      immediateActions = [
        '🏥 توجه فوراً إلى قسم الطوارئ',
        '📞 اتصل برقم الطوارئ إذا لم تستطع الذهاب',
        '⏸️ تجنب أي مجهود شاق',
        '💧 حافظ على رطوبة الجسم',
        '🚫 لا تتناول أدوية بدون وصفة طبية',
      ];
    } else if (severityScore >= 6) {
      // حالة متوسطة
      diagnosisType = 'moderate';
      severity = 'medium';
      title = '⚠️ حالة تحتاج متابعة طبية';
      description =
          'أعراضك تتطلب فحص طبي شامل. ننصح بزيارة عيادة طبية في أقرب وقت لتلقي التشخيص الدقيق والعلاج المناسب.';
      immediateActions = [
        '👨‍⚕️ حجز موعد مع الطبيب في أقرب وقت',
        '📋 جهز قائمة بجميع أعراضك',
        '💊 استشر الصيدلي قبل تناول أي أدوية',
        '😴 احصل على قسط كافٍ من الراحة',
        '🍎 حافظ على نظام غذائي صحي',
      ];
    } else {
      // حالة بسيطة
      diagnosisType = 'simple';
      severity = 'low';
      title = '✅ حالة بسيطة نسبياً';
      description =
          'الأعراض التي تواجهها تبدو بسيطة نسبياً. يمكنك البدء بالرعاية الذاتية والملاحظة. إذا استمرت الأعراض أكثر من أسبوع، استشر الطبيب.';
      immediateActions = [
        '☕ استرخ وتجنب الإجهاد',
        '💤 احصل على نوم كافٍ (7-8 ساعات)',
        '💧 اشرب الكثير من الماء والسوائل',
        '🌡️ راقب حرارتك إذا كانت لديك حمى',
        '📅 إذا استمرت الأعراض 7 أيام، استشر طبيب',
      ];
    }

    return DiagnosisResult(
      diagnosisType: diagnosisType,
      title: title,
      description: description,
      immediateActions: immediateActions,
      suggestedSpecialties: suggestedSpecialties,
      severity: severity,
      createdAt: DateTime.now(),
    );
  }
}
