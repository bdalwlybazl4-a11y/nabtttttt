# ⚙️ تعليمات الإعداد الأولي لنظام الإدارة

## 🔧 الخطوات الأولى للإدارة

### 1️⃣ إنشاء حساب مسؤول في Firestore

أضف وثيقة جديدة في مجموعة `admins`:

```json
{
  "email": "admin@digl.com",
  "fullName": "محمد الإدارة",
  "role": "super_admin",
  "phoneNumber": "0501234567",
  "profileImage": "",
  "isActive": true,
  "createdAt": "2025-01-30T00:00:00Z",
  "updatedAt": "2025-01-30T00:00:00Z",
  "permissions": [
    "approve_doctors",
    "reject_doctors",
    "view_statistics",
    "view_logs",
    "manage_admins"
  ]
}
```

### 2️⃣ إنشاء حساب في Firebase Authentication

1. اذهب إلى Firebase Console
2. اختر مشروعك
3. اذهب إلى Authentication
4. اضغط Add User
5. ادخل:
   - البريد الإلكتروني: `admin@digl.com`
   - كلمة المرور: `Admin@123`
6. اضغط Create User

### 3️⃣ ربط حساب Firebase مع Firestore

تأكد من أن `uid` حساب Firebase متطابق مع `id` الوثيقة في `admins`

### 4️⃣ الوصول إلى لوحة التحكم

```
رابط الدخول: /admin
البريد الإلكتروني: admin@digl.com
كلمة المرور: Admin@123
```

---

## 📋 قائمة التحقق الأولى

- [ ] تم إنشاء حساب في Firebase Authentication
- [ ] تم إضافة وثيقة في مجموعة `admins`
- [ ] تم اختبار تسجيل الدخول
- [ ] تم عرض لوحة التحكم بنجاح
- [ ] تم عرض الطلبات المعلقة
- [ ] تم اختبار الموافقة على طلب
- [ ] تم اختبار رفض طلب

---

## 🧪 بيانات اختبار عينة

### حساب مسؤول للاختبار:

```
البريد الإلكتروني: admin@digl.com
كلمة المرور: Admin@123
الدور: مسؤول عام
```

### حساب طبيب للاختبار:

```
{
  "doctorId": "doctor_test_001",
  "fullName": "د. أحمد محمد علي",
  "email": "doctor@example.com",
  "phoneNumber": "0501234567",
  "specialty": "طبيب قلب",
  "medicalLicense": "https://example.com/license.pdf",
  "medicalDegree": "https://example.com/degree.pdf",
  "clinicName": "عيادة القلب المتقدمة",
  "clinicAddress": "الرياض - حي النخيل",
  "documentUrls": ["https://example.com/doc1.pdf"],
  "status": "pending",
  "createdAt": "2025-01-30T10:00:00Z",
  "yearsOfExperience": "10",
  "bio": "طبيب قلب متخصص مع خبرة 10 سنوات",
  "specialties": ["cardiology", "internal_medicine"],
  "rating": 4.5,
  "reviewCount": 25
}
```

---

## 🔐 قواعد الأمان (Firestore Rules)

أضف هذه القواعل إلى قواعد الأمان في Firestore:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // السماح للمسؤول بالوصول إلى ملفات الإدارة
    match /admins/{userId} {
      allow read, write: if request.auth.uid == userId || isAdmin(request.auth.uid);
    }
    
    // السماح بقراءة وكتابة طلبات الأطباء للمسؤولين فقط
    match /doctor_requests/{document=**} {
      allow read, write: if isAdmin(request.auth.uid);
    }
    
    // سجلات الإدارة
    match /admin_logs/{document=**} {
      allow read, write: if isAdmin(request.auth.uid);
    }
  }
  
  // دالة للتحقق من أن المستخدم مسؤول
  function isAdmin(uid) {
    return exists(/databases/$(database)/documents/admins/$(uid));
  }
}
```

---

## 📦 التبعيات المستخدمة

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  firebase_auth: ^4.0.0
  cloud_firestore: ^4.0.0
  firebase_core: ^2.0.0
  
  # هذه موجودة بالفعل في المشروع
```

---

## 🗂️ هيكل المجلدات

