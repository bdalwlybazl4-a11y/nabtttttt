import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorRatingService {
  DoctorRatingService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  Future<void> submitRating({required String doctorId, required String patientId, required double rating, String? comment, String? appointmentId}) async {
    if (rating < 1 || rating > 5) throw ArgumentError('التقييم يجب أن يكون بين 1 و 5');
    final ref = _firestore.collection('users').doc(doctorId).collection('ratings').doc(patientId);
    await ref.set({
      'rating': rating,
      'comment': comment ?? '',
      'patientId': patientId,
      'appointmentId': appointmentId ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await recalculateDoctorRating(doctorId);
  }

  Future<void> recalculateDoctorRating(String doctorId) async {
    final snapshot = await _firestore.collection('users').doc(doctorId).collection('ratings').get();
    final count = snapshot.docs.length;
    final total = snapshot.docs.fold<double>(0, (sum, doc) => sum + ((doc.data()['rating'] as num?)?.toDouble() ?? 0));
    await _firestore.collection('users').doc(doctorId).set({
      'rating': count == 0 ? 0.0 : total / count,
      'reviewCount': count,
      'consultationCount': count,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
