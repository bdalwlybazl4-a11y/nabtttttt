import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digl/features/admin/models/admin_models.dart';

/// خدمة إنشاء حساب الأدمن التلقائي عند بدء التطبيق لأول مرة
/// 🔐 Auto Admin Setup Service - يتم تشغيلها مرة واحدة فقط عند أول بدء للتطبيق
class AdminSetupService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ بيانات الأدمن الافتراضية (يمكن تعديلها حسب الحاجة)
  static const String _defaultAdminEmail = 'admin@gmail.com';
  static const String _defaultAdminPassword = 'admin@gmail.com'; // كلمة مرور قوية
  static const String _defaultAdminName = 'مدير النظام';
  static const String _defaultAdminPhone = '781268448';

  /// ✅ دالة التحقق من وجود أدمن والإنشاء التلقائي إذا لم يكن موجود
  /// هذه الدالة يجب أن تُستدعى مرة واحدة عند بدء التطبيق
  static Future<bool> ensureAdminExists() async {
    try {
      print('🔍 جاري التحقق من وجود حساب الأدمن...');

      // 1️⃣ التحقق من وجود أدمن في Firestore
      final adminSnapshot = await _firestore
          .collection('admins')
          .where('role', isEqualTo: 'super_admin')
          .limit(1)
          .get();

      if (adminSnapshot.docs.isNotEmpty) {
        print('✅ تم العثور على حساب أدمن موجود');
        return true; // الأدمن موجود بالفعل
      }

      print('⚠️ لم يتم العثور على حساب أدمن، جاري الإنشاء...');

      // 2️⃣ إنشاء حساب الأدمن في Firebase Authentication
      final adminCredential = await _auth.createUserWithEmailAndPassword(
        email: _defaultAdminEmail,
        password: _defaultAdminPassword,
      );

      if (adminCredential.user == null) {
        throw Exception('فشل في إنشاء حساب Authentication للأدمن');
      }

      final adminUid = adminCredential.user!.uid;
      print('✅ تم إنشاء حساب Firebase للأدمن: $adminUid');

      // 3️⃣ إنشاء مستند الأدمن في Firestore
      final adminData = {
        'id': adminUid,
        'email': _defaultAdminEmail,
        'fullName': _defaultAdminName,
        'role': 'super_admin', // أعلى درجة صلاحيات
        'phoneNumber': _defaultAdminPhone,
        'profileImage': '', // يمكن إضافة صورة افتراضية
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'permissions': [
          'manage_doctors', // إدارة طلبات الأطباء
          'manage_admins', // إدارة حسابات الأدمن الأخرى
          'view_analytics', // عرض الإحصائيات
          'manage_users', // إدارة حسابات المستخدمين
          'manage_medications', // إدارة الأدوية
          'manage_health_data', // إدارة البيانات الصحية
          'system_settings', // إعدادات النظام
        ],
      };

      await _firestore.collection('admins').doc(adminUid).set(adminData);
      print('✅ تم إنشاء مستند الأدمن في Firestore');

      // 4️⃣ إضافة سجل عن إنشاء الأدمن
      await _firestore.collection('admin_setup_logs').add({
        'action': 'create_initial_admin',
        'adminEmail': _defaultAdminEmail,
        'adminUid': adminUid,
        'timestamp': FieldValue.serverTimestamp(),
        'appVersion': '1.0.0',
      });

      print('✅ تم تسجيل عملية إنشاء الأدمن بنجاح');

      // 5️⃣ تسجيل الخروج من حساب الأدمن (لا نريد أن يبقى مسجل الدخول)
      // حتى لا يؤثر على تدفق تسجيل المستخدم العادي
      await _auth.signOut();
      print('✅ تم تسجيل خروج الأدمن تحضيراً لتسجيل المستخدم العادي');

      return true;
    } on FirebaseAuthException catch (e) {
      // ✅ معالجة الأخطاء المتعلقة بـ Firebase Authentication
      if (e.code == 'email-already-in-use') {
        print('⚠️ بريد الأدمن الافتراضي مستخدم بالفعل (يمكن أن يكون من محاولة سابقة)');
        // محاولة تسجيل الدخول بدلاً من الإنشاء
        try {
          await _auth.signInWithEmailAndPassword(
            email: _defaultAdminEmail,
            password: _defaultAdminPassword,
          );
          await _auth.signOut();
          return true;
        } catch (signInError) {
          print('❌ فشل في التحقق من حساب الأدمن الموجود: $signInError');
          return false;
        }
      } else {
        print('❌ خطأ Firebase: ${e.message}');
        return false;
      }
    } catch (e) {
      print('❌ خطأ غير متوقع: $e');
      return false;
    }
  }

  /// ✅ دالة للتحقق من أن المستخدم الحالي هو أدمن
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
      return adminDoc.exists && (adminDoc.data()?['isActive'] ?? false);
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// ✅ دالة للتحقق من أن المستخدم لديه صلاحية معينة
  static Future<bool> hasPermission(String permission) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
      if (!adminDoc.exists) return false;

      final permissions = List<String>.from(adminDoc.data()?['permissions'] ?? []);
      return permissions.contains(permission);
    } catch (e) {
      print('Error checking permission: $e');
      return false;
    }
  }

  /// ✅ دالة لإضافة صلاحية إلى الأدمن
  static Future<void> addPermissionToAdmin(String adminId, String permission) async {
    try {
      final adminDoc = await _firestore.collection('admins').doc(adminId).get();
      if (!adminDoc.exists) throw Exception('الأدمن غير موجود');

      final permissions = List<String>.from(adminDoc.data()?['permissions'] ?? []);
      if (!permissions.contains(permission)) {
        permissions.add(permission);
        await _firestore.collection('admins').doc(adminId).update({
          'permissions': permissions,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ تم إضافة الصلاحية: $permission للأدمن');
      }
    } catch (e) {
      print('Error adding permission: $e');
    }
  }

  /// ✅ دالة لحذف صلاحية من الأدمن
  static Future<void> removePermissionFromAdmin(
    String adminId,
    String permission,
  ) async {
    try {
      final adminDoc = await _firestore.collection('admins').doc(adminId).get();
      if (!adminDoc.exists) throw Exception('الأدمن غير موجود');

      final permissions = List<String>.from(adminDoc.data()?['permissions'] ?? []);
      permissions.remove(permission);
      await _firestore.collection('admins').doc(adminId).update({
        'permissions': permissions,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ تم حذف الصلاحية: $permission من الأدمن');
    } catch (e) {
      print('Error removing permission: $e');
    }
  }

  /// ✅ دالة لتفعيل/تعطيل حساب الأدمن
  static Future<void> toggleAdminStatus(String adminId, bool isActive) async {
    try {
      await _firestore.collection('admins').doc(adminId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final status = isActive ? 'مُفعّل' : 'مُعطّل';
      print('✅ تم تغيير حالة الأدمن إلى: $status');
    } catch (e) {
      print('Error toggling admin status: $e');
    }
  }

  /// ✅ دالة لتغيير كلمة مرور الأدمن
  static Future<bool> changeAdminPassword(
    String adminEmail,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // إعادة التحقق من الهوية باستخدام كلمة المرور الحالية
      final credential = EmailAuthProvider.credential(
        email: adminEmail,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // تحديث كلمة المرور
      await user.updatePassword(newPassword);

      // تسجيل هذا الإجراء
      await _firestore.collection('admin_activity_logs').add({
        'adminId': user.uid,
        'action': 'change_password',
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('✅ تم تغيير كلمة المرور بنجاح');
      return true;
    } catch (e) {
      print('❌ خطأ في تغيير كلمة المرور: $e');
      return false;
    }
  }
}
