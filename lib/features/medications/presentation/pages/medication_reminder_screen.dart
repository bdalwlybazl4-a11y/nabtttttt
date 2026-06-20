import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digl/features/model.dart';
import 'package:digl/services/medication_service.dart';
import 'package:digl/core/config/medical_theme.dart';
import 'package:digl/services/advanced_medication_reminder_service.dart';
import 'package:intl/intl.dart';

/// شاشة إدارة تذكيرات الأدوية
class MedicationReminderScreen extends StatefulWidget {
  const MedicationReminderScreen({super.key});

  @override
  State<MedicationReminderScreen> createState() =>
      _MedicationReminderScreenState();
}

class _MedicationReminderScreenState extends State<MedicationReminderScreen> {
  late MedicationService _medicationService;

  @override
  void initState() {
    super.initState();
    _medicationService = Provider.of<MedicationService>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تذكيرات الأدوية'),
        centerTitle: true,
        backgroundColor: MedicalTheme.primaryColor,
      ),
      body: StreamBuilder<List<Medication>>(
        stream: _medicationService.getMedications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('حدث خطأ: ${snapshot.error}'),
            );
          }

          final medications = snapshot.data ?? [];

          if (medications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: medications.length,
            itemBuilder: (context, index) {
              final medication = medications[index];
              return _buildMedicationCard(medication);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MedicalTheme.primaryColor,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddMedicationReminderScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// بناء بطاقة الدواء
  Widget _buildMedicationCard(Medication medication) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.medication, color: Colors.blue),
        title: Text(
          medication.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('الجرعة: ${medication.dose}'),
            Text('المدة: ${medication.duration}'),
            Text('الأوقات: ${medication.times.join(", ")}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('تعديل'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditMedicationReminderScreen(
                      medication: medication,
                    ),
                  ),
                );
              },
            ),
            PopupMenuItem(
              child: const Text('حذف'),
              onTap: () {
                _showDeleteConfirmation(medication.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// حالة الشاشة عندما تكون قائمة الأدوية فارغة
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'لا توجد أدوية مضافة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'اضغط على + لإضافة أول دواء',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// عرض تأكيد الحذف
  void _showDeleteConfirmation(String medicationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الدواء'),
        content: const Text('هل تريد حذف هذا الدواء بالفعل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _medicationService.deleteMedication(medicationId);
              // إلغاء التذكيرات المرتبطة بهذا الدواء
              await AdvancedMedicationReminderService.cancelMedicationReminders(
                medicationId,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الدواء')),
                );
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// شاشة إضافة دواء جديد مع تذكير
class AddMedicationReminderScreen extends StatefulWidget {
  const AddMedicationReminderScreen({super.key});

  @override
  State<AddMedicationReminderScreen> createState() =>
      _AddMedicationReminderScreenState();
}

class _AddMedicationReminderScreenState
    extends State<AddMedicationReminderScreen> {
  late TextEditingController _nameController;
  late TextEditingController _doseController;
  late TextEditingController _noteController;

  String _selectedSchedule = 'مرة واحدة يومياً';
  List<String> _times = [];
  String _duration = '7'; // أيام
  bool _isLoading = false;

  final List<String> _schedules = [
    'مرة واحدة يومياً',
    'مرتين يومياً',
    'ثلاث مرات يومياً',
    'أربع مرات يومياً',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _doseController = TextEditingController();
    _noteController = TextEditingController();
    _initializeTimes();
  }

  /// تهيئة الأوقات بناءً على الجدول المختار
  void _initializeTimes() {
    _times.clear();
    switch (_selectedSchedule) {
      case 'مرة واحدة يومياً':
        _times = ['08:00'];
        break;
      case 'مرتين يومياً':
        _times = ['08:00', '20:00'];
        break;
      case 'ثلاث مرات يومياً':
        _times = ['08:00', '14:00', '20:00'];
        break;
      case 'أربع مرات يومياً':
        _times = ['08:00', '12:00', '16:00', '20:00'];
        break;
    }
  }

  /// التحقق من البيانات المدخلة
  bool _validateInput() {
    if (_nameController.text.isEmpty) {
      _showErrorSnackBar('يرجى إدخال اسم الدواء');
      return false;
    }
    if (_doseController.text.isEmpty) {
      _showErrorSnackBar('يرجى إدخال الجرعة');
      return false;
    }
    if (_times.isEmpty) {
      _showErrorSnackBar('يرجى تحديد أوقات التذكير');
      return false;
    }
    return true;
  }

  /// حفظ الدواء الجديد
  Future<void> _saveMedication() async {
    if (!_validateInput()) return;

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final medicationService =
          Provider.of<MedicationService>(context, listen: false);

      // إنشاء دواء جديد
      final newMedication = Medication(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        dose: _doseController.text,
        schedule: _selectedSchedule,
        next: _times.first,
        userId: '',
        history: [],
        type: 'تذكير يومي',
        duration: '$_duration أيام',
        note: _noteController.text,
        createdAt: Timestamp.now(),
        times: _times,
      );

      // حفظ الدواء
      await medicationService.addMedication(newMedication);

      // جدولة التذكيرات
      await AdvancedMedicationReminderService.scheduleMedicationReminders(
        medicationId: newMedication.id,
        medicationName: newMedication.name,
        times: _times,
        durationDays: int.parse(_duration),
      );

      _showSuccessSnackBar('تم إضافة الدواء والتذكير بنجاح');
      Navigator.pop(context);
    } catch (e) {
      print('❌ خطأ في حفظ الدواء: $e');
      _showErrorSnackBar('حدث خطأ في حفظ الدواء');
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
      ),
    );
  }

  /// عرض رسالة نجاح
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة دواء جديد'),
        centerTitle: true,
        backgroundColor: MedicalTheme.primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // اسم الدواء
          const Text(
            'اسم الدواء *',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'مثال: أسبيرين',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.medication),
            ),
          ),
          const SizedBox(height: 20),

          // الجرعة
          const Text(
            'الجرعة *',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _doseController,
            decoration: InputDecoration(
              hintText: 'مثال: 500 ملغ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.scale),
            ),
          ),
          const SizedBox(height: 20),

          // جدول التناول
          const Text(
            'جدول التناول',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: _selectedSchedule,
            isExpanded: true,
            items: _schedules
                .map((schedule) => DropdownMenuItem(
                      value: schedule,
                      child: Text(schedule),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedSchedule = value;
                  _initializeTimes();
                });
              }
            },
          ),
          const SizedBox(height: 20),

          // أوقات التذكير
          const Text(
            'أوقات التذكير',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Column(
            children: List.generate(_times.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_times[index]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
                        final newTime = await _selectTime();
                        if (newTime != null) {
                          setState(() {
                            _times[index] = newTime;
                          });
                        }
                      },
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // مدة العلاج
          const Text(
            'مدة العلاج (بالأيام)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _duration,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _duration = value.isEmpty ? '7' : value;
              });
            },
            decoration: InputDecoration(
              hintText: 'عدد الأيام',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 20),

          // ملاحظات
          const Text(
            'ملاحظات (اختياري)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'أضف أي ملاحظات هنا',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // زر الحفظ
          ElevatedButton(
            onPressed: _isLoading ? null : _saveMedication,
            style: ElevatedButton.styleFrom(
              backgroundColor: MedicalTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text(
                    'إضافة الدواء والتذكير',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  /// اختيار الوقت
  Future<String?> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
    return null;
  }
}

/// شاشة تعديل الدواء
class EditMedicationReminderScreen extends StatefulWidget {
  final Medication medication;

  const EditMedicationReminderScreen({
    super.key,
    required this.medication,
  });

  @override
  State<EditMedicationReminderScreen> createState() =>
      _EditMedicationReminderScreenState();
}

class _EditMedicationReminderScreenState
    extends State<EditMedicationReminderScreen> {
  late TextEditingController _nameController;
  late TextEditingController _doseController;
  late TextEditingController _noteController;

  late String _selectedSchedule;
  late List<String> _times;
  late String _duration;
  bool _isLoading = false;

  final List<String> _schedules = [
    'مرة واحدة يومياً',
    'مرتين يومياً',
    'ثلاث مرات يومياً',
    'أربع مرات يومياً',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medication.name);
    _doseController = TextEditingController(text: widget.medication.dose);
    _noteController = TextEditingController(text: widget.medication.note);
    _selectedSchedule = widget.medication.schedule;
    _times = List.from(widget.medication.times);
    _duration = widget.medication.duration.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// حفظ التعديلات
  Future<void> _updateMedication() async {
    if (_nameController.text.isEmpty) {
      _showErrorSnackBar('يرجى إدخال اسم الدواء');
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final medicationService =
          Provider.of<MedicationService>(context, listen: false);

      final updatedMedication = widget.medication.copyWith(
        name: _nameController.text,
        dose: _doseController.text,
        schedule: _selectedSchedule,
        note: _noteController.text,
        times: _times,
        duration: '$_duration أيام',
      );

      // تحديث الدواء
      await medicationService.updateMedication(updatedMedication);

      // إعادة جدولة التذكيرات
      await AdvancedMedicationReminderService.cancelMedicationReminders(
        widget.medication.id,
      );
      await AdvancedMedicationReminderService.scheduleMedicationReminders(
        medicationId: updatedMedication.id,
        medicationName: updatedMedication.name,
        times: _times,
        durationDays: int.parse(_duration),
      );

      _showSuccessSnackBar('تم تحديث الدواء والتذكير');
      Navigator.pop(context);
    } catch (e) {
      print('❌ خطأ في تحديث الدواء: $e');
      _showErrorSnackBar('حدث خطأ في تحديث الدواء');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الدواء'),
        centerTitle: true,
        backgroundColor: MedicalTheme.primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'اسم الدواء',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.medication),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _doseController,
            decoration: InputDecoration(
              labelText: 'الجرعة',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.scale),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButton<String>(
            value: _selectedSchedule,
            isExpanded: true,
            items: _schedules
                .map((schedule) => DropdownMenuItem(
                      value: schedule,
                      child: Text(schedule),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedSchedule = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'ملاحظات',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _isLoading ? null : _updateMedication,
            style: ElevatedButton.styleFrom(
              backgroundColor: MedicalTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text(
                    'تحديث الدواء',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Extension لإضافة copyWith إلى Medication
extension MedicationCopyWith on Medication {
  Medication copyWith({
    String? id,
    String? name,
    String? dose,
    String? schedule,
    String? next,
    String? userId,
    List<dynamic>? history,
    String? type,
    String? duration,
    String? note,
    Timestamp? createdAt,
    List<String>? times,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      schedule: schedule ?? this.schedule,
      next: next ?? this.next,
      userId: userId ?? this.userId,
      history: history ?? this.history,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      times: times ?? this.times,
    );
  }
}
