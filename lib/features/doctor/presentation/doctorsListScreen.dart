import 'package:digl/features/doctor/presentation/pages/doctor_profil_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/notification_service.dart';
import '../../consultations/presentation/pages/consultation_screen.dart';
import '../../model.dart';

class DoctorsListScreen extends StatefulWidget {
  const DoctorsListScreen({super.key});
  @override
  State<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends State<DoctorsListScreen>{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _selectedSpecialty;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final List<String> _specialties = ['الكل','القلب','الأسنان','العيون','الباطنة','الجلدية','العظام'];

  @override
  Widget build(BuildContext context) {
    final doctorsStream = FirebaseFirestore.instance
        .collection('users')
        .where('accountType', isEqualTo: 'doctor')
        .where('isVerified', isEqualTo: true)
        .snapshots();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode? Colors.grey[900]: Colors.white,
        foregroundColor: Colors.blue,
        elevation: 2,
        title: Text("شاشة عرض جميع الاطباء"),
      ),

      body: _buildDoctorsSelection(),

      // StreamBuilder<QuerySnapshot>(
      //   stream: doctorsStream,
      //   builder: (context, snapshot) {
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return const Center(child: CircularProgressIndicator());
      //     }
      //
      //     if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      //       return const Center(child: Text('لا يوجد أطباء متاحين'));
      //     }
      //
      //     final docs = snapshot.data!.docs;
      //
      //     return ListView.builder(
      //       scrollDirection: Axis.vertical,
      //       padding: const EdgeInsets.symmetric(horizontal: 12),
      //       itemCount: docs.length,
      //       itemBuilder: (context, index) {
      //         final userModel = UserModel.fromFirestore(docs[index]);
      //
      //         return DoctorCard(
      //           user: userModel,
      //           onTap: () {
      //             Navigator.push(
      //               context,
      //               MaterialPageRoute(
      //                 builder: (_) => DoctorProfileScreen(user: userModel),
      //               ),
      //             );
      //           },
      //         );
      //       },
      //     );
      //   },
      // ),
    );
  }

  Widget _buildDoctorsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('accountType', isEqualTo: 'doctor')
          .where('isVerified', isEqualTo: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('لا يوجد أطباء متاحين حالياً'));
        final doctors = docs.map((d) => UserModel.fromFirestore(d))
            .where((dr) =>
        (_selectedSpecialty == null || dr.specialtyName == _selectedSpecialty) &&
            dr.fullName.toLowerCase().contains(_searchQuery)
        ).toList();
        if (doctors.isEmpty) return const Center(child: Text('لا توجد نتائج مطابقة للبحث'));
        return ListView.builder(
          itemCount: doctors.length,
          itemBuilder: (ctx, i) => _buildDoctorCard(doctors[i]),
        );
      },
    );
  }

  Widget _buildDoctorCard(UserModel doctor) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: (doctor.photoURL != null && doctor.photoURL!.isNotEmpty)
              ? NetworkImage(doctor.photoURL!)
              : const AssetImage('assets/images/doctor_placeholder.png') as ImageProvider,
          // child: (doctor.photoURL == null || doctor.photoURL!.isEmpty)
          //     ? const Icon(Icons.person, size: 20, color: Colors.white)
          //     : null,
        ),
        title: Text(
          doctor.fullName.isNotEmpty ? doctor.fullName : 'اسم غير متوفر',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doctor.specialtyName ?? 'تخصص عام'),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('${doctor.rating?.toStringAsFixed(1) ?? '5.0'} (${doctor.consultationCount ?? 0})'),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => _startConsultation(doctor),
          child: const Text('استشارة'),
        ),
      ),
    );
  }


  Future<void> _startConsultation(UserModel doctor) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final userDataDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDataDoc.data() ?? {};
      // جلب الاستشارات الحالية للمستخدم
      final existing = await _firestore
          .collection('consultations')
          .where('userId', isEqualTo: user.uid)
          .get();

      // البحث عن الاستشارة مع الطبيب محلياً
      var matchingConsultation;
      for (var doc in existing.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['doctorId'] == doctor.uid &&
            data['type'] == 'instant' &&
            data['isActive'] == true) {
          matchingConsultation = doc;
          break;
        }
      }

      if (matchingConsultation != null) {
        final data = matchingConsultation.data() as Map<String, dynamic>;
        Navigator.push(context, MaterialPageRoute(builder: (_) =>
            ConsultationScreen(
              consultationId: matchingConsultation.id,
              doctorUid: data['doctorId'] ?? '',
              patientUid: data['userId'] ?? '',
              doctorName: userData['doctorName'] ?? '',
              patientName: userData['userName'] ?? '',
              doctorImage: data['doctorImage'] ?? '',
              userImage: data['userImage'] ?? '',
              isDoctor: false,
            ),
        ));
        return;
      }

      final userFcmToken = await NotificationService().getDeviceToken();
      final consultationRef = await _firestore.collection('consultations').add({
        'type': 'instant',
        'doctorId': doctor.uid,
        'doctorName': doctor.fullName,
        'doctorImage': doctor.photoURL,
        'doctorFcmToken': doctor.fcmToken,
        'userId': user.uid,
        'userName': userData['fullName'] ?? (user.displayName ?? 'مستخدم'),
        'userImage': userData['profilePicture'] ?? user.photoURL,
        'userFcmToken': userFcmToken,
        'specialty': doctor.specialtyName,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'isActive': true,
        'seenBy': [user.uid],
        'hasNewMessage': false,
      });

      if (doctor.fcmToken != null) {
        await _sendNotification(
          token: doctor.fcmToken!,
          title: 'استشارة جديدة',
          body: 'لديك استشارة جديدة من ${userData['fullName'] ?? user.displayName}',
          consultationId: consultationRef.id,
          recipientUserId: doctor.uid,
        );
      }

      Navigator.push(context, MaterialPageRoute(builder: (_) =>
          ConsultationScreen(
            consultationId: consultationRef.id,
            doctorUid: userData['doctorId'] ?? '',
            patientUid: userData['userId'] ?? '',
            doctorName: userData['doctorName'] ?? '',
            patientName: userData['userName'] ?? '',
            doctorImage: doctor.photoURL ?? '',
            userImage: userData['photoURL'] ?? user.photoURL ?? '',
            isDoctor: false,
          ),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل: ${e.toString()}')));
    }
  }

  Widget _buildDoctorsSelection() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
            children: [
          Container(
            width: 110,
            child: DropdownButtonFormField<String>(
              value: _selectedSpecialty ?? 'الكل',
              items: _specialties.map((sp) =>
                  DropdownMenuItem(value: sp, child: Text(sp))).toList(),
              onChanged: (value) =>
                  setState(() =>
                  _selectedSpecialty = (value == 'الكل' ? null : value)),
              decoration: const InputDecoration(
                  labelText: 'اختر التخصص', border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(width: 5),

          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن طبيب...',
                prefixIcon: const Icon(Icons.search, color: Colors.blue,),
                border: const OutlineInputBorder(),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                })
                    : null,
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),

        ]),
      ),
      Expanded(child: _buildDoctorsList()),
    ]
    );
  }

  Future<void> _sendNotification({
    required String token,
    required String title,
    required String body,
    required String consultationId,
    required String recipientUserId,
  }) async {
    await _firestore.collection('notifications').add({
      'to': token,
      'userId': recipientUserId,
      'title': title,
      'body': body,
      'consultationId': consultationId,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'message',
    });
  }
}


class DoctorCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const DoctorCard({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = user.photoURL ;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 0),
            CircleAvatar(
              radius: 40,
              backgroundImage: imageUrl != null
                  ? NetworkImage(imageUrl)
                  : const AssetImage('assets/images/doctor_placeholder.png') as ImageProvider,
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 4),
                  Text(
                    user.displaySpecialty,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.orange[400], size: 18),
                      const SizedBox(width: 4),
                      Text(
                        (user.rating ?? 0).toStringAsFixed(1),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
