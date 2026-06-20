import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digl/features/medical_profile/models/patient_symptoms_model.dart';
import 'package:digl/features/medical_profile/services/patient_symptoms_service.dart';
import 'package:digl/core/config/medical_theme.dart';
import 'package:digl/services/ai_questions_service.dart';

/// شاشة الأسئلة الذكية لتحديد الأعراض بعد إنشاء الحساب
class AiSymptomQuestionsScreen extends StatefulWidget {
  const AiSymptomQuestionsScreen({super.key});

  @override
  State<AiSymptomQuestionsScreen> createState() =>
      _AiSymptomQuestionsScreenState();
}

class _AiSymptomQuestionsScreenState extends State<AiSymptomQuestionsScreen> {
  late PageController _pageController;
  int _currentQuestion = 0;
  bool _isLoading = false;

  // متغيرات الإجابات
  String _mainSymptom = '';
  String _symptomStartDate = '';
  bool _hasPain = false;
  String _painLocation = '';
  bool _hasFeverOrTiredness = false;
  List<String> _currentMedications = [];
  String _medicationInput = '';

  // قائمة الأعراض الشائعة
  final List<String> _commonSymptoms = [
    'صداع',
    'حمى',
    'سعال',
    'احتقان أنف',
    'ألم في المعدة',
    'إسهال',
    'إمساك',
    'آلام في المفاصل',
    'تعب عام',
    'أرق',
  ];

  // قائمة مواقع الألم
  final List<String> _painLocations = [
    'الرأس',
    'الرقبة',
    'الكتف',
    'الظهر',
    'البطن',
    'الصدر',
    'الذراعين',
    'الساقين',
    'المفاصل',
  ];

