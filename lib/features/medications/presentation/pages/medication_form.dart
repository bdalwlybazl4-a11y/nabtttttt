import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:digl/services/patient_medication_reminder_service.dart';

class MedicationFormScreen extends StatefulWidget {
  final String userId;
  final String? patientId;
  final String? consultationId;
  final DocumentSnapshot? doc;

  const MedicationFormScreen({
    super.key,
    required this.userId,
    this.patientId,
    this.consultationId,
    this.doc,
  });

  @override
  State<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController doseController;
  late TextEditingController scheduleController;
  late TextEditingController notesController;
  late TextEditingController durationController;
  late TextEditingController typeController;

  List<TimeOfDay> selectedTimes = [];
  String? selectedPatientId;
  String? selectedConsultationId;
  bool enableReminders = true;

  @override
  void initState() {
    super.initState();
    final data = widget.doc?.data() as Map<String, dynamic>?;

    nameController = TextEditingController(text: data?['name'] ?? '');
    doseController = TextEditingController(text: data?['dose'] ?? '');
    scheduleController = TextEditingController(text: data?['schedule'] ?? '');
    notesController = TextEditingController(text: data?['notes'] ?? '');
    durationController = TextEditingController(text: data?['duration'] ?? '');
    typeController = TextEditingController(text: data?['type'] ?? '');

    selectedTimes = _readTimesFromDocument(data);
    selectedPatientId = widget.patientId ?? (data?['patientId']?.toString() ?? '');
    selectedConsultationId =
        widget.consultationId ?? (data?['consultationId']?.toString() ?? '');
    enableReminders = data?['enableReminders'] as bool? ?? true;
  }

