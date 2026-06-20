# نظام الثيمات الطبي الشامل

## 📋 نظرة عامة

تم تطوير نظام ثيمات متكامل وشامل يوفر:

✅ دعم الثيمين Light و Dark تلقائياً
✅ ألوان طبية احترافية وجذابة
✅ سهولة التخصيص والصيانة
✅ تطبيق موحد في جميع أنحاء التطبيق

## 🎨 الملفات الرئيسية

### 1. `medical_theme.dart`
ملف الثيمة الرئيسي يحتوي على:
- جميع الألوان الطبية الأساسية
- تعريفات Light Theme و Dark Theme الكاملة
- Helper functions للحصول على الألوان بناءً على الثيم الحالي

### 2. `theme_helper.dart`
ملف مساعد يوفر:
- Snackbar methods محسّنة للأخطاء والنجاح والتحذيرات
- Helper functions للألوان الشائعة
- دوال للتحقق من الثيم الحالي

## 🌈 الألوان الأساسية

### الألوان الطبية الأساسية
```
primaryMedicalBlue      #2E5CB8  (أزرق طبي)
primaryMedicalBlueDark  #1E3A8A  (أزرق داكن)
primaryMedicalBlueLight #6FA8DC  (أزرق فاتح)
secondaryMedicalGreen   #27AE60  (أخضر صحة)
tertiaryMedicalCyan     #17A2B8  (أزرق مائي)
```

### ألوان الحالات
```
successGreen      #27AE60  (نجاح)
warningOrange     #E67E22  (تحذير)
dangerRed         #E74C3C  (خطر)
infoBlue          #3498DB  (معلومات)
pendingYellow     #F39C12  (معلق)
```

### ألوان خاصة طبية
```
doctorPurple      #9B59B6  (الأطباء)
patientPink       #E91E63  (المرضى)
urgentCrimson     #C0392B  (حالات عاجلة)
stableGreen       #16A085  (حالة مستقرة)
```

## 📖 أمثلة الاستخدام

### استيراد الثيمة
```dart
import '../../core/config/medical_theme.dart';
import '../../core/config/theme_helper.dart';
```

### استخدام SnackBar
```dart
// الخطأ
ThemeHelper.showErrorSnackBar(context, 'حدث خطأ');

// النجاح
ThemeHelper.showSuccessSnackBar(context, 'تم بنجاح');

// التحذير
ThemeHelper.showWarningSnackBar(context, 'تحذير');

// المعلومات
ThemeHelper.showInfoSnackBar(context, 'معلومة');
```

### استخدام الألوان المخصصة
```dart
// للأطباء
Icon(Icons.medical_services, color: MedicalTheme.doctorPurple)

// للمرضى
Icon(Icons.person, color: MedicalTheme.patientPink)

// للحالات العاجلة
Icon(Icons.priority_high, color: MedicalTheme.urgentCrimson)

// للحالات المستقرة
Icon(Icons.check_circle, color: MedicalTheme.stableGreen)
```

### التعامل مع الثيمين
```dart
// الطريقة الأولى - استخدام Helper
Color textColor = ThemeHelper.getTextColor(context);
Color bgColor = ThemeHelper.getBackgroundColor(context);

// الطريقة الثانية - الفحص المباشر
bool isDark = ThemeHelper.isDarkMode(context);
Color color = isDark ? MedicalTheme.darkGray800 : MedicalTheme.pure;

// الطريقة الثالثة - استخدام getColor
Color customColor = ThemeHelper.getColor(
  context,
  MedicalTheme.pure,      // Light Mode
  MedicalTheme.darkGray800 // Dark Mode
);
```

## 🔧 الملفات المحدثة

### Doctor Module
- ✅ `lib/features/doctor/presentation/pages/doctor_dashboard_screen.dart`
- ✅ `lib/features/doctor/presentation/pages/doctor_appointments_screen.dart`
- ✅ `lib/features/doctor/dashboard/appointments_screen.dart`
- ✅ `lib/features/doctor/dashboard/bookings_screen.dart`