  // قائمة فترات الأعراض
  final List<String> _symptomDurations = [
    'أقل من 24 ساعة',
    '1-3 أيام',
    '3-7 أيام',
    'أكثر من أسبوع',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// الانتقال إلى السؤال التالي
  Future<void> _goToNextQuestion() async {
    // التحقق من صحة الإجابة الحالية
    if (!_validateCurrentAnswer()) {
      _showErrorSnackBar('يرجى ملء جميع الحقول المطلوبة');
      return;
    }

    if (_currentQuestion < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      // إكمال الأسئلة وحفظ البيانات
      await _submitAnswers();
    }
  }

  /// التحقق من صحة الإجابة الحالية
  bool _validateCurrentAnswer() {
    switch (_currentQuestion) {
      case 0:
        return _mainSymptom.isNotEmpty;
      case 1:
        return _symptomStartDate.isNotEmpty;
      case 2:
        if (_hasPain) {
          return _painLocation.isNotEmpty;
        }
        return true;
      case 3:
        return true; // الحمى اختيارية
      case 4:
        return true; // الأدوية اختيارية
      default:
        return false;
    }
  }

  /// إرسال الإجابات وحفظها
  Future<void> _submitAnswers() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('لم يتم العثور على المستخدم');

      // إنشاء كائن الأعراض
      final symptoms = PatientSymptoms(
        id: '', // سيتم إنشاؤه في Firebase
        patientId: '', // سيتم إعادة تعيينه في الخدمة
        mainSymptom: _mainSymptom,
        symptomStartDate: _symptomStartDate,
        hasPain: _hasPain,
        painLocation: _painLocation.isNotEmpty ? _painLocation : null,
        hasFeverOrTiredness: _hasFeverOrTiredness,
        currentMedications: _currentMedications,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // حفظ الأعراض في Firebase
      await PatientSymptomsService.addPatientSymptoms(symptoms);

      // ✅ حفظ تاريخ ظهور أسئلة الذكاء الاصطناعي
      // سيحفظ: ai_test_completed=true + ai_test_last_shown=now
      // بحيث تظهر مرة أخرى بعد 10 أيام
      await AiQuestionsService.saveAiQuestionsCompletion();

      _showSuccessSnackBar('✅ تم حفظ البيانات بنجاح');

      // الانتقال إلى الشاشة الرئيسية بعد ثانية
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      print('❌ خطأ في حفظ البيانات: $e');
      _showErrorSnackBar('حدث خطأ في حفظ البيانات. يرجى المحاولة مرة أخرى.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// عرض رسالة خطأ
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// عرض رسالة نجاح
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // منع الرجوع للخلف
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تقييم الأعراض'),
          centerTitle: true,
          backgroundColor: MedicalTheme.primaryColor,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            // شريط التقدم
            LinearProgressIndicator(
              value: (_currentQuestion + 1) / 5,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                MedicalTheme.primaryColor,
              ),
              minHeight: 6,
            ),
            // عداد الأسئلة
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'السؤال ${_currentQuestion + 1} من 5',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            // الأسئلة
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentQuestion = index;
                  });
                },
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildQuestion1(), // العرض الرئيسي
                  _buildQuestion2(), // متى بدأت الأعراض
                  _buildQuestion3(), // هل يوجد ألم
                  _buildQuestion4(), // هل يوجد حمى أو تعب
                  _buildQuestion5(), // الأدوية الحالية
                ],
              ),
            ),
            // أزرار التنقل
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // زر الرجوع
                  if (_currentQuestion > 0)
                    ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                              _pageController.previousPage(
                                duration:
                                    const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('السابق'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        foregroundColor: Colors.white,
                      ),
                    )
                  else
                    const SizedBox(width: 120),
                  // زر المتابعة
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _goToNextQuestion,
                    icon: Icon(
                      _currentQuestion == 4
                          ? Icons.check
                          : Icons.arrow_forward,
                    ),
                    label: Text(
                      _currentQuestion == 4 ? 'إنهاء' : 'التالي',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MedicalTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// السؤال الأول: ما هو العرض الرئيسي
  Widget _buildQuestion1() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              '🏥 ما هو العرض الرئيسي الذي تعاني منه؟',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // قائمة الأعراض الشائعة
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _commonSymptoms.map((symptom) {
                final isSelected = _mainSymptom == symptom;
                return FilterChip(
                  label: Text(symptom),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _mainSymptom = isSelected ? '' : symptom;
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: MedicalTheme.primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // حقل إدخال مخصص
            TextField(
              onChanged: (value) {
                setState(() {
                  _mainSymptom = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'أو اكتب العرض الذي تعاني منه',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.edit),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// السؤال الثاني: منذ متى بدأت الأعراض
  Widget _buildQuestion2() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              '⏰ منذ متى بدأت الأعراض؟',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: _symptomDurations.map((duration) {
                final isSelected = _symptomStartDate == duration;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _symptomStartDate = duration;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? MedicalTheme.primaryColor
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected
                            ? MedicalTheme.primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? MedicalTheme.primaryColor
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            duration,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// السؤال الثالث: هل يوجد ألم
  Widget _buildQuestion3() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              '💔 هل تعاني من ألم؟',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // نعم
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _hasPain = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _hasPain
                          ? MedicalTheme.primaryColor
                          : Colors.grey[300]!,
                      width: _hasPain ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: _hasPain
                        ? MedicalTheme.primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _hasPain
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: _hasPain
                            ? MedicalTheme.primaryColor
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'نعم، أعاني من ألم',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // لا
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _hasPain = false;
                    _painLocation = '';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: !_hasPain
                          ? MedicalTheme.primaryColor
                          : Colors.grey[300]!,
                      width: !_hasPain ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: !_hasPain
                        ? MedicalTheme.primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        !_hasPain
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: !_hasPain
                            ? MedicalTheme.primaryColor
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'لا، لا أعاني من ألم',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // إذا كان الجواب نعم، اطلب موقع الألم
            if (_hasPain)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'أين موقع الألم؟',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _painLocations.map((location) {
                        final isSelected = _painLocation == location;
                        return FilterChip(
                          label: Text(location),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _painLocation = isSelected ? '' : location;
                            });
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: MedicalTheme.primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// السؤال الرابع: هل يوجد حمى أو تعب
  Widget _buildQuestion4() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              '🌡️ هل تعاني من حمى أو تعب عام؟',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // نعم
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _hasFeverOrTiredness = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _hasFeverOrTiredness
                          ? MedicalTheme.primaryColor
                          : Colors.grey[300]!,
                      width: _hasFeverOrTiredness ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: _hasFeverOrTiredness
                        ? MedicalTheme.primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _hasFeverOrTiredness
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: _hasFeverOrTiredness
                            ? MedicalTheme.primaryColor
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'نعم، أعاني من حمى أو تعب',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // لا
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _hasFeverOrTiredness = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: !_hasFeverOrTiredness
                          ? MedicalTheme.primaryColor
                          : Colors.grey[300]!,
                      width: !_hasFeverOrTiredness ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: !_hasFeverOrTiredness
                        ? MedicalTheme.primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        !_hasFeverOrTiredness
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: !_hasFeverOrTiredness
                            ? MedicalTheme.primaryColor
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'لا، لا أعاني من حمى أو تعب',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// السؤال الخامس: الأدوية الحالية
  Widget _buildQuestion5() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              '💊 هل تتناول أدوية حالياً؟',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // حقل إضافة أدوية
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: _medicationInput),
                    onChanged: (value) {
                      setState(() {
                        _medicationInput = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'أضف اسم الدواء',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.medication),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _medicationInput.isNotEmpty
                      ? () {
                          setState(() {
                            if (!_currentMedications
                                .contains(_medicationInput)) {
                              _currentMedications.add(_medicationInput);
                              _medicationInput = '';
                            }
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedicalTheme.primaryColor,
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // قائمة الأدوية المضافة
            if (_currentMedications.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الأدوية المضافة:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _currentMedications.map((med) {
                      return Chip(
                        label: Text(med),
                        onDeleted: () {
                          setState(() {
                            _currentMedications.remove(med);
                          });
                        },
                        backgroundColor: MedicalTheme.primaryColor
                            .withOpacity(0.2),
                      );
                    }).toList(),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Center(
                    child: Text(
                      'لم تضف أي أدوية (اختياري)',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