```
lib/features/admin/
├── models/
│   └── admin_models.dart
│       ├── AdminUser
│       ├── DoctorRequest
│       └── AdminStats
│
├── services/
│   └── admin_service.dart
│       ├── loginAdmin()
│       ├── logoutAdmin()
│       ├── getPendingDoctorRequests()
│       ├── approveDoctorRequest()
│       ├── rejectDoctorRequest()
│       ├── getAdminStats()
│       └── getAdminLogs()
│
├── presentation/
│   └── pages/
│       ├── admin_auth_gate.dart
│       │   └── دالة للتحقق من المصادقة والتوجيه
│       │
│       ├── admin_login_screen.dart
│       │   ├── حقل البريد الإلكتروني
│       │   ├── حقل كلمة المرور
│       │   └── زر تسجيل الدخول
│       │
│       ├── admin_dashboard_screen.dart
│       │   ├── بطاقة الترحيب
│       │   ├── شبكة الإحصائيات
│       │   ├── تنبيهات الطلبات المعلقة
│       │   ├── الإجراءات السريعة
│       │   ├── الإعدادات
│       │   └── Navigation Bar
│       │
│       ├── doctor_requests_screen.dart
│       │   ├── شريط التصفية
│       │   ├── قائمة الطلبات
│       │   └── حالة فارغة
│       │
│       └── doctor_request_details_screen.dart
│           ├── بطاقة الحالة
│           ├── البيانات الشخصية
│           ├── البيانات المهنية
│           ├── الوثائق
│           ├── زر الموافقة
│           └── زر الرفض
│
├── ADMIN_GUIDE.md
│   └── دليل شامل
│
└── SETUP.md
    └── تعليمات الإعداد
```

---

## 🚀 خطوات التشغيل

### الخطوة 1: الإعداد الأساسي
```bash
# 1. تأكد من تثبيت جميع التبعيات
flutter pub get

# 2. شغل التطبيق
flutter run
```

### الخطوة 2: إعداد Firestore
```
1. افتح Firebase Console
2. اذهب إلى Firestore Database
3. اضغط Create Database
4. اختر production mode
5. اختر منطقة قريبة
```

### الخطوة 3: إضافة المسؤول
```
1. اذهب إلى Authentication
2. اضغط Add User
3. أضف بيانات المسؤول
4. انسخ UID المستخدم
5. أضف وثيقة في admins/{uid}
```

### الخطوة 4: الاختبار
```
1. افتح التطبيق
2. اذهب إلى /admin
3. سجل دخول
4. جرب الميزات المختلفة
```

---

## 📊 الإحصائيات والتقارير

### البيانات المتاحة:
- إجمالي الأطباء
- الطلبات المعلقة
- الأطباء الموافق عليهم
- الطلبات المرفوضة
- إجمالي المرضى
- المواعيد الكلية
- متوسط التقييم
- الاستشارات

### طريقة الوصول:
```dart
final stats = await AdminService.getAdminStats();
print('إجمالي الأطباء: ${stats.totalDoctors}');
print('طلبات معلقة: ${stats.pendingRequests}');
```

---

## 🔔 التنبيهات والإشعارات

### التنبيهات الحالية:
- ✅ عدد الطلبات المعلقة في لوحة التحكم
- ✅ رسائل نجاح/فشل العمليات

### التنبيهات المستقبلية:
- 🔜 إشعارات عند استقبال طلب جديد
- 🔜 إشعارات البريد الإلكتروني
- 🔜 نبضات حية للطلبات

---

## 🎓 أمثلة الاستخدام

### مثال 1: تسجيل دخول المسؤول
```dart
try {
  final admin = await AdminService.loginAdmin(
    'admin@digl.com',
    'Admin@123'
  );
  
  if (admin != null) {
    print('تم تسجيل الدخول بنجاح: ${admin.fullName}');
    // الانتقال إلى لوحة التحكم
  }
} catch (e) {
  print('خطأ في تسجيل الدخول: $e');
}
```

### مثال 2: الموافقة على طلب
```dart
try {
  await AdminService.approveDoctorRequest(
    'request_id_123',
    'admin_uid',
    'محمد الإدارة'
  );
  
  print('تم الموافقة على الطلب');
} catch (e) {
  print('خطأ: $e');
}
```

### مثال 3: رفض طلب
```dart
try {
  await AdminService.rejectDoctorRequest(
    'request_id_123',
    'admin_uid',
    'محمد الإدارة',
    'الشهادات غير مكتملة'
  );
  
  print('تم رفض الطلب');
} catch (e) {
  print('خطأ: $e');
}
```

---

## 🐛 حل المشاكل الشائعة

### مشكلة: "خطأ في المصادقة"
**الحل:**
- تحقق من صحة البريد الإلكتروني
- تحقق من كلمة المرور
- تأكد من أن الحساب موجود في Firebase

### مشكلة: "لا توجد صلاحيات"
**الحل:**
- تحقق من قواعل الأمان في Firestore
- تأكد من أن المستخدم مدرج في مجموعة admins

### مشكلة: "الطلبات لا تظهر"
**الحل:**
- تحقق من وجود بيانات في doctor_requests
- تحقق من اتصال الإنترنت
- تحقق من قواعل الأمان

---

## 📞 طلب الدعم

للمشاكل التقنية:
- البريد: support@digl.com
- الهاتف: +966 XX XXX XXXX
- الموقع: www.digl.com/support

---

**آخر تحديث:** 2025-01-30
**الإصدار:** 1.0.0

