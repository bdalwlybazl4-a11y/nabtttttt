import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🔐 خدمة إدارة صلاحيات المستخدم (Patient vs Doctor)
/// تتحقق من نوع حساب المستخدم والصلاحيات المتاحة له
class UserRoleService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ أنواع الحسابات المتاحة
  static const String ROLE_PATIENT = 'patient';
  static const String ROLE_DOCTOR = 'doctor';

  // ✅ الصلاحيات المتاحة للأطباء فقط
  static const List<String> doctorOnlyPermissions = [
    'add_medication',
    'prescribe_medicine',
    'view_patient_reports',
    'manage_appointments',
    'add_medical_news',
  ];

  /// ✅ دالة للحصول على نوع حساب المستخدم الحالي
  /// تعيد 'patient' أو 'doctor'
  static Future<String?> getUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) return null;

      return doc.get('accountType') as String?;
    } catch (e) {
      print('❌ خطأ في الحصول على نوع الحساب: $e');
      return null;
    }
  }

  /// ✅ دالة للتحقق من أن المستخدم هو دكتور
  static Future<bool> isDoctor() async {
    final role = await getUserRole();
    return role == ROLE_DOCTOR;
  }

  /// ✅ دالة للتحقق من أن المستخدم هو مريض
  static Future<bool> isPatient() async {
    final role = await getUserRole();
    return role == ROLE_PATIENT;
  }

  /// ✅ دالة للتحقق من وجود صلاحية معينة
  static Future<bool> hasPermission(String permission) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final role = await getUserRole();
      
      // إذا كان المستخدم دكتور، يجب أن يكون حسابه موافقاً عليه قبل منحه الصلاحيات
      if (role == ROLE_DOCTOR) {
        if (!doctorOnlyPermissions.contains(permission)) return false;
        return isDoctorVerified();
      }

      return false;
    } catch (e) {
      print('❌ خطأ في التحقق من الصلاحية: $e');
      return false;
    }
  }

  /// ✅ دالة للتحقق من صلاحية إضافة الأدوية
  static Future<bool> canAddMedication() async {
    return hasPermission('add_medication');
  }

  /// ✅ دالة للتحقق من صلاحية وصف الأدوية
  static Future<bool> canPrescribeMedicine() async {
    return hasPermission('prescribe_medicine');
  }

  /// ✅ دالة للتحقق من صلاحية عرض تقارير المريض
  static Future<bool> canViewPatientReports() async {
    return hasPermission('view_patient_reports');
  }

  /// ✅ دالة للتحقق من صلاحية إضافة أخبار طبية
  static Future<bool> canAddMedicalNews() async {
    return hasPermission('add_medical_news');
  }

  /// ✅ دالة للحصول على بيانات المستخدم كاملة
  static Future<Map<String, dynamic>?> getUserFullData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) return null;

      return doc.data();
    } catch (e) {
      print('❌ خطأ في الحصول على بيانات المستخدم: $e');
      return null;
    }
  }

  /// ✅ دالة لتحديث نوع حساب المستخدم (للاستخدام الإداري فقط)
  static Future<void> updateUserRole(String userId, String newRole) async {
    try {
      if (newRole != ROLE_PATIENT && newRole != ROLE_DOCTOR) {
        throw Exception('نوع حساب غير صحيح');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .update({'accountType': newRole});

      print('✅ تم تحديث نوع الحساب إلى: $newRole');
    } catch (e) {
      print('❌ خطأ في تحديث نوع الحساب: $e');
      rethrow;
    }
  }

  /// ✅ دالة للحصول على معلومات إضافية للدكتور
  static Future<Map<String, dynamic>?> getDoctorInfo() async {
    try {
      final isDoc = await isDoctor();
      if (!isDoc) return null;

      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) return null;

      final data = doc.data()!;
      return {
        'specialty': data['specialty'],
        'licenseNumber': data['licenseNumber'],
        'experience': data['yearsOfExperience'],
        'rating': data['rating'] ?? 0.0,
        'isVerified': data['isVerified'] ?? false,
      };
    } catch (e) {
      print('❌ خطأ في الحصول على بيانات الدكتور: $e');
      return null;
    }
  }

  /// ✅ دالة للتحقق من تحقق الدكتور (Verified)
  static Future<bool> isDoctorVerified() async {
    try {
      final isDoc = await isDoctor();
      if (!isDoc) return false;

      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;

      final data = doc.data() ?? {};
      final status = (data['verificationStatus'] ?? data['doctorRequestStatus'] ?? data['accountStatus'] ?? '').toString().toLowerCase();
      return data['isVerified'] == true && (status.isEmpty || status == 'approved');
    } catch (e) {
      print('❌ خطأ في التحقق من حالة الدكتور: $e');
      return false;
    }
  }
}
