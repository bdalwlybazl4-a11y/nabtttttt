import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digl/features/medical_profile/models/patient_symptoms_model.dart';

/// خدمة إدارة أعراض المريض
class PatientSymptomsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// إضافة أعراض جديدة للمريض
  static Future<String> addPatientSymptoms(PatientSymptoms symptoms) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مصرح');

      final symptomsWithUserId = symptoms.copyWith(
        patientId: user.uid,
      );

      // الحفظ في Firestore
      final docRef = await _firestore
          .collection('patients')
          .doc(user.uid)
          .collection('patient_symptoms')
          .add(symptomsWithUserId.toFirestore());

      print('✅ تم حفظ الأعراض بنجاح: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ خطأ في حفظ الأعراض: $e');
      rethrow;
    }
  }

  /// الحصول على آخر أعراض للمريض
  static Future<PatientSymptoms?> getLatestSymptoms() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final snapshot = await _firestore
          .collection('patients')
          .doc(user.uid)
          .collection('patient_symptoms')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return PatientSymptoms.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('❌ خطأ في جلب الأعراض: $e');
      return null;
    }
  }

  /// الحصول على جميع الأعراض للمريض
  static Future<List<PatientSymptoms>> getAllSymptoms() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('patients')
          .doc(user.uid)
          .collection('patient_symptoms')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PatientSymptoms.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ خطأ في جلب الأعراض: $e');
      return [];
    }
  }

  /// تحديث أعراض المريض
  static Future<void> updatePatientSymptoms(PatientSymptoms symptoms) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مصرح');

      await _firestore
          .collection('patients')
          .doc(user.uid)
          .collection('patient_symptoms')
          .doc(symptoms.id)
          .update(symptoms.toFirestore());

      print('✅ تم تحديث الأعراض بنجاح');
    } catch (e) {
      print('❌ خطأ في تحديث الأعراض: $e');
      rethrow;
    }
  }

  /// حذف أعراض المريض
  static Future<void> deletePatientSymptoms(String symptomsId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مصرح');

      await _firestore
          .collection('patients')
          .doc(user.uid)
          .collection('patient_symptoms')
          .doc(symptomsId)
          .delete();

      print('✅ تم حذف الأعراض بنجاح');
    } catch (e) {
      print('❌ خطأ في حذف الأعراض: $e');
      rethrow;
    }
  }

  /// التحقق من وجود أعراض للمريض
  static Future<bool> hasSymptoms() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final snapshot = await _firestore
          .collection('patients')
          .doc(user.uid)
          .collection('patient_symptoms')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ خطأ في التحقق من الأعراض: $e');
      return false;
    }
  }
}
