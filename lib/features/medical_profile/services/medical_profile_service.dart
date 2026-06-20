import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// خدمة للتحقق من الملف الصحي للمريض
class MedicalProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// التحقق من وجود ملف صحي للمريض
  static Future<bool> hasHealthProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final snapshot = await _firestore
          .collection('patients')
          .doc(user.uid)
          .collection('medical_profile')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking health profile: $e');
      return false;
    }
  }

  /// الحصول على آخر ملف صحي للمريض
  static Future<DocumentSnapshot?> getLatestHealthProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final snapshot = await _firestore
          .collection('patients')
          .doc(user.uid)
          .collection('medical_profile')
          .get();

      if (snapshot.docs.isEmpty) return null;

      // الحصول على أحدث ملف صحي محلياً
      snapshot.docs.sort((a, b) {
        final aCreatedAt = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
        final bCreatedAt = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
        return bCreatedAt.compareTo(aCreatedAt);
      });

      return snapshot.docs.first;
    } catch (e) {
      print('Error getting health profile: $e');
      return null;
    }
  }

  /// التحقق من كون المريض قد أكمل ملفه الصحي في هذا اليوم
  static Future<bool> hasCompletedTodayProfile() async {
    try {
      final profile = await getLatestHealthProfile();
      if (profile == null) return false;

      final data = profile.data() as Map<String, dynamic>;
      final createdAt = (data['createdAt'] as Timestamp).toDate();
      final today = DateTime.now();

      return createdAt.year == today.year &&
          createdAt.month == today.month &&
          createdAt.day == today.day;
    } catch (e) {
      print('Error checking today profile: $e');
      return false;
    }
  }
}