  List<TimeOfDay> _readTimesFromDocument(Map<String, dynamic>? data) {
    final raw24 = (data?['times24'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    if (raw24.isNotEmpty) {
      return raw24.map(_parse24HourTime).whereType<TimeOfDay>().toList();
    }

    final raw12 = (data?['times'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    return raw12.map(_parse12HourTime).whereType<TimeOfDay>().toList();
  }

  TimeOfDay? _parse24HourTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  TimeOfDay? _parse12HourTime(String value) {
    try {
      final date = DateFormat('hh:mm a').parse(value);
      return TimeOfDay(hour: date.hour, minute: date.minute);
    } catch (_) {
      return null;
    }
  }

  String formatTimeOfDayTo12Hour(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        selectedTimes.add(time);
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    doseController.dispose();
    scheduleController.dispose();
    notesController.dispose();
    durationController.dispose();
    typeController.dispose();
    super.dispose();
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    final medicationName = nameController.text.trim();
    final medicationTimes12 =
        selectedTimes.map((t) => formatTimeOfDayTo12Hour(t)).toList();
    final medicationTimes24 =
        selectedTimes.map(PatientMedicationReminderService.formatTime24).toList();

    if (selectedPatientId == null || selectedPatientId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار المريض قبل الحفظ.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (medicationTimes24.isEmpty && enableReminders) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إضافة وقت واحد على الأقل للتذكير.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final medicationData = {
      'name': medicationName,
      'dose': doseController.text.trim(),
      'schedule': scheduleController.text.trim(),
      'doctorId': widget.userId,
      'userId': widget.userId,
      'patientId': selectedPatientId,
      'consultationId': selectedConsultationId,
      'notes': notesController.text.trim(),
      'duration': durationController.text.trim(),
      'type': typeController.text.trim(),
      'times': medicationTimes12,
      'times24': medicationTimes24,
      'enableReminders': enableReminders,
      'history': widget.doc?.get('history') ?? [],
      'status': enableReminders ? 'pending' : 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
      'scheduledNotificationIds': [],
    };

    try {
      if (widget.doc != null) {
        await widget.doc!.reference.update(medicationData);
        if (enableReminders) {
          await PatientMedicationReminderService.cancelMedicationReminders(
            widget.doc!.id,
          );
        }
      } else {
        await FirebaseFirestore.instance.collection('medications').add({
          ...medicationData,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enableReminders
              ? '✅ تم إرسال الدواء للمريض بانتظار الموافقة.'
              : '✅ تم حفظ الدواء بنجاح.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ في حفظ الدواء: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.doc != null;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        foregroundColor: Colors.blue,
        elevation: 2,
        title: Text(isEditing ? 'تعديل الدواء' : 'إضافة دواء جديد'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildSectionHeader('معلومات الدواء'),
              _buildInputField(
                controller: nameController,
                label: 'اسم الدواء',
                icon: Icons.medical_services,
                validator: (v) =>
                    v == null || v.isEmpty ? 'يرجى إدخال اسم الدواء' : null,
              ),
              _buildInputField(
                controller: doseController,
                label: 'الجرعة',
                icon: Icons.local_pharmacy,
              ),
              _buildInputField(
                controller: scheduleController,
                label: 'تعليمات الدواء',
                icon: Icons.schedule,
              ),
              _buildInputField(
                controller: durationController,
                label: 'مدة العلاج (أيام)',
                icon: Icons.timelapse,
              ),
              _buildInputField(
                controller: typeController,
                label: 'نوع الدواء',
                icon: Icons.category,
              ),
              _buildInputField(
                controller: notesController,
                label: 'ملاحظات الطبيب',
                icon: Icons.note_alt,
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('أوقات تناول الدواء'),
              const Text('يمكن إضافة أكثر من وقت يوميًا (مثل 08:00، 14:00، 21:00).'),
              Wrap(
                spacing: 8,
                children: selectedTimes.map((time) {
                  return Chip(
                    label: Text(time.format(context)),
                    onDeleted: () {
                      setState(() {
                        selectedTimes.remove(time);
                      });
                    },
                  );
                }).toList(),
              ),
              TextButton.icon(
                icon: const Icon(Icons.access_time),
                label: const Text('إضافة وقت'),
                onPressed: _selectTime,
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('ربط الدواء'),
              _buildPatientSelector(),
              const SizedBox(height: 16),
              _buildConsultationSelector(),
              const SizedBox(height: 24),
              _buildSectionHeader('الإشعارات'),
              CheckboxListTile(
                title: const Text('يتطلب موافقة المريض قبل التفعيل'),
                subtitle: const Text(
                    'عند التفعيل سيتم إنشاء طلب pending، ولا يتم جدولة المنبه إلا بعد موافقة المريض.'),
                value: enableReminders,
                onChanged: (value) {
                  setState(() {
                    enableReminders = value ?? true;
                  });
                },
                controlAffinity: ListTileControlAffinity.trailing,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: _saveMedication,
                    child: const Text('حفظ'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E5CB8),
        ),
      ),
    );
  }

  Widget _buildPatientSelector() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('accountType', isEqualTo: 'patient')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final patients = snapshot.data?.docs ?? [];

        return DropdownButtonFormField<String>(
          value: selectedPatientId?.isNotEmpty == true ? selectedPatientId : null,
          hint: const Text('اختر المريض'),
          items: patients.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return DropdownMenuItem(
              value: doc.id,
              child: Text(data['fullName'] ?? 'مريض بدون اسم'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedPatientId = value;
            });
          },
          decoration: InputDecoration(
            labelText: 'المريض',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  Widget _buildConsultationSelector() {
    if (selectedPatientId == null || selectedPatientId!.isEmpty) {
      return const Text(
        'اختر المريض أولاً لتتمكن من ربط الاستشارة',
        style: TextStyle(color: Colors.orange, fontSize: 12),
      );
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('consultations')
          .where('patientId', isEqualTo: selectedPatientId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final consultations = snapshot.data?.docs ?? [];

        if (consultations.isEmpty) {
          return const Text(
            'لا توجد استشارات لهذا المريض',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          );
        }

        return DropdownButtonFormField<String>(
          value:
              selectedConsultationId?.isNotEmpty == true ? selectedConsultationId : null,
          hint: const Text('اختر الاستشارة (اختياري)'),
          items: consultations.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final doctorName = data['doctorName'] ?? 'طبيب';
            final date = data['createdAt']?.toDate().toString().split(' ')[0] ?? 'تاريخ';
            return DropdownMenuItem(
              value: doc.id,
              child: Text('$doctorName - $date'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedConsultationId = value;
            });
          },
          decoration: InputDecoration(
            labelText: 'الاستشارة (اختياري)',
            prefixIcon: const Icon(Icons.medical_information),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }
}
