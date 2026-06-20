import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digl/features/doctor/presentation/doctorsListWidget.dart';

/// نموذج البيانات للطبيب
class DoctorModel {
  final String id;
  final String fullName;
  final String specialty;
  final String phoneNumber;
  final String profileImage;
  final double rating;
  final int reviewCount;
  final String bio;
  final List<String> specialties;

  DoctorModel({
    required this.id,
    required this.fullName,
    required this.specialty,
    required this.phoneNumber,
    required this.profileImage,
    required this.rating,
    required this.reviewCount,
    required this.bio,
    required this.specialties,
  });

  factory DoctorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DoctorModel(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      specialty: data['specialty'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      profileImage: data['profileImage'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      bio: data['bio'] ?? '',
      specialties: List<String>.from(data['specialties'] ?? []),
    );
  }
}

class SuggestedDoctorScreen extends StatefulWidget {
  final List<String> specialties;
  final int patientAge;
  final String patientGender;

  const SuggestedDoctorScreen({
    super.key,
    required this.specialties,
    required this.patientAge,
    required this.patientGender,
  });

  @override
  State<SuggestedDoctorScreen> createState() => _SuggestedDoctorScreenState();
}

class _SuggestedDoctorScreenState extends State<SuggestedDoctorScreen> {
  late Future<List<DoctorModel>> _doctorsFuture;
  List<DoctorModel> _selectedDoctors = [];

  @override
  void initState() {
    super.initState();
    _doctorsFuture = _fetchSuggestedDoctors();
  }

  /// جلب الأطباء المقترحين بناءً على التخصص
  Future<List<DoctorModel>> _fetchSuggestedDoctors() async {
    try {
      final doctors = <DoctorModel>[];

      for (final specialty in widget.specialties) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('doctors')
            .where('specialty', isEqualTo: specialty)
            .where('isVerified', isEqualTo: true)
            .limit(3)
            .get();

        for (final doc in querySnapshot.docs) {
          final doctor = DoctorModel.fromFirestore(doc);
          // تجنب التكرار
          if (!doctors.any((d) => d.id == doctor.id)) {
            doctors.add(doctor);
          }
        }
      }

      // إذا لم نجد أطباء بالتخصص، جلب أطباء عامين
      if (doctors.isEmpty) {
        final generalDoctors = await FirebaseFirestore.instance
            .collection('doctors')
            .where('specialty', isEqualTo: 'طبيب عام')
            .where('isVerified', isEqualTo: true)
            .limit(5)
            .get();

        for (final doc in generalDoctors.docs) {
          doctors.add(DoctorModel.fromFirestore(doc));
        }
      }

      // ترتيب الأطباء حسب التقييم
      doctors.sort((a, b) => b.rating.compareTo(a.rating));

      _selectedDoctors = doctors.take(3).toList();
      return doctors;
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأطباء المقترحون'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3A86FF),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<DoctorModel>>(
        future: _doctorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildNoDoctorsFound();
          }

          final doctors = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 24),
                _buildDoctorsList(doctors),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      color: const Color(0xFF3A86FF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.verified, color: Colors.white, size: 40),
            const SizedBox(height: 12),
            const Text(
              'الأطباء المقترحون',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اخترنا لك أفضل الأطباء المتخصصين في ${widget.specialties.join(", ")}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorsList(List<DoctorModel> doctors) {
    return Column(
      children: doctors.map((doctor) {
        return _buildDoctorCard(doctor);
      }).toList(),
    );
  }

  Widget _buildDoctorCard(DoctorModel doctor) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // صورة الطبيب
                CircleAvatar(
                  radius: 40,
                  backgroundImage: doctor.profileImage.isNotEmpty
                      ? NetworkImage(doctor.profileImage)
                      : null,
                  child: doctor.profileImage.isEmpty
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                const SizedBox(width: 12),
                // معلومات الطبيب
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor.specialty,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF3A86FF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // التقييم
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${doctor.rating.toStringAsFixed(1)} (${doctor.reviewCount} تقييم)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // زر الاختيار
                Checkbox(
                  value: _selectedDoctors.contains(doctor),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        if (!_selectedDoctors.contains(doctor)) {
                          _selectedDoctors.add(doctor);
                        }
                      } else {
                        _selectedDoctors.remove(doctor);
                      }
                    });
                  },
                  activeColor: const Color(0xFF3A86FF),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // الوصف
            if (doctor.bio.isNotEmpty)
              Text(
                doctor.bio,
                style: const TextStyle(fontSize: 13, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (doctor.bio.isNotEmpty) const SizedBox(height: 12),
            // زر الحجز
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _bookAppointment(doctor),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A86FF),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'احجز موعد',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDoctorsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'لم نجد أطباء متاحين حالياً',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'حاول لاحقاً أو تواصل معنا للحصول على المساعدة',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          },
          icon: const Icon(Icons.home),
          label: const Text('العودة إلى الرئيسية'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3A86FF),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Future<void> _bookAppointment(DoctorModel doctor) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('لم يتم العثور على المستخدم');
      }

      // حفظ الحجز في Firestore
      await FirebaseFirestore.instance
          .collection('appointments')
          .add({
        'patientId': user.uid,
        'doctorId': doctor.id,
        'doctorName': doctor.fullName,
        'specialty': doctor.specialty,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'patientAge': widget.patientAge,
        'patientGender': widget.patientGender,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حجز موعد مع ${doctor.fullName} بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      // الانتقال للرئيسية بعد ثانية
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }
}
