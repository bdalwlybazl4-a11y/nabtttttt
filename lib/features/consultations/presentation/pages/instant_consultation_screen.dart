import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'consultation_screen.dart';
import '../../../../core/config/presenceService.dart';
import '../../../../core/config/medical_theme.dart';
import '../../../../services/notification_service.dart';
import 'package:digl/features/model.dart';
import 'groupConsultationScreen.dart';

class InstantConsultationScreen extends StatefulWidget {
  const InstantConsultationScreen({super.key});

  @override
  State<InstantConsultationScreen> createState() => _InstantConsultationScreenState();
}

class _InstantConsultationScreenState extends State<InstantConsultationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _selectedSpecialty;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final List<String> _specialties = ['الكل','القلب','الأسنان','العيون','الباطنة','الجلدية','العظام'];
  String? accountType;

  @override
  void initState() {
    super.initState();
    _setupPresence();
    _loadAccountType();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _setupPresence() async {
    await PresenceService().setOnline();
  }

  Future<void> _loadAccountType() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      setState(() {
        accountType = userDoc.data()!['accountType'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (accountType == null) {
      return Scaffold(backgroundColor: Theme.of(context).scaffoldBackgroundColor, body: const Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        title: const Text('الاستشارة الفورية'),
      ),
      body: accountType == 'doctor'
          ? _buildPatientConsultations()
          : _buildPatientConsultationsForUser(),
      floatingActionButton: FloatingActionButton(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: colorScheme.primary,
        onPressed: (){
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const GroupConsultationScreen(),
            ),
          );
        },
        tooltip: 'الاستشارة الجماعية',
        child: Icon(Icons.group, color: colorScheme.onPrimary),
      ),
    );
  }

  Widget _buildDoctorsSelection() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث عن طبيب...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              })
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedSpecialty ?? 'الكل',
            items: _specialties.map((sp) => DropdownMenuItem(value: sp, child: Text(sp))).toList(),
            onChanged: (value) =>
                setState(() => _selectedSpecialty = (value == 'الكل' ? null : value)),
            decoration: const InputDecoration(labelText: 'اختر التخصص', border: OutlineInputBorder()),
          ),
        ]),
      ),
      Expanded(child: _buildDoctorsList()),
    ]);
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      color: theme.cardColor,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: theme.dividerColor.withOpacity(0.25))),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: doctor.photoURL != null
              ? NetworkImage(doctor.photoURL!)
              : const AssetImage('assets/images/doctor_placeholder.png') as ImageProvider,
        ),
        title: Text(doctor.fullName, style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(doctor.specialtyName ?? 'تخصص عام', style: TextStyle(color: colorScheme.onSurface.withOpacity(.64))),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text('${doctor.rating?.toStringAsFixed(1) ?? '5.0'} (${doctor.consultationCount ?? 0})'),
          ]),
        ]),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: MedicalTheme.pure,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _startConsultation(doctor),
          child: const Text('استشارة'),
        ),
      ),
    );
  }

  Widget _buildConsultationsWithSearch({required Widget child}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: accountType == 'doctor'
                  ? 'ابحث عن مريض أو تخصص...'
                  : 'ابحث عن طبيب أو تخصص...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  List<QueryDocumentSnapshot> _filterConsultationDocs(
    List<QueryDocumentSnapshot> docs, {
    required bool isDoctor,
  }) {
    if (_searchQuery.isEmpty) return docs;

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (isDoctor ? data['userName'] : data['doctorName'])?.toString().toLowerCase() ?? '';
      final specialty = data['specialty']?.toString().toLowerCase() ?? '';
      final lastMessage = data['lastMessage']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery) ||
          specialty.contains(_searchQuery) ||
          lastMessage.contains(_searchQuery);
    }).toList();
  }

  /// قائمة المرضى للطبيب مع عرض عدد الرسائل الجديدة
  /// قائمة المرضى للطبيب مع تشخيص مفصل
  Widget _buildPatientConsultations() {
    final doctor = _auth.currentUser;
    if (doctor == null) {
      return const Center(child: Text('لم يتم التعرف على المستخدم'));
    }

    print('🎯 [تشخيص] جاري تحميل استشارات الطبيب: ${doctor.uid}');
    print('🎯 [تشخيص] اسم الطبيب: ${doctor.displayName}');

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('consultations')
          .where('doctorId', isEqualTo: doctor.uid)
          .where('type', isEqualTo: 'instant')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (ctx, snap) {
        // حالة التحميل
        if (snap.connectionState == ConnectionState.waiting) {
          print('⏳ [تشخيص] جاري تحميل البيانات...');
          return const Center(child: CircularProgressIndicator());
        }

        // حالة الخطأ
        if (snap.hasError) {
          print('❌ [تشخيص] خطأ في الاستعلام: ${snap.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: MedicalTheme.dangerRed, size: 50),
                SizedBox(height: 16),
                Text('خطأ في تحميل البيانات'),
                SizedBox(height: 8),
                Text(
                  '${snap.error}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // حالة عدم وجود بيانات
        if (!snap.hasData) {
          print('📭 [تشخيص] لا توجد بيانات مستلمة');
          return const Center(child: Text('لا توجد بيانات'));
        }

        var docs = snap.data!.docs;
        // فرز محلياً حسب lastMessageTime (الأحدث أولاً)
        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['lastMessageTime'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['lastMessageTime'] as Timestamp?;
          return (bTime?.toDate() ?? DateTime(1970)).compareTo(aTime?.toDate() ?? DateTime(1970));
        });
        print('📊 [تشخيص] عدد الاستشارات المستلمة: ${docs.length}');

        // عرض البيانات المستلمة للتشخيص
        for (var i = 0; i < docs.length; i++) {
          final data = docs[i].data() as Map<String, dynamic>;
          print('🔍 [تشخيص] استشارة ${i + 1}:');
          print('   - ID: ${docs[i].id}');
          print('   - doctorId: ${data['doctorId']}');
          print('   - userId: ${data['userId']}');
          print('   - userName: ${data['userName']}');
          print('   - type: ${data['type']}');
          print('   - isActive: ${data['isActive']}');
          print('   - lastMessageTime: ${data['lastMessageTime']}');
        }

        if (docs.isEmpty) {
          return _buildConsultationsWithSearch(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا يوجد مرضى حاليًا'),
                  SizedBox(height: 8),
                  Text(
                    'سيظهر المرضى هنا عندما يبدأون استشارة معك',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        docs = _filterConsultationDocs(docs, isDoctor: true);
        if (docs.isEmpty) {
          return _buildConsultationsWithSearch(
            child: const Center(child: Text('لا توجد نتائج مطابقة للبحث')),
          );
        }

        return _buildConsultationsWithSearch(
          child: ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            try {
              final consultation = ConsultationModel.fromFirestore(docs[i]);
              final unreadCount = consultation.getUnreadCountForUser(doctor.uid);
              final hasNewMessages = consultation.hasNewMessagesForUser(doctor.uid);

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(consultation.userId).get(),
                builder: (context, snapshot) {
                  String? userPhoto = consultation.userImage;
                  String userName = consultation.userName ?? 'مريض';

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final userData = snapshot.data!.data() as Map<String, dynamic>;
                    userPhoto = userData['photoURL'] ?? userPhoto;
                    userName = userData['fullName'] ?? userName;
                  } else if (snapshot.hasError) {
                    print('❌ [تشخيص] خطأ في تحميل بيانات المستخدم: ${snapshot.error}');
                  }

                  return _buildConsultationItem(
                    consultation: consultation,
                    userPhoto: userPhoto,
                    userName: userName,
                    unreadCount: unreadCount,
                    hasNewMessages: hasNewMessages,
                    currentUserId: doctor.uid,
                    isDoctor: true,
                  );
                },
              );
            } catch (e) {
              print('❌ [تشخيص] خطأ في معالجة الاستشارة: $e');
              return Card(
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                color: Colors.orange[50],
                child: ListTile(
                  leading: Icon(Icons.error, color: Colors.orange),
                  title: Text('خطأ في تحميل البيانات'),
                  subtitle: Text('$e'),
                ),
              );
            }
          },
        ),
        );
      },
    );
  }

  /// قائمة الاستشارات للمريض مع عرض عدد الرسائل الجديدة
  Widget _buildPatientConsultationsForUser() {
    final user = _auth.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('consultations')
          .where('userId', isEqualTo: user!.uid)
          .where('type', isEqualTo: 'instant')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snap.data!.docs;

        // فرز محلياً حسب lastMessageTime (الأحدث أولاً)
        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['lastMessageTime'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['lastMessageTime'] as Timestamp?;
          return (bTime?.toDate() ?? DateTime(1970)).compareTo(aTime?.toDate() ?? DateTime(1970));
        });

        if (docs.isEmpty) {
          return _buildConsultationsWithSearch(
            child: const Center(child: Text('لا يوجد استشارات حالياً')),
          );
        }

        docs = _filterConsultationDocs(docs, isDoctor: false);
        if (docs.isEmpty) {
          return _buildConsultationsWithSearch(
            child: const Center(child: Text('لا توجد نتائج مطابقة للبحث')),
          );
        }

        return _buildConsultationsWithSearch(
          child: ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final consultation = ConsultationModel.fromFirestore(docs[i]);
            final unreadCount = consultation.getUnreadCountForUser(user.uid);
            final hasNewMessages = consultation.hasNewMessagesForUser(user.uid);

            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(consultation.doctorId).get(),
              builder: (context, snapshot) {
                String? doctorPhoto = consultation.doctorImage;
                String doctorName = consultation.doctorName ?? 'طبيب';

                if (snapshot.hasData && snapshot.data!.exists) {
                  final doctorData = snapshot.data!.data() as Map<String, dynamic>;
                  doctorPhoto = doctorData['photoURL'] ?? doctorPhoto;
                  doctorName = doctorData['fullName'] ?? doctorName;
                }

                return _buildConsultationItem(
                  consultation: consultation,
                  userPhoto: doctorPhoto,
                  userName: doctorName,
                  unreadCount: unreadCount,
                  hasNewMessages: hasNewMessages,
                  currentUserId: user.uid,
                  isDoctor: false,
                );
              },
            );
          },
        ),
        );
      },
    );
  }

  /// واجهة عنصر الاستشارة المشتركة
  Widget _buildConsultationItem({
    required ConsultationModel consultation,
    required String? userPhoto,
    required String userName,
    required int unreadCount,
    required bool hasNewMessages,
    required String currentUserId,
    required bool isDoctor,
  }) {
    // استخدام StreamBuilder للحصول على العدد المحدث
    return StreamBuilder<int>(
      stream: _getUnreadMessagesCount(consultation.id, currentUserId),
      builder: (context, countSnapshot) {
        final actualUnreadCount = countSnapshot.data ?? unreadCount;
        final shouldShowBadge = actualUnreadCount > 0 || hasNewMessages;

        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: (userPhoto != null && userPhoto.isNotEmpty)
                    ? NetworkImage(userPhoto)
                    : const AssetImage('assets/images/doctor_placeholder.png') as ImageProvider,
              ),
              if (shouldShowBadge)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: MedicalTheme.dangerRed,
                      shape: BoxShape.circle,
                      border: Border.all(color: MedicalTheme.pure, width: 2),
                    ),
                    child: Text(
                      actualUnreadCount > 99 ? '99+' : actualUnreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(child: Text(userName)),
              // if (actualUnreadCount > 0)
              //   Container(
              //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              //     decoration: BoxDecoration(
              //       color: Colors.red,
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //     child: Text(
              //       actualUnreadCount.toString(),
              //       style: const TextStyle(
              //         color: Colors.white,
              //         fontSize: 12,
              //         fontWeight: FontWeight.bold,
              //       ),
              //     ),
              //   ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(consultation.specialty ?? ''),
              if (actualUnreadCount > 0)
                Text(
                  '$actualUnreadCount رسالة جديدة',
                  style: const TextStyle(
                    color: MedicalTheme.infoBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              if (consultation.lastMessageTime != null)
                Text(
                  _formatTime(consultation.lastMessageTime!),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
          trailing: const Icon(Icons.chat),
          onTap: () {
            _openConsultation(consultation, currentUserId);
          },
          onLongPress: () => _showConsultationActions(consultation, userName),
        );
      },
    );
  }

  void _showConsultationActions(ConsultationModel consultation, String displayName) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('حذف المحادثة بالكامل'),
              subtitle: Text(displayName),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteConsultation(consultation.id, displayName);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteConsultation(String consultationId, String displayName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المحادثة'),
        content: Text('هل تريد حذف محادثة $displayName وجميع رسائلها من قاعدة البيانات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _deleteConsultationCompletely(consultationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف المحادثة بالكامل')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل حذف المحادثة: $e'),
          backgroundColor: MedicalTheme.dangerRed,
        ),
      );
    }
  }

  Future<void> _deleteConsultationCompletely(String consultationId) async {
    final consultationRef = _firestore.collection('consultations').doc(consultationId);

    while (true) {
      final messages = await consultationRef.collection('messages').limit(400).get();
      if (messages.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final message in messages.docs) {
        batch.delete(message.reference);
      }
      await batch.commit();
    }

    final notifications = await _firestore
        .collection('notifications')
        .where('consultationId', isEqualTo: consultationId)
        .get();
    if (notifications.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final notification in notifications.docs) {
        batch.delete(notification.reference);
      }
      await batch.commit();
    }

    await consultationRef.delete();
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  // دالة للحصول على عدد الرسائل غير المقروءة
  Stream<int> _getUnreadMessagesCount(String consultationId, String userId) {
    return _firestore
        .collection('consultations')
        .doc(consultationId)
        .snapshots()
        .map((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return 0;

      final unreadCountMap = data['unreadCount'] as Map<String, dynamic>? ?? {};
      return unreadCountMap[userId] as int? ?? 0;
    });
  }

  Future<void> _openConsultation(ConsultationModel consultation, String currentUserId) async {
    // تحديث الحالة عند فتح المحادثة
    await _firestore.collection('consultations').doc(consultation.id).update({
      'hasNewMessage': false,
      'newMessageFor': null,
      'unreadCount.$currentUserId': 0,
      'seenBy': FieldValue.arrayUnion([currentUserId]),
    });

    Navigator.push(context, MaterialPageRoute(builder: (_) =>
        ConsultationScreen(
          consultationId: consultation.id,
          doctorUid: consultation.doctorId ?? '',
          patientUid: consultation.userId,
          doctorName: consultation.doctorName ?? '',
          patientName: consultation.userName ?? '',
          doctorImage: consultation.doctorImage ?? '',
          userImage: consultation.userImage ?? '',
          isDoctor: accountType == 'doctor',
        ),
    ));
  }

  Future<void> _startConsultation(UserModel doctor) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final userDataDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDataDoc.data() ?? {};

      // جلب الاستشارات حسب المستخدم فقط
      final existing = await _firestore
          .collection('consultations')
          .where('userId', isEqualTo: user.uid)
          .get();

      // فلترة محلياً لتجنب الحاجة لفهرس مركب
      QueryDocumentSnapshot<Map<String, dynamic>>? matchingConsultation;
      for (final doc in existing.docs) {
        final data = doc.data();
        if (data['doctorId'] == doctor.uid &&
            data['type'] == 'instant' &&
            data['isActive'] == true) {
          matchingConsultation = doc;
          break;
        }
      }

      if (matchingConsultation != null) {
        final consultation = ConsultationModel.fromFirestore(matchingConsultation);
        _openConsultation(consultation, user.uid);
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
        'lastMessageTime': FieldValue.serverTimestamp(),
        'status': 'pending',
        'isActive': true,
        'seenBy': [user.uid],
        'hasNewMessage': false,
        'newMessageFor': null,
        'unreadCount': {
          user.uid: 0,
          doctor.uid: 0
        },
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

      final newConsultation = ConsultationModel(
        id: consultationRef.id,
        type: 'instant',
        doctorId: doctor.uid,
        userId: user.uid,
        createdAt: Timestamp.now(),
        lastMessageTime: Timestamp.now(),
        doctorName: doctor.fullName,
        userName: userData['fullName'] ?? (user.displayName ?? 'مستخدم'),
        doctorImage: doctor.photoURL,
        userImage: userData['profilePicture'] ?? user.photoURL,
        specialty: doctor.specialtyName,
        unreadCount: {user.uid: 0, doctor.uid: 0},
      );

      _openConsultation(newConsultation, user.uid);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل: ${e.toString()}'),
          backgroundColor: MedicalTheme.dangerRed,
        ),
      );
    }
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