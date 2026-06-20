import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة إدارة منطق ظهور أسئلة الذكاء الاصطناعي
/// تتحكم في: الظهور الأول بعد التسجيل، إعادة الظهور كل 10 أيام
class AiQuestionsService {
  static const String _lastAiQuestionsKey = 'ai_questions_last_shown';
  static const Duration _appearanceInterval = Duration(days: 10);

  /// التحقق من هل يجب عرض أسئلة الذكاء الاصطناعي
  /// 1. عرض مباشر بعد إنشاء الحساب (ai_test_completed = false)
  /// 2. إعادة عرض بعد 10 أيام من آخر ظهور
  static Future<bool> shouldShowAiQuestions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // جلب بيانات المستخدم
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      final aiTestCompleted = userData['ai_test_completed'] as bool? ?? false;

      // الحالة الأولى: لم يكمل الاختبار بعد (ظهور مباشر)
      if (!aiTestCompleted) {
        return true;
      }

      // الحالة الثانية: تحقق إذا مضى 10 أيام
      return await _shouldShowAgainAfterDays();
    } catch (e) {
      print('❌ خطأ في التحقق من أسئلة الذكاء الاصطناعي: $e');
      return false;
    }
  }

  /// التحقق من هل مضى 10 أيام منذ آخر ظهور
  static Future<bool> _shouldShowAgainAfterDays() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      final lastShown = userData['ai_test_last_shown'] as Timestamp?;

      if (lastShown == null) {
        // إذا لم يحفظ تاريخ آخر ظهور، عرّض الأسئلة
        return true;
      }

      final lastShownDate = lastShown.toDate();
      final now = DateTime.now();
      final daysDifference = now.difference(lastShownDate).inDays;

      // إذا مضى 10 أيام أو أكثر
      return daysDifference >= _appearanceInterval.inDays;
    } catch (e) {
      print('❌ خطأ في التحقق من تاريخ آخر ظهور: $e');
      return false;
    }
  }

  /// حفظ تاريخ ظهور أسئلة الذكاء الاصطناعي
  static Future<void> saveAiQuestionsCompletion() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل دخول');

      // حفظ في Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'ai_test_completed': true,
        'ai_test_completed_at': FieldValue.serverTimestamp(),
        'ai_test_last_shown': FieldValue.serverTimestamp(),
      });

      // حفظ محلي (SharedPreferences) للتحقق السريع
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _lastAiQuestionsKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      print('✅ تم حفظ تاريخ ظهور أسئلة الذكاء الاصطناعي بنجاح');
    } catch (e) {
      print('❌ خطأ في حفظ تاريخ ظهور أسئلة الذكاء الاصطناعي: $e');
      rethrow;
    }
  }

  /// الحصول على معلومات الظهور الأخير (للتطوير والاختبار)
  static Future<Map<String, dynamic>> getAiQuestionsInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {};

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return {};

      final userData = userDoc.data() as Map<String, dynamic>;

      return {
        'ai_test_completed': userData['ai_test_completed'] ?? false,
        'ai_test_completed_at': userData['ai_test_completed_at'],
        'ai_test_last_shown': userData['ai_test_last_shown'],
        'should_show': await shouldShowAiQuestions(),
      };
    } catch (e) {
      print('❌ خطأ في جلب معلومات أسئلة الذكاء الاصطناعي: $e');
      return {};
    }
  }

  /// إعادة تعيين حالة أسئلة الذكاء الاصطناعي (للاختبار)
  static Future<void> resetAiQuestionsForDebug() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'ai_test_completed': false,
        'ai_test_completed_at': FieldValue.delete(),
        'ai_test_last_shown': FieldValue.delete(),
      });

      print('🔄 تم إعادة تعيين أسئلة الذكاء الاصطناعي');
    } catch (e) {
      print('❌ خطأ في إعادة تعيين أسئلة الذكاء الاصطناعي: $e');
    }
  }
}
