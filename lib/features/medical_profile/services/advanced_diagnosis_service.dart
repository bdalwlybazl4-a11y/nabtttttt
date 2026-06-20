import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digl/features/medical_profile/models/health_profile_model.dart';
import 'package:digl/features/medical_profile/models/doctor_recommendation_model.dart';

/// 🏥 خدمة التشخيص الذكية والتوصيات الطبية المتقدمة
/// تقوم بتحليل بيانات المريض واقتراح الأدوية والأطباء المناسبين
class AdvancedDiagnosisService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Map<String, List<String>> _symptomSynonyms = {
    'صداع': ['صداع', 'صداع نصفي', 'شقيقة', 'الم راس', 'ألم رأس'],
    'حمى': ['حمى', 'حرارة', 'ارتفاع حرارة', 'سخونة'],
    'سعال': ['سعال', 'كحة', 'كحه'],
    'احتقان': ['احتقان', 'انسداد الانف', 'رشح'],
    'ضيق التنفس': ['ضيق التنفس', 'نهجان', 'صعوبة تنفس'],
    'المعدة': ['المعدة', 'معدة', 'غثيان', 'استفراغ', 'قيء'],
    'حساسية': ['حساسية', 'حكة', 'طفح', 'عطاس'],
    'ألم الصدر': ['ألم الصدر', 'وجع صدر', 'ضغط الصدر'],
  };

  /// ✅ نموذج لتمثيل توصية الدواء
  static const List<Map<String, dynamic>> medicinesDatabase = [
    // الزكام والإنفلونزا
    {
      'name': 'بنادول كولد',
      'activeIngredient': 'باراسيتامول + كافيين',
      'symptoms': ['الزكام', 'الإنفلونزا', 'حمى', 'صداع'],
      'severity': ['low', 'medium'],
      'dose': '500 ملغ كل 4-6 ساعات',
      'sideEffects': ['الدوخة', 'الأرق'],
      'warnings': ['لا تتجاوز 3000 ملغ يومياً'],
      'category': 'خافض حرارة ومسكن',
    },
    {
      'name': 'ديسبرين',
      'activeIngredient': 'ديكستروميثورفان + باراسيتامول',
      'symptoms': ['السعال', 'الإنفلونزا', 'الزكام'],
      'severity': ['low', 'medium'],
      'dose': 'ملعقة صغيرة كل 4 ساعات',
      'sideEffects': ['الدوخة', 'الرغبة في النعاس'],
      'warnings': ['لا تستخدم إذا كنت تتناول مثبطات MAO'],
      'category': 'دواء السعال',
    },

    // الحساسية والحكة
    {
      'name': 'كلاريتين',
      'activeIngredient': 'لوراتاديين',
      'symptoms': ['الحساسية', 'الحكة', 'الطفح الجلدي', 'العطاس'],
      'severity': ['low', 'medium'],
      'dose': 'حبة واحدة يومياً',
      'sideEffects': ['جفاف الفم', 'الإرهاق'],
      'warnings': ['قد تسبب النعاس في بعض الحالات'],
      'category': 'مضاد للحساسية',
    },
    {
      'name': 'أكوافين',
      'activeIngredient': 'سيتريزين',
      'symptoms': ['الحساسية', 'العطاس', 'حكة الأنف', 'الحكة الجلدية'],
      'severity': ['low', 'medium'],
      'dose': 'حبة واحدة يومياً (10 ملغ)',
      'sideEffects': ['الإرهاق', 'جفاف الفم'],
      'warnings': ['قد تؤثر على القدرة على القيادة'],
      'category': 'مضاد للحساسية',
    },

    // الجهاز الهضمي
    {
      'name': 'رينيول',
      'activeIngredient': 'رانيتيدين',
      'symptoms': ['حموضة', 'عسر الهضم', 'حرقة المعدة'],
      'severity': ['low', 'medium'],
      'dose': 'حبة واحدة بعد الطعام',
      'sideEffects': ['الإمساك', 'الإسهال'],
      'warnings': ['لا تستخدم مع مضادات الحموضة مباشرة'],
      'category': 'مضاد الحموضة',
    },
    {
      'name': 'ميوكوستا',
      'activeIngredient': 'سوكرالفات',
      'symptoms': ['الإسهال', 'اضطراب المعدة', 'الغثيان'],
      'severity': ['low', 'medium'],
      'dose': 'ملعقة واحدة 4 مرات يومياً',
      'sideEffects': ['الإمساك'],
      'warnings': ['تجنب الحليب والمضادات الحيوية معها'],
      'category': 'واقي المعدة',
    },

    // الألم والالتهاب
    {
      'name': 'ايبوبروفين',
      'activeIngredient': 'ايبوبروفين',
      'symptoms': ['آلام عضلية', 'التهاب المفاصل', 'الصداع', 'الحمى'],
      'severity': ['low', 'medium'],
      'dose': '400 ملغ كل 6 ساعات',
      'sideEffects': ['عسر الهضم', 'الدوخة'],
      'warnings': ['تجنب على معدة فارغة', 'قد يسبب القرحة'],
      'category': 'مسكن ومضاد التهاب',
    },
    {
      'name': 'أسبرين',
      'activeIngredient': 'حمض أسيتيل ساليسيليك',
      'symptoms': ['الصداع', 'آلام الأسنان', 'الحمى'],
      'severity': ['low'],
      'dose': 'حبة واحدة كل 4-6 ساعات',
      'sideEffects': ['الغثيان', 'حموضة المعدة'],
      'warnings': ['تجنب إذا كان لديك حساسية للأسبرين'],
      'category': 'مسكن',
    },

    // النوم والأرق
    {
      'name': 'ميلاتونين',
      'activeIngredient': 'ميلاتونين',
      'symptoms': ['الأرق', 'قلة النوم', 'التعب'],
      'severity': ['low'],
      'dose': '1-3 ملغ قبل النوم بـ 30 دقيقة',
      'sideEffects': ['الصداع', 'الدوخة'],
      'warnings': ['قد لا يكون مناسباً للقيادة'],
      'category': 'منوم طبيعي',
    },
  ];

  /// ✅ قاعدة بيانات التخصصات الطبية المقترحة
  static const List<Map<String, dynamic>> specialtiesDatabase = [
    {
      'name': 'طب عام',
      'symptoms': ['الحمى', 'الإرهاق', 'الصداع العام'],
      'description': 'للأعراض العامة والفحوصات الروتينية',
    },
    {
      'name': 'أنف وأذن وحنجرة',
      'symptoms': ['الزكام', 'السعال', 'التهاب الحلق', 'احتقان الأنف'],
      'description': 'متخصص في أمراض الجهاز التنفسي العلوي',
    },
    {
      'name': 'جلدية',
      'symptoms': ['الطفح الجلدي', 'الحكة الجلدية', 'حب الشباب', 'الحساسية'],
      'description': 'متخصص في أمراض الجلد والحساسية',
    },
    {
      'name': 'طب الجهاز الهضمي',
      'symptoms': ['حموضة', 'عسر الهضم', 'الإسهال', 'الإمساك', 'آلام البطن'],
      'description': 'متخصص في أمراض المعدة والأمعاء',
    },
    {
      'name': 'طب الأعصاب',
      'symptoms': ['الصداع الحاد', 'الدوخة الشديدة', 'تنميل', 'شلل'],
      'description': 'متخصص في أمراض الأعصاب والدماغ',
    },
    {
      'name': 'القلب والأوعية الدموية',
      'symptoms': ['ألم الصدر', 'ضيق التنفس', 'السمنة'],
      'description': 'متخصص في أمراض القلب والدورة الدموية',
    },
  ];

  /// ✅ دالة تحليل البيانات الطبية الرئيسية
  /// تأخذ الملف الصحي وتُرجع التشخيص والتوصيات
  static Future<MedicalAnalysisResult> analyzeHealthProfile(
    HealthProfile profile,
  ) async {
    try {
      print('🔍 جاري تحليل الملف الصحي...');

      // 1️⃣ تحديد خطورة الحالة
      final severity = _calculateSeverity(profile);

      // 2️⃣ البحث عن الأعراض المطابقة
      final matchedSymptoms = _parseSymptoms(profile.symptoms);

      // 3️⃣ اقتراح الأدوية المناسبة
      final recommendedMedicines = _recommendMedicines(
        matchedSymptoms,
        severity,
      );

      // 4️⃣ اقتراح التخصصات الطبية
      final recommendedSpecialties = _recommendSpecialties(
        matchedSymptoms,
        severity,
      );
      final recommendedDoctors = await _recommendDoctors(
        specialties: recommendedSpecialties,
        severity: severity,
      );

      // 5️⃣ الإجراءات الفورية
      final immediateActions = _getImmediateActions(
        severity,
        matchedSymptoms,
        profile,
      );

      // 6️⃣ بناء النتيجة
      final result = MedicalAnalysisResult(
        severity: severity,
        matchedSymptoms: matchedSymptoms,
        recommendedMedicines: recommendedMedicines,
        recommendedSpecialties: recommendedSpecialties,
        immediateActions: immediateActions,
        recommendedDoctors: recommendedDoctors,
        analysisDate: DateTime.now(),
        detailedAnalysis: _buildDetailedAnalysis(
          profile,
          matchedSymptoms,
          severity,
        ),
      );

      print('✅ تم تحليل الملف الصحي بنجاح');
      return result;
    } catch (e) {
      print('❌ خطأ في تحليل الملف الصحي: $e');
      rethrow;
    }
  }

  /// ✅ حساب مستوى خطورة الحالة
  static String _calculateSeverity(HealthProfile profile) {
    int riskScore = 0;

    // زيادة النقاط بناءً على عمر المريض
    if (profile.age > 60) riskScore += 2;
    if (profile.age > 50) riskScore += 1;

    // زيادة النقاط بناءً على مستوى الألم
    if (profile.painLevel >= 8) riskScore += 3;
    if (profile.painLevel >= 6) riskScore += 2;
    if (profile.painLevel >= 4) riskScore += 1;

    // زيادة النقاط إذا كان لديه أمراض مزمنة
    if (profile.hasChronicDisease) riskScore += 2;

    // التصنيف النهائي
    if (riskScore >= 6) return 'high';
    if (riskScore >= 3) return 'medium';
    return 'low';
  }

  /// ✅ تحليل الأعراض وتقسيمها إلى كلمات مفتاحية
  static List<String> _parseSymptoms(String symptomsText) {
    final normalized = symptomsText
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ');
    final words = normalized.split(RegExp(r'[\s،]+')).where((word) => word.length > 2).toList();

    final normalizedSymptoms = <String>{};
    for (final entry in _symptomSynonyms.entries) {
      final hasMatch = entry.value.any((alias) => normalized.contains(alias.toLowerCase()));
      if (hasMatch) {
        normalizedSymptoms.add(entry.key.toLowerCase());
      }
    }

    normalizedSymptoms.addAll(words.where((word) => word.isNotEmpty));
    return normalizedSymptoms.toList();
  }

  /// ✅ اقتراح الأدوية المناسبة بناءً على الأعراض والخطورة
  static List<MedicineRecommendation> _recommendMedicines(
    List<String> symptoms,
    String severity,
  ) {
    final recommendations = <MedicineRecommendation>[];

    // البحث عن الأدوية المطابقة
    for (final medicine in medicinesDatabase) {
      final medicineSymptoms =
          (medicine['symptoms'] as List<dynamic>).cast<String>();
      final medicineSeverities =
          (medicine['severity'] as List<dynamic>).cast<String>();

      // حساب عدد الأعراض المتطابقة
      int matchCount = 0;
      for (final symptom in symptoms) {
        if (medicineSymptoms.any((ms) {
          final lowerMs = ms.toLowerCase();
          return lowerMs.contains(symptom) || symptom.contains(lowerMs);
        })) {
          matchCount++;
        }
      }

      // إذا كان هناك تطابق وكانت درجة الخطورة مناسبة
      if (matchCount > 0 && medicineSeverities.contains(severity)) {
        recommendations.add(
          MedicineRecommendation(
            name: medicine['name'] as String,
            activeIngredient: medicine['activeIngredient'] as String,
            dose: medicine['dose'] as String,
            category: medicine['category'] as String,
            sideEffects: (medicine['sideEffects'] as List<dynamic>)
                .cast<String>(),
            warnings: (medicine['warnings'] as List<dynamic>).cast<String>(),
            matchPercentage: (matchCount / symptoms.length.clamp(1, 10) * 100).toInt(),
          ),
        );
      }
    }

    // ترتيب الأدوية بناءً على نسبة التطابق
    recommendations.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));

    if (recommendations.isEmpty) return [];

    return recommendations.take(3).toList();
  }

  /// ✅ اقتراح التخصصات الطبية
  static List<SpecialtyRecommendation> _recommendSpecialties(
    List<String> symptoms,
    String severity,
  ) {
    final recommendations = <SpecialtyRecommendation>[];

    for (final specialty in specialtiesDatabase) {
      final specialtySymptoms =
          (specialty['symptoms'] as List<dynamic>).cast<String>();

      // حساب عدد الأعراض المتطابقة
      int matchCount = 0;
      for (final symptom in symptoms) {
        if (specialtySymptoms.any((ss) {
          final lowerSs = ss.toLowerCase();
          return lowerSs.contains(symptom) || symptom.contains(lowerSs);
        })) {
          matchCount++;
        }
      }

      if (matchCount > 0) {
        recommendations.add(
          SpecialtyRecommendation(
            name: specialty['name'] as String,
            description: specialty['description'] as String,
            matchPercentage: (matchCount / symptoms.length.clamp(1, 10) * 100).toInt(),
          ),
        );
      }
    }

    recommendations.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
    if (recommendations.isNotEmpty) return recommendations.take(2).toList();

    return [
      SpecialtyRecommendation(
        name: 'طب عام',
        description: 'بداية آمنة لتقييم الحالة وتحويلها للتخصص المناسب عند الحاجة',
        matchPercentage: 40,
      ),
    ];
  }

  static Future<List<DoctorRecommendation>> _recommendDoctors({
    required List<SpecialtyRecommendation> specialties,
    required String severity,
  }) async {
    if (specialties.isEmpty) return [];
    final specialtyNames = specialties.map((s) => s.name).toSet();
    final doctorsQuery = await _firestore
        .collection('users')
        .where('accountType', isEqualTo: 'doctor')
        .where('isVerified', isEqualTo: true)
        .get();

    final recommendations = <DoctorRecommendation>[];
    for (final doc in doctorsQuery.docs) {
      final data = doc.data();
      final doctorSpecialty = (data['specialtyName'] ?? data['specialty'] ?? '').toString();
      final specialtyMatched = specialtyNames.contains(doctorSpecialty);
      if (!specialtyMatched && specialties.first.name != 'طب عام') continue;
      final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
      final available = (data['isAvailable'] as bool?) ?? true;
      final online = (data['isOnline'] as bool?) ?? false;
      int matchScore = specialtyMatched ? 60 : 35;
      if (rating >= 4.5) matchScore += 25;
      if (online) matchScore += 15;
      if (available) matchScore += 10;
      if (severity == 'high' && online) matchScore += 10;
      matchScore = matchScore.clamp(0, 100);

      recommendations.add(
        DoctorRecommendation.fromFirestore(
          doc,
          matchPercentage: matchScore,
          reasons: [
            if (specialtyMatched) 'تخصص مناسب للحالة' else 'طبيب عام مناسب للتقييم الأولي',
            if (rating >= 4) 'تقييم مرتفع',
            if (available) 'متاح للحجز',
            if (online) 'متصل الآن',
          ],
        ),
      );
    }

    recommendations.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
    return recommendations.take(5).toList();
  }

  /// ✅ الحصول على الإجراءات الفورية
  static List<String> _getImmediateActions(
    String severity,
    List<String> symptoms,
    HealthProfile profile,
  ) {
    final actions = <String>[];

    // إجراءات عامة
    actions.add('الحصول على قسط كافٍ من الراحة');
    actions.add('شرب كمية كافية من الماء والسوائل');

    if (severity == 'high') {
      actions.add('⚠️ يُنصح بزيارة الطبيب في أقرب وقت');
      actions.add('تجنب النشاطات البدنية الشاقة');
      if (profile.painLevel >= 8) {
        actions.add('استخدم مسكنات الألم حسب التعليمات');
      }
    } else if (severity == 'medium') {
      actions.add('يُنصح بزيارة الطبيب خلال أيام قليلة');
      actions.add('راقب الأعراض وأبلغ الطبيب عن أي تفاقم');
    } else {
      actions.add('الاعتناء بنظافة شخصية جيدة');
      actions.add('اتبع نمط حياة صحي');
    }

    // إجراءات خاصة بناءً على الأعراض
    if (symptoms.any((s) => s.contains('حمى') || s.contains('درجة حرارة'))) {
      actions.add('راقب درجة حرارة جسمك بانتظام');
    }

    if (symptoms.any((s) => s.contains('سعال') || s.contains('التهاب حلق'))) {
      actions.add('تجنب المهيجات والدخان');
      actions.add('استنشق بخار ماء دافئ');
    }

    return actions;
  }

  /// ✅ بناء تحليل مفصل
  static String _buildDetailedAnalysis(
    HealthProfile profile,
    List<String> symptoms,
    String severity,
  ) {
    final StringBuffer analysis = StringBuffer();

    analysis.writeln('📋 تحليل مفصل للحالة الصحية');
    analysis.writeln('─' * 40);

    // معلومات المريض
    analysis.writeln('👤 معلومات المريض:');
    analysis.writeln('   • العمر: ${profile.age} سنة');
    analysis.writeln('   • الجنس: ${profile.gender == 'male' ? 'ذكر' : 'أنثى'}');
    analysis.writeln('   • مستوى الألم: ${profile.painLevel}/10');

    // الأمراض المزمنة
    if (profile.hasChronicDisease) {
      analysis.writeln('   • أمراض مزمنة: ${profile.chronicDiseaseDetails}');
    }

    // مدة الأعراض
    if ((profile.illnessDuration ?? '').trim().isNotEmpty) {
      analysis.writeln('   • مدة المرض حسب إدخال المريض: ${profile.illnessDuration}');
    }
    analysis.writeln('   • مدة الأعراض: ${profile.symptomStartDate}');

    // درجة الخطورة
    analysis.writeln('');
    analysis.writeln('⚠️ تقييم الخطورة:');
    final severityLabel = severity == 'high'
        ? 'عالية - يُنصح بزيارة فورية'
        : severity == 'medium'
        ? 'متوسطة - زيارة خلال أيام'
        : 'منخفضة - المراقبة والعناية المنزلية';
    analysis.writeln('   $severityLabel');

    // الأعراض المكتشفة
    analysis.writeln('');
    analysis.writeln('🔍 الأعراض المكتشفة:');
    for (int i = 0; i < symptoms.length && i < 5; i++) {
      analysis.writeln('   ${i + 1}. ${symptoms[i]}');
    }

    analysis.writeln('');
    analysis.writeln(
      '⚕️ تذكير مهم: هذا التحليل استرشادي فقط ولا يحل محل استشارة الطبيب المتخصص.',
    );

    return analysis.toString();
  }

  /// ✅ حفظ النتائج في Firestore
  static Future<void> saveMedicalAnalysis(
    String patientId,
    MedicalAnalysisResult result,
  ) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('medical_analysis')
          .add({
        'severity': result.severity,
        'matchedSymptoms': result.matchedSymptoms,
        'recommendedMedicines': result.recommendedMedicines
            .map((m) => {
          'name': m.name,
          'activeIngredient': m.activeIngredient,
          'dose': m.dose,
          'category': m.category,
          'matchPercentage': m.matchPercentage,
        })
            .toList(),
        'recommendedSpecialties': result.recommendedSpecialties
            .map((s) => {
          'name': s.name,
          'description': s.description,
          'matchPercentage': s.matchPercentage,
        })
            .toList(),
        'immediateActions': result.immediateActions,
        'recommendedDoctors': result.recommendedDoctors.map((d) => d.toFirestore()).toList(),
        'analysisDate': FieldValue.serverTimestamp(),
      });

      print('✅ تم حفظ نتائج التحليل بنجاح');
    } catch (e) {
      print('❌ خطأ في حفظ النتائج: $e');
      rethrow;
    }
  }
}