### Consultations Module
- ✅ `lib/features/consultations/presentation/pages/instant_consultation_screen.dart`
- ✅ `lib/features/consultations/presentation/pages/consultation_screen.dart`

### Main App
- ✅ `lib/main.dart`
- ✅ `lib/features/home/presentation/pages/home_screen.dart`

## 📝 نصائح مهمة

### 1. استخدام الثيمة الصحيحة
❌ تجنب الألوان الثابتة:
```dart
backgroundColor: Colors.white,
foregroundColor: Colors.blue,
```

✅ استخدم المتغيرات:
```dart
backgroundColor: MedicalTheme.pure,
foregroundColor: MedicalTheme.primaryMedicalBlue,
```

### 2. دعم الثيمين
❌ تجنب الألوان الثابتة في المنطق:
```dart
if (isDarkMode) {
  color = Colors.white;
} else {
  color = Colors.black;
}
```

✅ استخدم Helper Functions:
```dart
color = ThemeHelper.getTextColor(context);
```

### 3. الرسائل والإشعارات
❌ رسائل عادية:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('خطأ'))
);
```

✅ رسائل ملونة مخصصة:
```dart
ThemeHelper.showErrorSnackBar(context, 'خطأ');
```

### 4. الاتساق واللون
استخدم نفس الألوان:
- للأخطاء: `MedicalTheme.dangerRed`
- للنجاح: `MedicalTheme.successGreen`
- للتحذيرات: `MedicalTheme.warningOrange`
- للمعلومات: `MedicalTheme.infoBlue`
- للمعلق: `MedicalTheme.pendingYellow`

## 🎯 حالات الاستخدام الشائعة

### موعد معلق (جديد)
```dart
color: MedicalTheme.pendingYellow
icon: Icons.schedule
```

### موعد مؤكد (تم الحضور)
```dart
color: MedicalTheme.successGreen
icon: Icons.check_circle
```

### موعد ملغى
```dart
color: MedicalTheme.dangerRed
icon: Icons.cancel
```

### استشارة عاجلة
```dart
color: MedicalTheme.urgentCrimson
icon: Icons.priority_high
```

### طبيب أنلاين
```dart
color: MedicalTheme.doctorPurple
icon: Icons.medical_services
```

### مريض نشط
```dart
color: MedicalTheme.patientPink
icon: Icons.person_add
```

## 🔍 اختبار الثيمات

تأكد من اختبار التطبيق في:
1. **Light Mode** - الثيم الفاتح
2. **Dark Mode** - الثيم الداكن
3. **الحدود والتباين** - للوصولية
4. **جميع الأجهزة** - الهواتف والأجهزة اللوحية

## 🚀 الخطوات التالية

### لإضافة ملف جديد:
1. استيراد الثيمة:
```dart
import 'package:your_app/core/config/medical_theme.dart';
import 'package:your_app/core/config/theme_helper.dart';
```

2. استبدال الألوان الثابتة بمتغيرات الثيمة

3. استخدام ThemeHelper للرسائل

4. اختبار في الثيمين Light و Dark

## ❓ الأسئلة الشائعة

**س: كيف أضيف لون جديد؟**
ج: أضفه في `medical_theme.dart` في الفئة المناسبة

**س: كيف أستخدم لون مخصص بناءً على الثيم؟**
ج: استخدم:
```dart
color = ThemeHelper.getColor(context, lightColor, darkColor);
```

**س: ماذا أفعل إذا نسيت استيراد الثيمة؟**
ج: ستظهر أخطاء في الكود - أضف الاستيراد:
```dart
import 'package:your_app/core/config/medical_theme.dart';
```

## 📞 الدعم والمساعدة

لأي استفسار أو مشكلة:
1. راجع الأمثلة أعلاه
2. تحقق من الملفات المحدثة
3. راجع `THEME_USAGE_GUIDE.md` للمزيد من التفاصيل
