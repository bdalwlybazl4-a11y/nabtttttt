import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digl/features/admin/models/admin_models.dart';

/// خدمة إدارة النظام
class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// تسجيل دخول المسؤول
  static Future<AdminUser?> loginAdmin(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = userCredential.user;
      if (user == null) return null;

      final adminDoc =
      await _firestore.collection('admins').doc(user.uid).get();

      if (!adminDoc.exists) {
        await _auth.signOut();
        throw Exception('هذا الحساب ليس حساب مسؤول');
      }

      return AdminUser.fromFirestore(adminDoc);
    } catch (e) {
      print('Error logging in admin: $e');
      rethrow;
    }
  }

  /// تسجيل خروج المسؤول
  static Future<void> logoutAdmin() async {
    await _auth.signOut();
  }


  /// مراقبة حسابات الأطباء بشكل مباشر لتظهر طلبات التفعيل حتى إذا لم يتم إنشاء
  /// مستند مستقل داخل doctor_requests بسبب قواعد Firestore القديمة.
  static Stream<List<DoctorRequest>> watchDoctorRequests({String? status}) {
    return _firestore
        .collection('users')
        .where('accountType', isEqualTo: 'doctor')
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs
          .map((doc) => DoctorRequest.fromFirestore(doc))
          .where((request) => status == null || status == 'all' || request.status == status)
          .toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  /// جلب جميع طلبات الأطباء المعلقة
  static Future<List<DoctorRequest>> getPendingDoctorRequests() async {
    try {
      final snapshot = await _firestore
          .collection('doctor_requests')
          .where('status', isEqualTo: 'pending')
          .get();

      final requests = snapshot.docs
          .map((doc) => DoctorRequest.fromFirestore(doc))
          .toList();

      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    } catch (e) {
      print('Error fetching pending requests: $e');
      return [];
    }
  }

  /// جلب جميع طلبات الأطباء
  static Future<List<DoctorRequest>> getAllDoctorRequests(
      {String? status}) async {
    try {
      Query query = _firestore.collection('doctor_requests');

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();

      final requests = snapshot.docs
          .map((doc) => DoctorRequest.fromFirestore(doc))
          .toList();

      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    } catch (e) {
      print('Error fetching requests: $e');
      return [];
    }
  }

  /// جلب تفاصيل طلب معين
  static Future<DoctorRequest?> getDoctorRequest(String requestId) async {
    try {
      final doc = await _firestore
          .collection('doctor_requests')
          .doc(requestId)
          .get();

      if (!doc.exists) return null;
      return DoctorRequest.fromFirestore(doc);
    } catch (e) {
      print('Error fetching request: $e');
      return null;
    }
  }

  /// الموافقة على طلب الطبيب
  static Future<void> approveDoctorRequest(
      String requestId,
      String adminId,
      String adminName,
      ) async {
    try {
      final requestRef =
      _firestore.collection('doctor_requests').doc(requestId);

      var requestDoc = await requestRef.get();
      if (!requestDoc.exists) {
        requestDoc = await _firestore.collection('users').doc(requestId).get();
      }
      if (!requestDoc.exists) {
        throw Exception('الطلب غير موجود');
      }

      final request = DoctorRequest.fromFirestore(requestDoc);

      final batch = _firestore.batch();

      /// تحديث حالة الطلب (آمن)
      batch.set(requestRef, {
        'status': 'approved',
        'verificationStatus': 'approved',
        'doctorRequestStatus': 'approved',
        'accountStatus': 'Approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminId,
        'rejectionReason': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      /// تحديث حساب الطبيب والسماح له باستخدام صلاحيات الطبيب.
      batch.set(_firestore.collection('users').doc(request.doctorId), {
        'isVerified': true,
        'verificationStatus': 'approved',
        'doctorRequestStatus': 'approved',
        'accountStatus': 'Approved',
        'hasLicenseDocuments': true,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': adminId,
        'rejectedAt': null,
        'rejectedBy': null,
        'rejectionReason': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      /// تسجيل في السجل
      await _firestore.collection('admin_logs').add({
        'adminId': adminId,
        'adminName': adminName,
        'action': 'approve_doctor',
        'doctorId': request.doctorId,
        'doctorName': request.fullName,
        'requestId': requestId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error approving request: $e');
      rethrow;
    }
  }

  /// رفض طلب الطبيب
  static Future<void> rejectDoctorRequest(
      String requestId,
      String adminId,
      String adminName,
      String rejectionReason,
      ) async {
    try {
      final requestRef =
      _firestore.collection('doctor_requests').doc(requestId);

      var requestDoc = await requestRef.get();
      if (!requestDoc.exists) {
        requestDoc = await _firestore.collection('users').doc(requestId).get();
      }
      if (!requestDoc.exists) {
        throw Exception('الطلب غير موجود');
      }

      final request = DoctorRequest.fromFirestore(requestDoc);

      final batch = _firestore.batch();
      batch.set(requestRef, {
        'status': 'rejected',
        'verificationStatus': 'rejected',
        'doctorRequestStatus': 'rejected',
        'accountStatus': 'Rejected',
        'rejectionReason': rejectionReason,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      batch.set(_firestore.collection('users').doc(request.doctorId), {
        'isVerified': false,
        'verificationStatus': 'rejected',
        'doctorRequestStatus': 'rejected',
        'accountStatus': 'Rejected',
        'hasLicenseDocuments': false,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': adminId,
        'rejectionReason': rejectionReason,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      await _firestore.collection('admin_logs').add({
        'adminId': adminId,
        'adminName': adminName,
        'action': 'reject_doctor',
        'doctorId': request.doctorId,
        'doctorName': request.fullName,
        'requestId': requestId,
        'rejectionReason': rejectionReason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error rejecting request: $e');
      rethrow;
    }
  }


  /// إلغاء تفعيل طبيب تمت الموافقة عليه سابقاً دون حذف بياناته.
  static Future<void> deactivateDoctor(
    String doctorId,
    String adminId,
    String adminName,
    String reason,
  ) async {
    try {
      final doctorDoc = await _firestore.collection('users').doc(doctorId).get();
      if (!doctorDoc.exists) throw Exception('حساب الطبيب غير موجود');

      final doctorData = doctorDoc.data() ?? {};
      final doctorName = (doctorData['fullName'] ?? '').toString();
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(doctorId);
      final requestRef = _firestore.collection('doctor_requests').doc(doctorId);

      batch.set(userRef, {
        'isVerified': false,
        'verificationStatus': 'rejected',
        'doctorRequestStatus': 'rejected',
        'accountStatus': 'Rejected',
        'deactivatedAt': FieldValue.serverTimestamp(),
        'deactivatedBy': adminId,
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      batch.set(requestRef, {
        ...doctorData,
        'doctorId': doctorId,
        'status': 'rejected',
        'verificationStatus': 'rejected',
        'doctorRequestStatus': 'rejected',
        'accountStatus': 'Rejected',
        'rejectionReason': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      await _firestore.collection('admin_logs').add({
        'adminId': adminId,
        'adminName': adminName,
        'action': 'deactivate_doctor',
        'doctorId': doctorId,
        'doctorName': doctorName,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error deactivating doctor: $e');
      rethrow;
    }
  }

  /// حذف الطبيب من Firestore. لا يحذف حساب Firebase Auth لأن ذلك يتطلب Admin SDK.
  static Future<void> deleteDoctor(
    String doctorId,
    String adminId,
    String adminName,
  ) async {
    try {
      final doctorDoc = await _firestore.collection('users').doc(doctorId).get();
      final doctorData = doctorDoc.data() ?? {};
      final doctorName = (doctorData['fullName'] ?? '').toString();

      final batch = _firestore.batch();
      batch.delete(_firestore.collection('doctor_requests').doc(doctorId));
      batch.delete(_firestore.collection('users').doc(doctorId));
      await batch.commit();

      await _firestore.collection('admin_logs').add({
        'adminId': adminId,
        'adminName': adminName,
        'action': 'delete_doctor',
        'doctorId': doctorId,
        'doctorName': doctorName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error deleting doctor: $e');
      rethrow;
    }
  }


  /// إحصائيات مباشرة للواجهة الرئيسية حتى تتحدث الأرقام فور وصول/مراجعة الطلبات.
  static Stream<AdminStats> watchAdminStats() {
    return _firestore.collection('users').snapshots().asyncMap((usersSnapshot) async {
      try {
        var totalDoctors = 0;
        var pendingRequests = 0;
        var approvedDoctors = 0;
        var rejectedRequests = 0;
        var totalPatients = 0;
        final specialtyUsage = <String, int>{};
        var ratingSum = 0.0;
        var ratedDoctors = 0;

        for (final doc in usersSnapshot.docs) {
          final data = doc.data();
          final accountType = (data['accountType'] ?? '').toString();
          if (accountType == 'patient') totalPatients++;
          if (accountType != 'doctor') continue;

          totalDoctors++;
          final status = _doctorStatus(data);
          if (status == 'approved') {
            approvedDoctors++;
          } else if (status == 'rejected') {
            rejectedRequests++;
          } else {
            pendingRequests++;
          }

          final specialty = (data['specialtyName'] ?? data['specialty'] ?? 'غير محدد').toString();
          specialtyUsage[specialty] = (specialtyUsage[specialty] ?? 0) + 1;
          final rating = (data['rating'] as num?)?.toDouble() ?? 0;
          if (rating > 0) {
            ratingSum += rating;
            ratedDoctors++;
          }
        }

        final appointments = await _firestore.collection('appointments').count().get();
        final consultations = await _firestore.collection('consultations').count().get();
        final healthAssessments = await _firestore.collectionGroup('health_assessments').count().get();

        return AdminStats(
          totalDoctors: totalDoctors,
          pendingRequests: pendingRequests,
          approvedDoctors: approvedDoctors,
          rejectedRequests: rejectedRequests,
          totalPatients: totalPatients,
          totalAppointments: appointments.count ?? 0,
          averageDoctorRating: ratedDoctors == 0 ? 0 : ratingSum / ratedDoctors,
          totalConsultations: consultations.count ?? 0,
          totalHealthAssessments: healthAssessments.count ?? 0,
          topSpecialties: _topEntries(specialtyUsage),
          topDoctors: const {},
        );
      } catch (e) {
        print('Error watching stats: $e');
        return AdminStats(
          totalDoctors: 0,
          pendingRequests: 0,
          approvedDoctors: 0,
          rejectedRequests: 0,
          totalPatients: 0,
          totalAppointments: 0,
          averageDoctorRating: 0,
          totalConsultations: 0,
        );
      }
    });
  }

  /// جلب إحصائيات الإدارة من Firestore مع مؤشرات التقارير والتوصيات.
  static Future<AdminStats> getAdminStats() async {
    try {
      final doctors = await _firestore
          .collection('users')
          .where('accountType', isEqualTo: 'doctor')
          .count()
          .get();
      final patients = await _firestore
          .collection('users')
          .where('accountType', isEqualTo: 'patient')
          .count()
          .get();
      final appointments = await _firestore.collection('appointments').count().get();
      final consultations = await _firestore.collection('consultations').count().get();
      final healthAssessments = await _firestore.collectionGroup('health_assessments').count().get();

      final doctorSnapshot = await _firestore
          .collection('users')
          .where('accountType', isEqualTo: 'doctor')
          .get();
      final specialtyUsage = <String, int>{};
      var ratingSum = 0.0;
      var ratedDoctors = 0;
      var pendingRequests = 0;
      var approvedDoctors = 0;
      var rejectedRequests = 0;
      for (final doc in doctorSnapshot.docs) {
        final data = doc.data();
        final status = _doctorStatus(data);
        if (status == 'approved') {
          approvedDoctors++;
        } else if (status == 'rejected') {
          rejectedRequests++;
        } else {
          pendingRequests++;
        }

        final specialty = (data['specialtyName'] ?? data['specialty'] ?? 'غير محدد').toString();
        specialtyUsage[specialty] = (specialtyUsage[specialty] ?? 0) + 1;
        final rating = (data['rating'] as num?)?.toDouble() ?? 0;
        if (rating > 0) {
          ratingSum += rating;
          ratedDoctors++;
        }
      }

      final appointmentsSnapshot = await _firestore.collection('appointments').limit(500).get();
      final topDoctors = <String, int>{};
      final topSpecialties = <String, int>{...specialtyUsage};
      for (final doc in appointmentsSnapshot.docs) {
        final data = doc.data();
        final doctorName = (data['doctorName'] ?? data['doctorFullName'] ?? data['doctorId'] ?? 'غير محدد').toString();
        final specialty = (data['specialtyName'] ?? data['specialty'] ?? '').toString();
        topDoctors[doctorName] = (topDoctors[doctorName] ?? 0) + 1;
        if (specialty.isNotEmpty) topSpecialties[specialty] = (topSpecialties[specialty] ?? 0) + 1;
      }

      return AdminStats(
        totalDoctors: doctors.count ?? 0,
        pendingRequests: pendingRequests,
        approvedDoctors: approvedDoctors,
        rejectedRequests: rejectedRequests,
        totalPatients: patients.count ?? 0,
        totalAppointments: appointments.count ?? 0,
        averageDoctorRating: ratedDoctors == 0 ? 0 : ratingSum / ratedDoctors,
        totalConsultations: consultations.count ?? 0,
        totalHealthAssessments: healthAssessments.count ?? 0,
        topSpecialties: _topEntries(topSpecialties),
        topDoctors: _topEntries(topDoctors),
      );
    } catch (e) {
      print('Error fetching stats: $e');
      return AdminStats(
        totalDoctors: 0,
        pendingRequests: 0,
        approvedDoctors: 0,
        rejectedRequests: 0,
        totalPatients: 0,
        totalAppointments: 0,
        averageDoctorRating: 0,
        totalConsultations: 0,
      );
    }
  }


  static String _doctorStatus(Map<String, dynamic> data) {
    final rawStatus = (data['verificationStatus'] ??
            data['doctorRequestStatus'] ??
            data['accountStatus'] ??
            data['status'] ??
            (data['isVerified'] == true ? 'approved' : 'pending'))
        .toString()
        .trim()
        .toLowerCase();
    if (rawStatus == 'approved' || rawStatus == 'approve') return 'approved';
    if (rawStatus == 'rejected' || rawStatus == 'reject') return 'rejected';
    return 'pending';
  }

  static Map<String, int> _topEntries(Map<String, int> source, {int limit = 5}) {
    final entries = source.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries.take(limit));
  }

  /// سجل الأنشطة
  static Future<List<Map<String, dynamic>>> getAdminLogs(
      {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('admin_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching logs: $e');
      return [];
    }
  }

  /// البحث عن الطلبات
  static Future<List<DoctorRequest>> searchDoctorRequests(String query) async {
    try {
      final snapshot = await _firestore
          .collection('doctor_requests')
          .where('fullName', isGreaterThanOrEqualTo: query)
          .where('fullName', isLessThan: '$query\uf8ff')
          .get();

      return snapshot.docs
          .map((doc) => DoctorRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error searching requests: $e');
      return [];
    }
  }

  /// تحديث ملف المسؤول
  static Future<void> updateAdminProfile(
      String adminId,
      Map<String, dynamic> data,
      ) async {
    try {
      await _firestore
          .collection('admins')
          .doc(adminId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      print('Error updating admin profile: $e');
      rethrow;
    }
  }
}
