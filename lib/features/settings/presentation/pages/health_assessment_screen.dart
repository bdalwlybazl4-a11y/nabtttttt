import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:digl/core/config/medical_theme.dart';
import 'package:digl/core/config/theme_helper.dart';
import 'package:digl/features/appointments/presentation/pages/book_appointment_screen.dart';
import 'package:digl/features/consultations/presentation/pages/consultation_screen.dart';
import 'package:digl/features/medical_profile/models/doctor_recommendation_model.dart';
import 'package:digl/features/medical_profile/models/health_profile_model.dart';
import 'package:digl/features/medical_profile/presentation/pages/ai_symptom_questions_screen.dart';
import 'package:digl/features/medical_profile/services/advanced_diagnosis_service.dart';
import 'package:digl/features/medical_profile/services/doctor_matching_service.dart';
import 'package:digl/features/settings/models/symptom_keyword_analysis_model.dart';
import 'package:digl/features/settings/services/symptom_keyword_analysis_service.dart';

/// 🏥 صفحة تقييم الصحة الذكية.
/// تجمع بين التقييم الحالي وقواعد كلمات مفتاحية قابلة للتوسعة لتوجيه المريض للتخصص المناسب.
class HealthAssessmentScreen extends StatefulWidget {
  const HealthAssessmentScreen({Key? key}) : super(key: key);

  @override
  State<HealthAssessmentScreen> createState() => _HealthAssessmentScreenState();
}

