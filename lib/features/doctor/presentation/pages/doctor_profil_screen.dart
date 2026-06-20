import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../../consultations/presentation/pages/consultation_screen.dart';
import '../../../model.dart';

class DoctorProfileScreen extends StatelessWidget {
  final UserModel user;

  const DoctorProfileScreen({super.key, required this.user});

  Future<void> submitUserRating({
    required String doctorId,
    required String userId,
    required double rating,
  }) async {
    final ratingRef = FirebaseFirestore.instance
        .collection('users')
        .doc(doctorId)
        .collection('ratings')
        .doc(userId);

    await ratingRef.set({'rating': rating});
    await updateDoctorAverageRating(doctorId);
  }

  Future<void> updateDoctorAverageRating(String doctorId) async {
    final ratingsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(doctorId)
        .collection('ratings')
        .get();

    if (ratingsSnapshot.docs.isEmpty) return;

    double total = 0;
    for (var doc in ratingsSnapshot.docs) {
      total += (doc['rating'] as num).toDouble();
    }

    final average = total / ratingsSnapshot.docs.length;

    await FirebaseFirestore.instance.collection('users').doc(doctorId).update({
      'rating': average,
      'consultationCount': ratingsSnapshot.docs.length,
    });
  }

  // دالة لبدء الاستشارة مع الطبيب
  Future<void> _startConsultation(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول لبدء الاستشارة')),
      );
      return;
    }

    try {
      final userDataDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final userData = userDataDoc.data() ?? {};

      // التحقق من وجود استشارة نشطة حالياً
      final existingConsultation = await FirebaseFirestore.instance
          .collection('consultations')
          .where('userId', isEqualTo: currentUser.uid)
          .where('doctorId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'instant')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      String consultationId;

      if (existingConsultation.docs.isNotEmpty) {
        // استخدام الاستشارة الموجودة
        consultationId = existingConsultation.docs.first.id;
      } else {
        // إنشاء استشارة جديدة
        final consultationRef = await FirebaseFirestore.instance
            .collection('consultations')
            .add({
          'type': 'instant',
          'doctorId': user.uid,
          'doctorName': user.fullName,
          'doctorImage': user.photoURL,
          'doctorFcmToken': user.fcmToken,
          'userId': currentUser.uid,
          'userName': userData['fullName'] ?? (currentUser.displayName ?? 'مستخدم'),
          'userImage': userData['profilePicture'] ?? currentUser.photoURL,
          'specialty': user.specialtyName,
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageTime': FieldValue.serverTimestamp(),
          'status': 'pending',
          'isActive': true,
          'seenBy': [currentUser.uid],
          'hasNewMessage': false,
          'newMessageFor': null,
          'unreadCount': {
            currentUser.uid: 0,
            user.uid: 0
          },
        });
        consultationId = consultationRef.id;
      }

      // الانتقال إلى شاشة المحادثة
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConsultationScreen(
            consultationId: consultationId,
            doctorUid: user.uid,
            patientUid: currentUser.uid,
            doctorName: user.fullName,
            patientName: userData['fullName'] ?? (currentUser.displayName ?? 'مستخدم'),
            doctorImage: user.photoURL ?? '',
            userImage: userData['photoURL'] ?? currentUser.photoURL ?? '',
            isDoctor: false,
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في بدء الاستشارة: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = user.photoURL;
    final workplaces = user.workplaces;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(user.fullName),
        centerTitle: true,
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        foregroundColor: Colors.blue,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          Container(color: Theme.of(context).colorScheme.background),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 80),
                CircleAvatar(
                  radius: 60,
                  backgroundImage: imageUrl != null
                      ? NetworkImage(imageUrl)
                      : const AssetImage('assets/images/doctor_placeholder.png')
                  as ImageProvider,
                ),
                const SizedBox(height: 16),
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
                Text(
                  user.displaySpecialty,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      user.isOnline == true
                          ? Icons.circle
                          : Icons.circle_outlined,
                      color: user.isOnline == true
                          ? Colors.greenAccent
                          : Colors.grey,
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      user.isOnline == true ? 'متصل الآن' : 'غير متصل',
                      style: const TextStyle(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                /// ✅ معلومات الطبيب الحية
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final data =
                    snapshot.data!.data() as Map<String, dynamic>;

                    return _buildGlassInfoCardFromLiveData(
                      rating: (data['rating'] ?? 0).toDouble(),
                      consultationCount:
                      (data['consultationCount'] ?? 0).toInt(),
                      licenseNumber: data['licenseNumber'],
                      phone: data['phone'],
                      isAvailable: data['isAvailable'] == true,
                    );
                  },
                ),
                const SizedBox(height: 20),

                // أماكن العمل
                if (workplaces != null && workplaces.isNotEmpty)
                  ...workplaces.map((place) {
                    final workplace = Workplace.fromMap(place);
                    return _buildWorkplaceCard(workplace, context);
                  }).toList(),

                const SizedBox(height: 20),

                // أزرار الإجراءات
                _buildActionButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // واجهة أزرار الإجراءات
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // زر بدء الاستشارة
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startConsultation(context),
            icon: const Icon(Icons.chat, size: 24),
            label: const Text(
              "بدء الاستشارة",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 3,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // زر تقييم الطبيب
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showRatingDialog(context),
            icon: const Icon(Icons.star_rate, size: 24),
            label: const Text(
              "قيّم الطبيب",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassInfoCardFromLiveData({
    required double rating,
    required int consultationCount,
    String? licenseNumber,
    String? phone,
    required bool isAvailable,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white30),
          ),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                      Icons.star, 'التقييم', '${rating.toStringAsFixed(1)} / 5'),
                  const SizedBox(height: 4),
                  RatingBarIndicator(
                    rating: rating,
                    itemBuilder: (context, _) =>
                    const Icon(Icons.star, color: Colors.amber),
                    itemCount: 5,
                    itemSize: 24,
                    unratedColor: Colors.grey[300],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildInfoRow(Icons.chat, 'عدد الاستشارات', '$consultationCount'),
              if (licenseNumber != null) ...[
                const SizedBox(height: 10),
                _buildInfoRow(
                    Icons.verified_user, 'رقم الترخيص', licenseNumber),
              ],
              if (phone != null) ...[
                const SizedBox(height: 10),
                _buildInfoRow(Icons.phone, 'رقم الهاتف', phone),
              ],
              const SizedBox(height: 10),
              _buildInfoRow(
                isAvailable ? Icons.check_circle : Icons.cancel,
                'الحالة',
                isAvailable ? 'متاح للاستشارة' : 'غير متاح حالياً',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[900], size: 20),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkplaceCard(Workplace workplace, BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      color: isDarkMode ? Colors.grey[800] : Colors.white.withOpacity(0.9),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: const Icon(Icons.location_on, color: Colors.blueAccent),
        title:
        Text(workplace.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          workplace.formattedWorkingHours,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext parentContext) {
    double _currentRating = 3.0;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(content: Text("يجب تسجيل الدخول لتقييم الطبيب")),
      );
      return;
    }

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('قيّم الطبيب'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBar.builder(
                initialRating: _currentRating,
                minRating: 1,
                allowHalfRating: true,
                itemCount: 5,
                unratedColor: Colors.grey[300],
                itemBuilder: (context, _) =>
                const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) => setState(() => _currentRating = rating),
              ),
              const SizedBox(height: 12),
              Text('التقييم الحالي: ${_currentRating.toStringAsFixed(1)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              await submitUserRating(
                doctorId: user.uid,
                userId: currentUserId,
                rating: _currentRating,
              );

              ScaffoldMessenger.of(parentContext).showSnackBar(
                const SnackBar(content: Text('تم إرسال التقييم بنجاح')),
              );
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }
}