/// 📊 نموذج نتائج التحليل الطبي الشامل
class MedicalAnalysisResult {
  final String severity; // low, medium, high
  final List<String> matchedSymptoms;
  final List<MedicineRecommendation> recommendedMedicines;
  final List<SpecialtyRecommendation> recommendedSpecialties;
  final List<String> immediateActions;
  final List<DoctorRecommendation> recommendedDoctors;
  final DateTime analysisDate;
  final String detailedAnalysis;

  MedicalAnalysisResult({
    required this.severity,
    required this.matchedSymptoms,
    required this.recommendedMedicines,
    required this.recommendedSpecialties,
    required this.immediateActions,
    required this.recommendedDoctors,
    required this.analysisDate,
    required this.detailedAnalysis,
  });
}

/// 💊 نموذج توصية الدواء
class MedicineRecommendation {
  final String name;
  final String activeIngredient;
  final String dose;
  final String category;
  final List<String> sideEffects;
  final List<String> warnings;
  final int matchPercentage;

  MedicineRecommendation({
    required this.name,
    required this.activeIngredient,
    required this.dose,
    required this.category,
    required this.sideEffects,
    required this.warnings,
    required this.matchPercentage,
  });
}

/// 👨‍⚕️ نموذج توصية التخصص الطبي
class SpecialtyRecommendation {
  final String name;
  final String description;
  final int matchPercentage;

  SpecialtyRecommendation({
    required this.name,
    required this.description,
    required this.matchPercentage,
  });
}