class _HealthAssessmentScreenState extends State<HealthAssessmentScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _hasCompletedAssessment = false;
  late TabController _tabController;

  MedicalAnalysisResult? _lastAnalysisResult;
  SymptomKeywordAnalysisResult? _keywordAnalysisResult;
  List<DoctorRecommendation> _recommendedDoctors = [];
  final Set<String> _selectedSymptoms = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAssessmentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAssessmentData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final assessmentSnapshot = await _firestore
          .collection('patients')
          .doc(user.uid)
          .collection('health_assessments')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (assessmentSnapshot.docs.isNotEmpty) {
        final data = assessmentSnapshot.docs.first.data();
        final ruleId = data['ruleId']?.toString();
        final rule = SymptomKeywordAnalysisService.rules
            .where((item) => item.id == ruleId)
            .cast<SymptomKeywordRule?>()
            .firstWhere((item) => item != null, orElse: () => null);
        if (rule != null) {
          _keywordAnalysisResult = SymptomKeywordAnalysisResult(
            rule: rule,
            score: data['score'] ?? 0,
            selectedSymptoms: (data['selectedSymptoms'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
          _selectedSymptoms.addAll(_keywordAnalysisResult!.selectedSymptoms);
          _hasCompletedAssessment = true;
          _recommendedDoctors = await DoctorMatchingService.findMatchingDoctors(
            recommendedSpecialties: [_keywordAnalysisResult!.primarySpecialty],
            symptoms: _keywordAnalysisResult!.selectedSymptoms,
          );
        }
      }

      final analysisSnapshot = await _firestore
          .collection('patients')
          .doc(user.uid)
          .collection('medical_analysis')
          .orderBy('analysisDate', descending: true)
          .limit(1)
          .get();

      if (analysisSnapshot.docs.isNotEmpty && _keywordAnalysisResult == null) {
        final analysisData = analysisSnapshot.docs.first.data();
        final medicines = (analysisData['recommendedMedicines'] as List<dynamic>?)
                ?.map((m) => MedicineRecommendation(
                      name: m['name'] ?? '',
                      activeIngredient: m['activeIngredient'] ?? '',
                      dose: m['dose'] ?? '',
                      category: m['category'] ?? '',
                      sideEffects: (m['sideEffects'] as List<dynamic>?)?.cast<String>() ?? [],
                      warnings: (m['warnings'] as List<dynamic>?)?.cast<String>() ?? [],
                      matchPercentage: m['matchPercentage'] ?? 0,
                    ))
                .toList() ??
            [];

        final specialties = (analysisData['recommendedSpecialties'] as List<dynamic>?)
                ?.map((s) => SpecialtyRecommendation(
                      name: s['name'] ?? '',
                      description: s['description'] ?? '',
                      matchPercentage: s['matchPercentage'] ?? 0,
                    ))
                .toList() ??
            [];

        _lastAnalysisResult = MedicalAnalysisResult(
          severity: analysisData['severity'] ?? 'low',
          matchedSymptoms: (analysisData['matchedSymptoms'] as List<dynamic>?)?.cast<String>() ?? [],
          recommendedMedicines: medicines,
          recommendedSpecialties: specialties,
          immediateActions: (analysisData['immediateActions'] as List<dynamic>?)?.cast<String>() ?? [],
          analysisDate: (analysisData['analysisDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          detailedAnalysis: analysisData['detailedAnalysis'] ?? '',
          recommendedDoctors: [],
        );
        _hasCompletedAssessment = true;
        _recommendedDoctors = await DoctorMatchingService.findMatchingDoctors(
          recommendedSpecialties: _lastAnalysisResult!.recommendedSpecialties,
          symptoms: _lastAnalysisResult!.matchedSymptoms,
        );
      }
    } catch (e) {
      print('❌ خطأ في تحميل بيانات التقييم: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startNewAssessment() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const AiSymptomQuestionsScreen()),
    );
    if (result == true && mounted) {
      await _loadAssessmentData();
      ThemeHelper.showSuccessSnackBar(context, '✅ تم إكمال التقييم بنجاح');
      _tabController.animateTo(1);
    }
  }

  Future<void> _analyzeSelectedSymptoms() async {
    if (_selectedSymptoms.isEmpty) {
      ThemeHelper.showErrorSnackBar(context, 'اختر عرضاً واحداً على الأقل');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final result = SymptomKeywordAnalysisService.analyze(_selectedSymptoms.toList());
      if (result == null) {
        ThemeHelper.showErrorSnackBar(context, 'لم يتم العثور على تخصص مناسب، جرّب التقييم التفصيلي');
        return;
      }

      final doctors = await DoctorMatchingService.findMatchingDoctors(
        recommendedSpecialties: [result.primarySpecialty],
        symptoms: result.selectedSymptoms,
        returnCount: 5,
      );

      await SymptomKeywordAnalysisService.saveResult(patientId: user.uid, result: result);
      await DoctorMatchingService.saveDoctorRecommendation(user.uid, doctors);

      setState(() {
        _keywordAnalysisResult = result;
        _lastAnalysisResult = null;
        _recommendedDoctors = doctors;
        _hasCompletedAssessment = true;
      });

      if (mounted) {
        ThemeHelper.showSuccessSnackBar(context, '✅ تم تحليل الأعراض واقتراح الطبيب المناسب');
        _tabController.animateTo(1);
      }
    } catch (e) {
      print('❌ خطأ في تحليل الكلمات المفتاحية: $e');
      if (mounted) ThemeHelper.showErrorSnackBar(context, 'حدث خطأ في التحليل');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _analyzeSymptoms() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final symptomsSnapshot = await _firestore
          .collection('patients')
          .doc(user.uid)
          .collection('patient_symptoms')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (symptomsSnapshot.docs.isEmpty) {
        if (mounted) ThemeHelper.showErrorSnackBar(context, 'لا توجد بيانات أعراض محفوظة');
        return;
      }

      final symptomsData = symptomsSnapshot.docs.first.data();
      final mainSymptom = (symptomsData['mainSymptom'] ?? '').toString();
      final additionalSymptoms = (symptomsData['additionalSymptoms'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
      final symptomText = [mainSymptom, ...additionalSymptoms].where((value) => value.trim().isNotEmpty).join('، ');

      final userData = await _firestore.collection('users').doc(user.uid).get();
      final data = userData.data() ?? <String, dynamic>{};
      final healthProfile = HealthProfile(
        id: user.uid,
        patientId: user.uid,
        age: int.tryParse(data['age']?.toString() ?? '0') ?? 0,
        gender: data['gender'] ?? 'male',
        hasChronicDisease: (data['hasChronicDisease'] ?? false) || additionalSymptoms.isNotEmpty,
        chronicDiseaseDetails: data['chronicDiseaseDetails'] ?? symptomsData['chronicDetails'],
        symptoms: symptomText,
        symptomStartDate: symptomsData['symptomStartDate'] ?? '',
        painLevel: (symptomsData['painLevel'] as int?) ?? (symptomsData['severityScore'] as int?) ?? 7,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final analysisResult = await AdvancedDiagnosisService.analyzeHealthProfile(healthProfile);
      await AdvancedDiagnosisService.saveMedicalAnalysis(user.uid, analysisResult);
      final doctors = await DoctorMatchingService.findMatchingDoctors(
        recommendedSpecialties: analysisResult.recommendedSpecialties,
        symptoms: analysisResult.matchedSymptoms,
      );

      setState(() {
        _lastAnalysisResult = analysisResult;
        _keywordAnalysisResult = null;
        _recommendedDoctors = doctors.isNotEmpty ? doctors : analysisResult.recommendedDoctors;
        _hasCompletedAssessment = true;
      });

      if (mounted) {
        ThemeHelper.showSuccessSnackBar(context, '✅ تم التحليل بنجاح');
        _tabController.animateTo(1);
      }
    } catch (e) {
      print('❌ خطأ في التحليل: $e');
      if (mounted) ThemeHelper.showErrorSnackBar(context, 'حدث خطأ في التحليل');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقييم الصحة الذكي'),
        elevation: 0,
        backgroundColor: MedicalTheme.primaryMedicalBlue,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الأعراض', icon: Icon(Icons.health_and_safety_rounded)),
            Tab(text: 'النتائج', icon: Icon(Icons.assessment_rounded)),
            Tab(text: 'الأطباء', icon: Icon(Icons.person_4_rounded)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildStartTab(theme), _buildResultsTab(theme), _buildDoctorsTab(theme)],
            ),
    );
  }

  Widget _buildStartTab(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(constraints.maxWidth > 700 ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroCard(theme),
              const SizedBox(height: 18),
              _buildKeywordAssessmentCard(theme),
              const SizedBox(height: 18),
              _buildLegacyAssessmentActions(),
              const SizedBox(height: 18),
              _buildMedicalDisclaimer(theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: MedicalTheme.primaryMedicalBlue.withOpacity(0.22), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 34),
          SizedBox(height: 12),
          Text('تحليل ذكي للأعراض', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 8),
          Text('اختر الأعراض وسيقوم النظام بتحديد العضو المحتمل، التخصص المناسب، وأفضل الأطباء من قاعدة البيانات.', style: TextStyle(color: Colors.white, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildKeywordAssessmentCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: theme.dividerColor.withOpacity(0.12))),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _circleIcon(Icons.psychology_alt_rounded, MedicalTheme.primaryMedicalBlue),
                const SizedBox(width: 12),
                const Expanded(child: Text('اختر الأعراض أو منطقة الألم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SymptomKeywordAnalysisService.allSymptoms.map((symptom) {
                final selected = _selectedSymptoms.contains(symptom);
                return FilterChip(
                  selected: selected,
                  label: Text(symptom),
                  avatar: Icon(selected ? Icons.check_circle : Icons.add_circle_outline, size: 18),
                  selectedColor: MedicalTheme.primaryMedicalBlue.withOpacity(0.18),
                  checkmarkColor: MedicalTheme.primaryMedicalBlue,
                  onSelected: (value) => setState(() {
                    value ? _selectedSymptoms.add(symptom) : _selectedSymptoms.remove(symptom);
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _selectedSymptoms.isEmpty ? 0.55 : 1,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _selectedSymptoms.isEmpty ? null : _analyzeSelectedSymptoms,
                  icon: const Icon(Icons.travel_explore_rounded),
                  label: const Text('تحليل الأعراض واقتراح طبيب'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedicalTheme.primaryMedicalBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegacyAssessmentActions() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('التقييم التفصيلي السابق', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _startNewAssessment,
              icon: const Icon(Icons.quiz_rounded),
              label: Text(_hasCompletedAssessment ? 'إعادة الاختبار التفصيلي' : 'ابدأ التقييم التفصيلي'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700], foregroundColor: Colors.white),
            ),
            if (_hasCompletedAssessment) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _analyzeSymptoms,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة تحليل آخر أعراض محفوظة'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsTab(ThemeData theme) {
    if (!_hasCompletedAssessment || (_lastAnalysisResult == null && _keywordAnalysisResult == null)) {
      return _buildEmptyState(Icons.assessment_outlined, 'لا توجد نتائج بعد', 'اختر أعراضك من التبويب الأول لرؤية التحليل');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_keywordAnalysisResult != null) _buildKeywordResultCard(theme),
          if (_lastAnalysisResult != null) ...[
            _buildSeverityCard(),
            const SizedBox(height: 16),
            _buildSpecialtiesCard(_lastAnalysisResult!.recommendedSpecialties),
            const SizedBox(height: 16),
            _buildActionsCard(_lastAnalysisResult!.immediateActions),
          ],
        ],
      ),
    );
  }

  Widget _buildKeywordResultCard(ThemeData theme) {
    final result = _keywordAnalysisResult!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _circleIcon(result.rule.icon, result.rule.color),
                    const SizedBox(width: 12),
                    Expanded(child: Text(result.rule.patientMessage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 14),
                _infoTile(Icons.biotech_rounded, 'العضو أو المشكلة المحتملة', result.rule.organ),
                _infoTile(Icons.local_hospital_rounded, 'التخصص المقترح', result.rule.specialties.join(' أو ')),
                _infoTile(Icons.fact_check_rounded, 'الأعراض المطابقة', result.selectedSymptoms.join('، ')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSpecialtiesCard([result.primarySpecialty]),
        const SizedBox(height: 16),
        _buildMedicalDisclaimer(theme),
      ],
    );
  }


  Future<void> _openBookingForDoctor(DoctorRecommendation doctor) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookAppointmentScreen(
          initialDoctorName: doctor.fullName,
          initialSpecialtyName: doctor.specialtyName.isNotEmpty ? doctor.specialtyName : doctor.specialty,
        ),
      ),
    );
  }

  Future<void> _startConsultationWithDoctor(DoctorRecommendation doctor) async {
    final user = _auth.currentUser;
    if (user == null) {
      ThemeHelper.showErrorSnackBar(context, 'يرجى تسجيل الدخول أولاً');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userDataDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDataDoc.data() ?? <String, dynamic>{};
      final doctorDoc = await _firestore.collection('users').doc(doctor.doctorId).get();
      final doctorData = doctorDoc.data() ?? <String, dynamic>{};

      final existingConsultation = await _firestore
          .collection('consultations')
          .where('userId', isEqualTo: user.uid)
          .where('doctorId', isEqualTo: doctor.doctorId)
          .where('type', isEqualTo: 'instant')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      String consultationId;
      if (existingConsultation.docs.isNotEmpty) {
        consultationId = existingConsultation.docs.first.id;
        await _firestore.collection('consultations').doc(consultationId).update({
          'hasNewMessage': false,
          'newMessageFor': null,
          'unreadCount.${user.uid}': 0,
          'seenBy': FieldValue.arrayUnion([user.uid]),
        });
      } else {
        final consultationRef = await _firestore.collection('consultations').add({
          'type': 'instant',
          'doctorId': doctor.doctorId,
          'doctorName': doctor.fullName,
          'doctorImage': doctor.photoURL ?? doctorData['photoURL'] ?? doctorData['profileImageUrl'],
          'doctorFcmToken': doctorData['fcmToken'],
          'userId': user.uid,
          'userName': userData['fullName'] ?? (user.displayName ?? 'مستخدم'),
          'userImage': userData['profilePicture'] ?? userData['photoURL'] ?? user.photoURL,
          'specialty': doctor.specialtyName.isNotEmpty ? doctor.specialtyName : doctor.specialty,
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageTime': FieldValue.serverTimestamp(),
          'status': 'pending',
          'isActive': true,
          'seenBy': [user.uid],
          'hasNewMessage': false,
          'newMessageFor': null,
          'unreadCount': {
            user.uid: 0,
            doctor.doctorId: 0,
          },
        });
        consultationId = consultationRef.id;
      }

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConsultationScreen(
            consultationId: consultationId,
            doctorUid: doctor.doctorId,
            patientUid: user.uid,
            doctorName: doctor.fullName,
            patientName: userData['fullName'] ?? (user.displayName ?? 'مستخدم'),
            doctorImage: doctor.photoURL ?? doctorData['photoURL'] ?? doctorData['profileImageUrl'] ?? '',
            userImage: userData['profilePicture'] ?? userData['photoURL'] ?? user.photoURL ?? '',
            isDoctor: false,
          ),
        ),
      );
    } catch (e) {
      if (mounted) ThemeHelper.showErrorSnackBar(context, 'تعذر بدء الاستشارة: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDoctorsTab(ThemeData theme) {
    if (_recommendedDoctors.isEmpty) {
      return _buildEmptyState(Icons.person_search_rounded, 'لا توجد توصيات بعد', 'أكمل تحليل الأعراض لرؤية الأطباء المناسبين');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _recommendedDoctors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _buildDoctorCard(_recommendedDoctors[index], index + 1, theme),
    );
  }

  Widget _buildDoctorCard(DoctorRecommendation doctor, int rank, ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + (rank * 80)),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 18 * (1 - value)), child: child),
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: MedicalTheme.primaryMedicalBlue.withOpacity(0.12),
                    backgroundImage: doctor.photoURL != null && doctor.photoURL!.isNotEmpty ? NetworkImage(doctor.photoURL!) : null,
                    child: doctor.photoURL == null || doctor.photoURL!.isEmpty ? const Icon(Icons.person_rounded, size: 32) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doctor.fullName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(doctor.specialtyName.isNotEmpty ? doctor.specialtyName : doctor.specialty, style: TextStyle(color: theme.hintColor)),
                      ],
                    ),
                  ),
                  Chip(label: Text('#$rank'), backgroundColor: MedicalTheme.primaryMedicalBlue.withOpacity(0.12)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _metric(Icons.star_rounded, '${doctor.rating.toStringAsFixed(1)}', 'التقييم', Colors.amber)),
                  Expanded(child: _metric(Icons.work_history_rounded, '${doctor.yearsOfExperience}', 'سنوات الخبرة', Colors.teal)),
                  Expanded(child: _metric(Icons.verified_rounded, '${doctor.matchPercentage}%', 'التطابق', MedicalTheme.primaryMedicalBlue)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: doctor.reasonsForRecommendation.map((reason) => Chip(label: Text(reason), visualDensity: VisualDensity.compact)).toList(),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openBookingForDoctor(doctor),
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: const Text('حجز موعد'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _startConsultationWithDoctor(doctor),
                      icon: const Icon(Icons.chat_bubble_rounded),
                      label: const Text('بدء استشارة'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityCard() => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(padding: const EdgeInsets.all(16), child: _buildSeverityBadge(_lastAnalysisResult!.severity)),
      );

  Widget _buildSpecialtiesCard(List<SpecialtyRecommendation> specialties) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('التخصصات الموصى بها', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...specialties.map((s) => _infoTile(Icons.star_rounded, s.name, s.description)),
            ],
          ),
        ),
      );

  Widget _buildActionsCard(List<String> actions) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('الإجراءات الموصى بها', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...actions.map((a) => _infoTile(Icons.check_circle_rounded, 'إجراء', a)),
            ],
          ),
        ),
      );

  Widget _buildSeverityBadge(String severity) {
    final (color, icon, label) = switch (severity) {
      'high' => (MedicalTheme.dangerRed, Icons.warning_rounded, 'حالة خطيرة - يُنصح بزيارة فورية'),
      'medium' => (MedicalTheme.pendingYellow, Icons.info_rounded, 'حالة متوسطة - يُنصح بزيارة خلال أيام'),
      _ => (Colors.green, Icons.check_circle_rounded, 'حالة بسيطة - المراقبة والعناية المنزلية'),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), border: Border.all(color: color), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [Icon(icon, color: color), const SizedBox(width: 12), Expanded(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)))]),
    );
  }

  Widget _buildMedicalDisclaimer(ThemeData theme) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: MedicalTheme.pendingYellow.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: MedicalTheme.pendingYellow.withOpacity(0.6))),
        child: const Row(children: [Icon(Icons.info_rounded, color: MedicalTheme.pendingYellow), SizedBox(width: 12), Expanded(child: Text('ملاحظة: هذا التقييم استرشادي فقط ولا يغني عن استشارة الطبيب المتخصص', style: TextStyle(fontSize: 12)))]),
      );

  Widget _emptyIcon(IconData icon) => Icon(icon, size: 68, color: Colors.grey[400]);

  Widget _buildEmptyState(IconData icon, String title, String subtitle) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [_emptyIcon(icon), const SizedBox(height: 16), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(subtitle, style: TextStyle(color: Colors.grey[600]))]),
      );

  Widget _circleIcon(IconData icon, Color color) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      );

  Widget _infoTile(IconData icon, String title, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20, color: MedicalTheme.primaryMedicalBlue), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text(value)]))]),
      );

  Widget _metric(IconData icon, String value, String label, Color color) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
        child: Column(children: [Icon(icon, color: color, size: 20), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)]),
      );
}
