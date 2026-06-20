import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/premium_ui.dart';
import '../../../home/presentation/pages/home_screen.dart';
import '../../../maps/widgets/doctor_location_map_card.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String? initialDoctorName;
  final String? initialSpecialtyName;

  const BookAppointmentScreen({
    super.key,
    this.initialDoctorName,
    this.initialSpecialtyName,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? _selectedSpecialty;
  String? _selectedDoctor;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedLocation;
  String? _selectedPayment;
  String? _selectedWorkplace;

  String? _doctorImageUrl;
  String? _patientImageUrl;

  bool _isLoading = false;
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _workplaces = [];
  Map<String, List<String>> _availableTimes = {};
  Map<String, List<String>> _bookedTimes = {};

  final List<String> specialties = [
    'القلب',
    'الأسنان',
    'العيون',
    'الباطنة',
    'الجلدية',
    'العظام',
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    final snapshot = await _firestore
        .collection('users')
        .where('accountType', isEqualTo: 'doctor')
        .where('isVerified', isEqualTo: true)
        .get();

    final loadedDoctors = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    Map<String, dynamic>? initialDoctor;
    if (widget.initialDoctorName != null) {
      for (final doctor in loadedDoctors) {
        if (doctor['fullName']?.toString() == widget.initialDoctorName) {
          initialDoctor = doctor;
          break;
        }
      }
    }

    setState(() {
      _doctors = loadedDoctors;
      if (initialDoctor != null) {
        _selectedDoctor = initialDoctor['fullName']?.toString();
        _selectedSpecialty = widget.initialSpecialtyName ?? initialDoctor['specialtyName']?.toString();
        _doctorImageUrl = initialDoctor['profileImageUrl']?.toString() ?? initialDoctor['photoURL']?.toString();
      }
    });

    final doctorId = initialDoctor?['uid']?.toString();
    if (doctorId != null && doctorId.isNotEmpty) {
      await _loadDoctorWorkplaces(doctorId);
    }
  }

  Future<void> _loadDoctorWorkplaces(String doctorId) async {
    final doc = await _firestore.collection('users').doc(doctorId).get();
    if (doc.exists) {
      final data = doc.data()!;
      final workplaces = List<Map<String, dynamic>>.from(data['workplaces'] ?? []);

      setState(() {
        _workplaces = workplaces;
        _selectedWorkplace = null;
        _selectedLocation = null;
        _availableTimes = {};
        _bookedTimes = {};
      });
    }
  }

  Future<void> _loadAvailableTimes(String workplaceName, DateTime date) async {
    final dayName = DateFormat('EEEE', 'ar').format(date);
    final doctor = _doctors.firstWhere((d) => d['fullName'] == _selectedDoctor);
    final workplaces = List<Map<String, dynamic>>.from(doctor['workplaces'] ?? []);

    final workplace = workplaces.firstWhere(
          (wp) => wp['name'] == workplaceName,
      orElse: () => {},
    );

    if (workplace.isNotEmpty) {
      final workDays = Map<String, dynamic>.from(workplace['workDays'] ?? {});
      final dayTimes = List<Map<String, dynamic>>.from(workDays[dayName] ?? []);

      await _loadBookedTimes(doctor['uid'], workplaceName, date);

      final availableTimes = <String>[];
      for (var timeSlot in dayTimes) {
        final startTime = TimeOfDay(
          hour: timeSlot['startHour'],
          minute: timeSlot['startMinute'],
        );
        final endTime = TimeOfDay(
          hour: timeSlot['endHour'],
          minute: timeSlot['endMinute'],
        );

        print('⏰ فترة العمل الأصلية: ${startTime.format(context)} - ${endTime.format(context)}');
        print('🔢 البيانات الخام: startHour=${timeSlot['startHour']}, endHour=${timeSlot['endHour']}');

        var currentHour = startTime.hour;
        var currentMinute = startTime.minute;

        while (currentHour < endTime.hour ||
            (currentHour == endTime.hour && currentMinute < endTime.minute)) {

          final timeStr = '${currentHour.toString().padLeft(2, '0')}:${currentMinute.toString().padLeft(2, '0')}';

          // التحقق إذا كان الوقت محجوزاً مسبقاً
          final isBooked = _isTimeBooked(workplaceName, timeStr);
          if (!isBooked) {
            availableTimes.add(timeStr);
            print('✅ الوقت المتاح: $timeStr');
          }

          // إضافة 30 دقيقة
          currentMinute += 30;
          if (currentMinute >= 60) {
            currentMinute -= 60;
            currentHour += 1;
          }
        }
      }

      print('📋 إجمالي الأوقات المتاحة: ${availableTimes.length}');
      print('📋 الأوقات المتاحة النهائية: $availableTimes');

      setState(() {
        _availableTimes[workplaceName] = availableTimes;
      });
    }
  }

  Future<void> _loadBookedTimes(String doctorId, String workplaceName, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // جلب جميع المواعيد للطبيب وفلترتها محلياً
      final snapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      final bookedTimes = <String>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();

        // فلترة محلياً
        final appointmentWorkplace = data['workplace'] as String?;
        final appointmentDate = data['date'] as Timestamp?;
        final appointmentStatus = data['status'] as String?;
        final appointmentTime = data['time'] as String?;

        if (appointmentWorkplace == workplaceName &&
            appointmentDate != null &&
            appointmentDate.toDate().isAfter(startOfDay) &&
            appointmentDate.toDate().isBefore(endOfDay.add(const Duration(seconds: 1))) &&
            (appointmentStatus == 'pending' || appointmentStatus == 'confirmed') &&
            appointmentTime != null) {
          bookedTimes.add(appointmentTime);
        }
      }

      setState(() {
        _bookedTimes[workplaceName] = bookedTimes;
      });
    } catch (e, s) {
      print("Error loading booked times: $e");
      print(s);
    }
  }

  bool _isTimeBooked(String workplaceName, String timeStr) {
    return _bookedTimes[workplaceName]?.contains(timeStr) ?? false;
  }

  void _confirmBooking() async {
    if (_auth.currentUser == null ||
        _selectedDoctor == null ||
        _selectedDate == null ||
        _selectedTime == null ||
        _selectedWorkplace == null ||
        _selectedPayment == null) return;

    // التحقق مرة أخرى إذا كان الوقت محجوزاً
    final timeStr = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
    if (_isTimeBooked(_selectedWorkplace!, timeStr)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ هذا الموعد محجوز مسبقاً، يرجى اختيار وقت آخر')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUserId = _auth.currentUser!.uid;

      String userName = 'مستخدم';
      String userImageUrl = '';
      String userPhone = '';

      final patientDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (patientDoc.exists) {
        final data = patientDoc.data();
        if (data != null) {
          userName = data['fullName'] ?? 'مستخدم';
          userImageUrl = data['profilePicture'] ?? data['photoURL'] ?? '';
          userPhone = data['phone'] ?? '';
        }
      }

      final doctor = _doctors.firstWhere((d) => d['fullName'] == _selectedDoctor);
      final doctorId = doctor['uid'];
      final doctorImageUrl = doctor['profileImageUrl'] ?? '';
      final doctorPhone = doctor['phone'] ?? '';
      final bookingFee = _bookingFeeForDoctor(doctor);

      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await _firestore.collection('appointments').add({
        'userId': currentUserId,
        'userName': userName,
        'userImageUrl': userImageUrl,
        'userPhone': userPhone,

        'doctorId': doctorId,
        'doctorName': _selectedDoctor,
        'doctorImageUrl': doctorImageUrl,
        'doctorPhone': doctorPhone,

        'specialtyName': _selectedSpecialty,
        'date': Timestamp.fromDate(_selectedDate!),
        'time': _selectedTime!.format(context),
        'workplace': _selectedWorkplace,
        'payment': _selectedPayment,
        'paymentMethod': _selectedPayment,
        'paymentStatus': _selectedPayment == 'الدفع عند المقابلة' ? 'pending_at_visit' : 'unpaid',
        'bookingFee': bookingFee,
        'consultationFee': bookingFee,
        'price': bookingFee,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),

        // إشعارات المواعيد لاحقاً
        'notified': {
          '1day': false,
          '6hours': false,
          '1hour': false,
          'ontime': false,
          'cancelled': false,
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم تأكيد الحجز بنجاح!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ حدث خطأ أثناء الحجز: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFormComplete = _selectedDoctor != null &&
        _selectedDate != null &&
        _selectedTime != null &&
        _selectedWorkplace != null &&
        _selectedPayment != null;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        title: const Text('حجز موعد جديد'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : PremiumGradientBackground(
              child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        child: Column(
          children: [
            _buildDropdownCard(
              title: 'اختر القسم والطبيب',
              children: [
                _buildDropdown<String>(
                  label: 'القسم',
                  value: _selectedSpecialty,
                  items: specialties,
                  icon: Icons.medical_services,
                  onChanged: (val) {
                    setState(() {
                      _selectedSpecialty = val;
                      _selectedDoctor = null;
                      _workplaces = [];
                      _selectedWorkplace = null;
                      _doctorImageUrl = null;
                      _availableTimes = {};
                      _bookedTimes = {};
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdown<String>(
                  label: 'الطبيب',
                  value: _selectedDoctor,
                  items: _doctors
                      .where((d) =>
                  _selectedSpecialty == null ||
                      d['specialtyName'] == _selectedSpecialty)
                      .map((d) => d['fullName'] as String)
                      .toList(),
                  icon: Icons.person,
                  onChanged: (val) async {
                    setState(() {
                      _selectedDoctor = val;
                      _availableTimes = {};
                      _bookedTimes = {};
                      _selectedDate = null;
                      _selectedTime = null;
                    });
                    if (val != null) {
                      final doctor = _doctors.firstWhere((d) => d['fullName'] == val);
                      _doctorImageUrl = doctor['profileImageUrl'];
                      await _loadDoctorWorkplaces(doctor['uid']);
                    }
                  },
                ),
              ],
            ),

            if (_selectedDoctor != null)
              _buildDoctorDetails(
                _doctors.firstWhere((d) => d['fullName'] == _selectedDoctor),
              ),

            const SizedBox(height: 24),

            if (_selectedDoctor != null && _workplaces.isNotEmpty)
              _buildDropdownCard(
                title: 'اختر مستشفى او عيادة',
                children: [
                  _buildDropdown<String>(
                    label: 'مستشفى او عيادة',
                    value: _selectedWorkplace,
                    items: _workplaces.map((wp) => wp['name'] as String).toList(),
                    icon: Icons.work,
                    onChanged: (val) {
                      setState(() {
                        _selectedWorkplace = val;
                        _selectedDate = null;
                        _selectedTime = null;
                        _availableTimes = {};
                        _bookedTimes = {};
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedWorkplace != null)
                    _buildWorkplaceSchedule(_selectedWorkplace!),
                ],
              ),

            const SizedBox(height: 24),

            if (_selectedWorkplace != null)
              _buildDropdownCard(
                title: 'حدد تاريخ و وقت الحجز',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_selectedDate == null
                              ? 'اختر التاريخ'
                              : DateFormat('yyyy/MM/dd').format(_selectedDate!)),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedDate = picked;
                                _selectedTime = null;
                              });
                              if (_selectedWorkplace != null) {
                                await _loadAvailableTimes(_selectedWorkplace!, picked);
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTimeDropdown(),
                      ),
                    ],
                  ),
                  if (_selectedDate != null && _availableTimes[_selectedWorkplace]?.isEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'لا توجد أوقات متاحة في هذا التاريخ',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 24),

            _buildDropdownCard(
              title: 'اختر طريقة الدفع',
              children: [
                _buildDropdown<String>(
                  label: 'طريقة الدفع',
                  value: _selectedPayment,
                  items: const ['الدفع عند المقابلة', 'بطاقة بنكية'],
                  icon: Icons.payment,
                  onChanged: (val) => setState(() => _selectedPayment = val),
                ),
              ],
            ),

            const SizedBox(height: 32),

            PremiumSurface(
              padding: const EdgeInsets.all(8),
              radius: 24,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: Text(_selectedPayment == 'الدفع عند المقابلة' ? 'تأكيد الحجز' : 'تأكيد الحجز والدفع'),
                onPressed: isFormComplete ? _confirmBooking : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            ),
          ],
        ),
      ),
            ),
    );
  }

  Widget _buildTimeDropdown() {
    final times = _selectedWorkplace != null && _selectedDate != null
        ? _availableTimes[_selectedWorkplace] ?? []
        : [];

    return DropdownButtonFormField<TimeOfDay>(
      value: _selectedTime,
      decoration: InputDecoration(
        labelText: 'الوقت',
        prefixIcon: Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        enabled: times.isNotEmpty,
      ),
      items: times.map((timeStr) {
        final parts = timeStr.split(':');
        final time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        return DropdownMenuItem<TimeOfDay>(
          value: time,
          child: Text(time.format(context), style: TextStyle(fontSize: 13),),
        );
      }).toList(),
      onChanged: (time) => setState(() => _selectedTime = time),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required IconData icon,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
      items: items
          .map((item) => DropdownMenuItem<T>(value: item, child: Text(item.toString())))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDropdownCard({required String title, required List<Widget> children}) {
    return PremiumSurface(
      margin: const EdgeInsets.only(bottom: 16),
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumSectionHeader(
            title: title,
            subtitle: 'خطوة مصممة لتسهيل الحجز بسرعة ووضوح',
            icon: Icons.auto_awesome_rounded,
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDoctorDetails(Map<String, dynamic> doctor) {
    final theme = Theme.of(context);
    final bookingFee = _bookingFeeForDoctor(doctor);
    return PremiumSurface(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: doctor['profileImageUrl'] != null
                  ? NetworkImage(doctor['profileImageUrl'])
                  : const AssetImage('assets/images/doctor_placeholder.png') as ImageProvider,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctor['fullName'],
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
                  Text(doctor['specialtyName'] ?? '',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(.64))),
                  const SizedBox(height: 4),
                  if (doctor['rating'] != null)
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: theme.colorScheme.tertiary),
                        Text(doctor['rating'].toString()),
                      ],
                    ),
                  if (doctor['specialty'] != null)
                    Text(
                      doctor['specialty'],
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(.64)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(Icons.payments, size: 16, color: theme.colorScheme.primary),
                label: Text('قيمة الحجز: ${_formatFee(bookingFee)}'),
              ),
              Chip(avatar: Icon(Icons.reviews, size: 16, color: theme.colorScheme.primary), label: Text('المراجعات: ${doctor['reviewsCount'] ?? doctor['reviewCount'] ?? 0}')),
              if (doctor['moodIndicator'] != null || doctor['mood'] != null) Chip(label: Text('مؤشر الحالة: ${doctor['moodIndicator'] ?? doctor['mood']}')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'عنوان العيادة: ${doctor['address'] ?? doctor['clinicAddress'] ?? 'غير محدد'}',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          DoctorLocationMapCard(
            latitude: (doctor['latitude'] as num?)?.toDouble(),
            longitude: (doctor['longitude'] as num?)?.toDouble(),
            address: (doctor['address'] ?? doctor['clinicAddress'])?.toString(),
          ),
        ],
      ),
    );
  }

  double _bookingFeeForDoctor(Map<String, dynamic> doctor) {
    final value = doctor['bookingFee'] ??
        doctor['consultationFee'] ??
        doctor['sessionPrice'] ??
        doctor['minSessionPrice'] ??
        doctor['minPrice'] ??
        0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _formatFee(double fee) {
    if (fee <= 0) return 'غير محددة';
    final hasDecimals = fee.truncateToDouble() != fee;
    return '${fee.toStringAsFixed(hasDecimals ? 2 : 0)} ريال';
  }

  Widget _buildWorkplaceSchedule(String workplaceName) {
    final workplace = _workplaces.firstWhere((wp) => wp['name'] == workplaceName);
    final workDays = Map<String, dynamic>.from(workplace['workDays'] ?? {});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أوقات الدوام:',
          style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        ...workDays.entries.map((entry) {
          final dayName = entry.key;
          final times = List<Map<String, dynamic>>.from(entry.value ?? []);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(dayName),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: times.map((time) {
                      final start = TimeOfDay(
                        hour: time['startHour'],
                        minute: time['startMinute'],
                      );
                      final end = TimeOfDay(
                        hour: time['endHour'],
                        minute: time['endMinute'],
                      );
                      return Chip(
                        label: Text('${start.format(context)} - ${end.format(context)}'),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
