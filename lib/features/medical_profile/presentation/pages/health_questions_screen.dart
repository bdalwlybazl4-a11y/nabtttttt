import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:digl/features/medical_profile/models/health_profile_model.dart';
import 'package:digl/features/medical_profile/services/diagnosis_service.dart';
import 'package:digl/features/medical_profile/services/advanced_diagnosis_service.dart';
import 'package:digl/features/medical_profile/presentation/pages/diagnosis_result_screen.dart';
import 'package:digl/features/medical_profile/presentation/pages/medical_analysis_result_screen.dart';
import 'package:digl/core/config/theme.dart';

class HealthQuestionsScreen extends StatefulWidget {
  const HealthQuestionsScreen({super.key});

  @override
  State<HealthQuestionsScreen> createState() => _HealthQuestionsScreenState();
}

class _HealthQuestionsScreenState extends State<HealthQuestionsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _currentStep = 0;
  static const int _totalSteps = 7;
  static const int _lastStepIndex = _totalSteps - 1;

  // متغيرات الأسئلة
  late int _age;
  String _gender = 'ذكر';
  bool _hasChronicDisease = false;
  String _chronicDiseaseDetails = '';
  String _symptoms = '';
  String _illnessDuration = '';
  DateTime? _symptomStartDate;
  int _painLevel = 5;

  final List<String> _genderOptions = ['ذكر', 'أنثى'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ خلفية بتدرج طبي مريح
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryBlue.withOpacity(0.05),
              AppTheme.positiveGreen.withOpacity(0.05),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'جاري تحليل بيانات صحتك...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              )
            : SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // ✅ رأس مخصص يستبدل AppBar
                      _buildHeader(),

                      // ✅ شريط التقدم المحسّن
                      _buildAdvancedProgressBar(),

                      // ✅ محتوى الأسئلة
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ✅ بطاقة السؤال
                              _buildQuestionCard(),

                              const SizedBox(height: 32),

                              // ✅ أزرار التنقل
                              _buildNavigationButtons(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ✅ رأس مخصص بتصميم حديث
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, Color(0xFF2563EB)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/home',
                  (route) => false,
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withOpacity(0.28)),
                ),
              ),
              icon: const Icon(Icons.home_rounded, size: 20),
              label: const Text(
                'الرجوع للرئيسية',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'بناء ملفك الصحي',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ساعدنا بملء معلوماتك لتقديم استشارات صحية أفضل',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ شريط التقدم المحسّن
  Widget _buildAdvancedProgressBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // شريط التقدم البصري
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // الخطوات المرقمة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;

              return Column(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? AppTheme.primaryBlue
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isCurrent ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStepTitle(index),
                    style: TextStyle(
                      fontSize: 10,
                      color: isCurrent ? AppTheme.primaryBlue : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ✅ بطاقة السؤال
  Widget _buildQuestionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ أيقونة السؤال
            Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.1),
                      AppTheme.positiveGreen.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getQuestionIcon(),
                  size: 40,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildCurrentQuestion(),
          ],
        ),
      ),
    );
  }

  // ✅ الحصول على عنوان الخطوة
  String _getStepTitle(int index) {
    const titles = [
      'العمر',
      'الجنس',
      'مرض مزمن',
      'الأعراض',
      'مدة المرض',
      'التاريخ',
      'الألم',
    ];
    return index < titles.length ? titles[index] : '';
  }

  // ✅ الحصول على أيقونة السؤال
  IconData _getQuestionIcon() {
    const icons = [
      Icons.cake,
      Icons.people,
      Icons.health_and_safety,
      Icons.sick,
      Icons.timelapse,
      Icons.calendar_today,
      Icons.favorite,
    ];
    return icons[_currentStep];
  }

  Widget _buildCurrentQuestion() {
    switch (_currentStep) {
      case 0:
        return _buildAgeQuestion();
      case 1:
        return _buildGenderQuestion();
      case 2:
        return _buildChronicDiseaseQuestion();
      case 3:
        return _buildSymptomsQuestion();
      case 4:
        return _buildIllnessDurationQuestion();
      case 5:
        return _buildSymptomStartDateQuestion();
      case 6:
        return _buildPainLevelQuestion();
      default:
        return const SizedBox();
    }
  }

  Widget _buildAgeQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ما عمرك؟',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'هذا يساعدنا على تقديم استشارات صحية أفضل',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          cursorColor: AppTheme.primaryBlue,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
            letterSpacing: 0.4,
          ),
          decoration: InputDecoration(
            labelText: 'العمر بالسنوات',
            hintText: 'أدخل عمرك',
            helperText: 'مثال: 30',
            suffixText: 'سنة',
            labelStyle: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w700,
            ),
            hintStyle: const TextStyle(
              fontSize: 18,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: Icon(
              Icons.cake,
              color: AppTheme.primaryBlue,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'الرجاء إدخال عمرك';
            }
            final age = int.tryParse(value);
            if (age == null || age < 1 || age > 150) {
              return 'الرجاء إدخال عمر صحيح (1-150)';
            }
            return null;
          },
          onSaved: (value) => _age = int.parse(value!),
        ),
      ],
    );
  }

  Widget _buildGenderQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. ما جنسك؟',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: _gender,
            isExpanded: true,
            underline: const SizedBox(),
            items: _genderOptions.map((gender) {
              return DropdownMenuItem(
                value: gender,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(gender),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _gender = value ?? 'ذكر');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChronicDiseaseQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3. هل تعاني من مرض مزمن؟',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _hasChronicDisease = true),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _hasChronicDisease
                          ? const Color(0xFF3A86FF)
                          : Colors.grey,
                      width: _hasChronicDisease ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: _hasChronicDisease
                        ? const Color(0xFF3A86FF).withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: const Text(
                    'نعم',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _hasChronicDisease = false),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: !_hasChronicDisease
                          ? const Color(0xFF3A86FF)
                          : Colors.grey,
                      width: !_hasChronicDisease ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: !_hasChronicDisease
                        ? const Color(0xFF3A86FF).withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: const Text(
                    'لا',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_hasChronicDisease) ...[
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _chronicDiseaseDetails,
            decoration: InputDecoration(
              hintText: 'اذكر نوع المرض المزمن',
              prefixIcon: const Icon(Icons.health_and_safety),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) => _chronicDiseaseDetails = value,
          ),
        ],
      ],
    );
  }

  Widget _buildSymptomsQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '4. ما الأعراض الحالية؟',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _symptoms,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'صف الأعراض التي تشعر بها (مثل: سعال، حمى، ألم في الرأس)',
            prefixIcon: const Icon(Icons.format_align_left),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'الرجاء وصف الأعراض';
            }
            return null;
          },
          onChanged: (value) => _symptoms = value,
        ),
      ],
    );
  }

  Widget _buildSymptomStartDateQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '6. منذ متى بدأت الأعراض؟',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF3A86FF)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _symptomStartDate == null
                        ? 'اختر التاريخ'
                        : DateFormat('yyyy-MM-dd', 'ar_SA')
                            .format(_symptomStartDate!),
                    style: TextStyle(
                      fontSize: 16,
                      color: _symptomStartDate == null
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIllnessDurationQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '5. كم مدة المرض الذي تعاني منه؟',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'اكتب المدة بشكل واضح مثل: يومين، أسبوع، شهر، أو أكثر',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _illnessDuration,
          textInputAction: TextInputAction.done,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            labelText: 'مدة المرض',
            hintText: 'مثال: 3 أيام / أسبوعين / شهر',
            prefixIcon: const Icon(Icons.timelapse),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'الرجاء إدخال مدة المرض';
            }
            return null;
          },
          onChanged: (value) => _illnessDuration = value.trim(),
          onSaved: (value) => _illnessDuration = value?.trim() ?? '',
        ),
      ],
    );
  }

  Widget _buildPainLevelQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '7. درجة الألم أو التعب (1-10)',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('بدون ألم'),
                Text(
                  '$_painLevel',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3A86FF),
                  ),
                ),
                const Text('ألم شديد جداً'),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: _painLevel.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: _painLevel.toString(),
              activeColor: const Color(0xFF3A86FF),
              onChanged: (value) {
                setState(() => _painLevel = value.toInt());
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ✅ زر التالي/الإرسال
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryBlue, Color(0xFF2563EB)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _handleNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _currentStep == _lastStepIndex ? 'إرسال البيانات' : 'التالي',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ✅ زر الرجوع (إذا لم نكن في الخطوة الأولى)
        if (_currentStep > 0)
          OutlinedButton(
            onPressed: () => setState(() => _currentStep--),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: AppTheme.primaryBlue),
            ),
            child: const Text(
              'السابق',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  void _handleNext() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_currentStep < _lastStepIndex) {
      setState(() => _currentStep++);
    } else {
      _submitHealthProfile();
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() => _symptomStartDate = pickedDate);
    }
  }

  Future<void> _submitHealthProfile() async {
    if (_symptomStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار تاريخ بدء الأعراض')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('لم يتم العثور على المستخدم');

      // ✅ حفظ الملف الصحي الأساسي
      final healthProfile = HealthProfile(
        id: '',
        patientId: user.uid,
        age: _age,
        gender: _gender,
        hasChronicDisease: _hasChronicDisease,
        chronicDiseaseDetails: _hasChronicDisease ? _chronicDiseaseDetails : null,
        symptoms: _symptoms,
        illnessDuration: _illnessDuration,
        symptomStartDate: _symptomStartDate!.toIso8601String(),
        painLevel: _painLevel,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // ✅ حفظ في Firestore
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .collection('medical_profile')
          .add(healthProfile.toFirestore());

      print('✅ تم حفظ الملف الصحي الأساسي');

      // ✅ تحليل متقدم باستخدام AdvancedDiagnosisService
      print('🔍 جاري تحليل البيانات الطبية بشكل متقدم...');
      final analysisResult =
          await AdvancedDiagnosisService.analyzeHealthProfile(
        healthProfile,
      );

      print('✅ تم تحليل البيانات بنجاح');

      if (!mounted) return;

      // ✅ الانتقال إلى شاشة النتائج المتقدمة
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MedicalAnalysisResultScreen(
            analysisResult: analysisResult,
            patientName: user.displayName ?? 'المريض',
          ),
        ),
      );
    } catch (e) {
      print('❌ خطأ في معالجة الملف الصحي: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
