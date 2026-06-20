import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digl/features/model.dart';

class AppointmentService {
  final CollectionReference _appointmentsCollection =
  FirebaseFirestore.instance.collection('appointments');

  /// إضافة موعد جديد
  Future<void> addAppointment(Appointment appointment) async {
    try {
      await _appointmentsCollection.doc(appointment.id).set(appointment.toMap());
    } catch (e) {
      print('Error adding appointment: $e');
    }
  }

  /// الحصول على موعد واحد حسب الـ ID
  Future<Appointment?> getAppointment(String id) async {
    try {
      DocumentSnapshot doc = await _appointmentsCollection.doc(id).get();
      if (doc.exists) {
        return Appointment.fromFirestore(doc);
      }
    } catch (e) {
      print('Error getting appointment: $e');
    }
    return null;
  }

  /// الحصول على المواعيد حسب نوع المستخدم (طبيب أو مريض)
  Stream<List<Appointment>> getAppointments() async* {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      yield [];
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        yield [];
        return;
      }

      final accountType = userDoc['accountType'] as String?;
      Query query = _appointmentsCollection;

      if (accountType == 'doctor') {
        query = query.where('doctorId', isEqualTo: user.uid);
      } else {
        query = query.where('userId', isEqualTo: user.uid);
      }

      yield* query
          .snapshots()
          .map((snapshot) {
        final appointments = snapshot.docs
            .map((doc) => Appointment.fromFirestore(doc))
            .toList();

        // ترتيب المواعيد محلياً حسب التاريخ
        appointments.sort((a, b) => a.date.compareTo(b.date));

        return appointments;
      });
    } catch (e) {
      print('Error fetching appointments: $e');
      yield [];
    }
  }

  /// تعديل موعد موجود
  Future<void> updateAppointment(Appointment appointment) async {
    try {
      await _appointmentsCollection.doc(appointment.id).update(appointment.toMap());
    } catch (e) {
      print('Error updating appointment: $e');
    }
  }

  /// حذف موعد
  Future<void> deleteAppointment(String id) async {
    try {
      await _appointmentsCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting appointment: $e');
    }
  }
}
