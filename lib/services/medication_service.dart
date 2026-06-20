import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // لـ debugPrint
import 'package:digl/features/model.dart';

class MedicationService {
  final CollectionReference _medicationsCollection =
  FirebaseFirestore.instance.collection('medications');

  /// إضافة دواء
  Future<void> addMedication(Medication medication) async {
    try {
      await _medicationsCollection.doc(medication.id).set(medication.toMap());
    } catch (e) {
      debugPrint('Error adding medication: $e');
    }
  }

  /// جلب دواء محدد
  Future<Medication?> getMedication(String id) async {
    try {
      DocumentSnapshot doc = await _medicationsCollection.doc(id).get();
      if (doc.exists) {
        return Medication.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error getting medication: $e');
    }
    return null;
  }

  /// تحديث دواء
  Future<void> updateMedication(Medication medication) async {
    try {
      await _medicationsCollection.doc(medication.id).update(medication.toMap());
    } catch (e) {
      debugPrint('Error updating medication: $e');
    }
  }

  /// حذف دواء
  Future<void> deleteMedication(String id) async {
    try {
      await _medicationsCollection.doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting medication: $e');
    }
  }

  /// جلب أدوية المستخدم الحالي فقط
  Stream<List<Medication>> getMedications() {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Stream<List<Medication>>.empty();
    }

    return _medicationsCollection
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      // ترتيب الأدوية محلياً حسب التاريخ
      final medications = snapshot.docs.map((doc) {
        return Medication.fromFirestore(doc);
      }).toList();

      medications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return medications;
    });
  }
}
