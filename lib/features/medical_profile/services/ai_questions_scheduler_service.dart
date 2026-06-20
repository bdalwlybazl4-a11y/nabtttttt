import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🤖 خدمة التحكم في ظهور أسئلة الذكاء الاصطناعي
/// 
/// المسؤولة عن:
/// - تحديد متى يجب إعادة عرض الأسئلة للمريض
/// - حفظ تاريخ آخر ظهور للأسئلة
/// - التحقق من مرور 10 أيام للعودة للأسئلة
class AiQuestionsSchedulerService {
  static const String _lastShownKey = 'ai_questions_last_shown';
  static const int _daysBetweenQuestions = 10;
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔍 التحقق من ما إذا كان يجب عرض الأسئلة للمريض
  /// 
  /// تعود بـ true إذا:
  /// 1. لم يكمل المريض الأسئلة مطلقاً (أول مرة)
  /// 2. مرّ 10 أيام على آخر ظهور للأسئلة
  static Future<bool> shouldShowAiQuestions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // جلب بيانات المستخدم من Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      final aiTestCompleted = userData['ai_test_completed'] as bool? ?? false;

      // 1️⃣ إذا لم يكمل الاختبار مطلقاً، اعرض الأسئلة
      if (!aiTestCompleted) {
        return true;
      }

      // 2️⃣ تحقق من آخر ظهور
      var lastShownTime = await _getLastShownTime(user.uid);
      if (lastShownTime == null) {
        // إذا لم يوجد تاريخ، استخدم تاريخ إكمال الاختبار
        final completedAt = userData['ai_test_completed_at'] as Timestamp?;
        if (completedAt == null) return true;
        
        lastShownTime = completedAt.toDate();
      }

      // 3️⃣ تحقق من مرور 10 أيام
      final daysPassed = DateTime.now().difference(lastShownTime).inDays;
      return daysPassed >= _daysBetweenQuestions;
    } catch (e) {
      print('⚠️ خطأ في التحقق من ظهور الأسئلة: $e');
      return false;
    }
  }

  /// 💾 حفظ وقت ظهور الأسئلة
  /// 
  /// يتم استدعاؤها عندما تظهر الأسئلة للمريض
  static Future<void> saveQuestionsShownTime() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();

      // 1️⃣ حفظ في SharedPreferences (محلياً للسرعة)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastShownKey, now.toIso8601String());

      // 2️⃣ حفظ في Firestore (للمزامنة)
      await _firestore.collection('users').doc(user.uid).update({
        'ai_questions_last_shown_at': FieldValue.serverTimestamp(),
      });

      print('✅ تم حفظ وقت ظهور الأسئلة: $now');
    } catch (e) {
      print('⚠️ خطأ في حفظ وقت الأسئلة: $e');
    }
  }

  /// ✅ وضع علامة على إكمال الأسئلة (استبدال الطريقة القديمة)
  /// 
  /// يتم استدعاؤها عند إكمال المريض للأسئلة
  static Future<void> markAiQuestionsAsCompleted() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'ai_test_completed': true,
        'ai_test_completed_at': FieldValue.serverTimestamp(),
        'ai_questions_last_shown_at': FieldValue.serverTimestamp(),
      });

      // احفظ محلياً أيضاً
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastShownKey, DateTime.now().toIso8601String());

      print('✅ تم وضع علامة على إكمال الأسئلة');
    } catch (e) {
      print('⚠️ خطأ في وضع علامة الإكمال: $e');
    }
  }

  /// 🔔 وضع علامة على إظهار الأسئلة (بدون إكمال)
  /// 
  /// يتم استدعاؤها عند الدخول إلى شاشة الأسئلة
  static Future<void> markAiQuestionsAsShown() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // احفظ محلياً فقط عند الإظهار (بدون تعليق التوقيت)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastShownKey, DateTime.now().toIso8601String());

      // حدّث في Firebase أيضاً
      await _firestore.collection('users').doc(user.uid).update({
        'ai_questions_last_shown_at': FieldValue.serverTimestamp(),
      }).catchError((_) {
        // تجاهل الأخطاء في هذه الحالة
      });

      print('✅ تم تسجيل إظهار الأسئلة');
    } catch (e) {
      print('⚠️ خطأ في تسجيل الإظهار: $e');
    }
  }

  /// 📅 الحصول على آخر وقت ظهور للأسئلة
  static Future<DateTime?> _getLastShownTime(String userId) async {
    try {
      // 1️⃣ جرب SharedPreferences أولاً (أسرع)
      final prefs = await SharedPreferences.getInstance();
      final localTime = prefs.getString(_lastShownKey);
      if (localTime != null) {
        return DateTime.tryParse(localTime);
      }

      // 2️⃣ جرب Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;

      final lastShown = userDoc['ai_questions_last_shown_at'] as Timestamp?;
      return lastShown?.toDate();
    } catch (e) {
      print('⚠️ خطأ في جلب آخر وقت ظهور: $e');
      return null;
    }
  }

  /// 📊 الحصول على معلومات تفصيلية عن حالة الأسئلة
  static Future<Map<String, dynamic>> getQuestionStatusInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return {};

      final userData = userDoc.data() as Map<String, dynamic>;
      final lastShown = await _getLastShownTime(user.uid);

      return {
        'ai_test_completed': userData['ai_test_completed'] ?? false,
        'ai_test_completed_at': userData['ai_test_completed_at'],
        'ai_questions_last_shown_at': userData['ai_questions_last_shown_at'],
        'last_shown_local': lastShown,
        'days_since_last_shown': lastShown != null 
            ? DateTime.now().difference(lastShown).inDays 
            : null,
        'days_until_next_shown': lastShown != null
            ? _daysBetweenQuestions - DateTime.now().difference(lastShown).inDays
            : 0,
      };
    } catch (e) {
      print('⚠️ خطأ في جلب معلومات الحالة: $e');
      return {};
    }
  }

  /// 🧹 مسح الذاكرة المحلية (اختياري)
  static Future<void> clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastShownKey);
      print('✅ تم مسح ذاكرة الأسئلة المحلية');
    } catch (e) {
      print('⚠️ خطأ في مسح الذاكرة: $e');
    }
  }
}
