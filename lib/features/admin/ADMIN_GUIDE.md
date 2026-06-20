# 🛡️ دليل نظام الإدارة الشامل

## 📋 نظرة عامة

نظام الإدارة المتكامل لتطبيق digl الصحي يوفر لوحة تحكم متقدمة وعصرية للمسؤولين لإدارة طلبات تسجيل الأطباء والتحكم الكامل بالنظام.

---

## 🚀 الوصول إلى لوحة الإدارة

### طريقة الوصول:
```
URL: /admin
أو الرابط المباشر: https://your-app.com/admin
```

### بيانات الدخول:
```
البريد الإلكتروني: (بريد المسؤول المسجل)
كلمة المرور: (كلمة المرور الخاصة به)
```

---

## 📂 هيكل المشروع

```
lib/features/admin/
├── models/
│   └── admin_models.dart          # نماذج البيانات
│
├── services/
│   └── admin_service.dart          # خدمات الإدارة
│
├── presentation/
│   └── pages/
│       ├── admin_auth_gate.dart          # بوابة المصادقة
│       ├── admin_login_screen.dart       # شاشة تسجيل الدخول
│       ├── admin_dashboard_screen.dart   # لوحة التحكم الرئيسية
│       ├── doctor_requests_screen.dart   # طلبات الأطباء
│       └── doctor_request_details_screen.dart  # تفاصيل الطلب
│
└── ADMIN_GUIDE.md                 # هذا الملف
```

---

## 🎯 المميزات الأساسية

### 1️⃣ **تسجيل دخول آمن**
- مصادقة عبر Firebase Authentication
- تشفير آمن لكلمات المرور
- تحقق من نوع الحساب (مسؤول فقط)

### 2️⃣ **لوحة التحكم الرئيسية**
- **إحصائيات فورية:**
  - إجمالي الأطباء
  - طلبات معلقة
  - أطباء موافق عليهم
  - إجمالي المرضى
  - المواعيد
  - متوسط التقييم

- **بطاقة التنبيهات:**
  - عدد الطلبات المعلقة
  - رابط سريع لعرض الطلبات

- **إجراءات سريعة:**
  - الطلبات
  - إضافة مسؤول (قريباً)
  - التقارير (قريباً)

### 3️⃣ **إدارة طلبات الأطباء**

#### عرض الطلبات:
- **تصفية حسب الحالة:**
  - قيد الانتظار (معلقة)
  - موافق عليها
  - مرفوضة
  - الكل

- **معلومات الطلب الأساسية:**
  - اسم الطبيب
  - التخصص
  - حالة الطلب
  - تاريخ الطلب

- **بحث وتصفية:**
  - بحث بالاسم
  - تصفية حسب الحالة
  - ترتيب حسب التاريخ

#### تفاصيل الطلب:

**1. البيانات الشخصية:**
- الاسم الكامل
- البريد الإلكتروني
- رقم الهاتف

**2. البيانات المهنية:**
- التخصص
- سنوات الخبرة
- اسم العيادة
- عنوان العيادة
- السيرة الذاتية

**3. الوثائق والإثباتات:**
- رخصة الممارسة الطبية
- شهادة التخرج
- وثائق إضافية

**4. الإجراءات:**
- الموافقة على الطلب ✅
- رفض الطلب مع ذكر السبب ❌

### 4️⃣ **الإعدادات والملف الشخصي**
- عرض معلومات الحساب
- تسجيل الخروج الآمن

---

## 💾 قاعدة البيانات (Firestore)

### 1. مجموعة `admins`
```
admins/{adminId}
├── email: string
├── fullName: string
├── role: string (super_admin, admin)
├── phoneNumber: string
├── profileImage: string
├── isActive: boolean
├── createdAt: timestamp
├── updatedAt: timestamp
└── permissions: array[string]
```

### 2. مجموعة `doctor_requests`
```
doctor_requests/{requestId}
├── doctorId: string
├── fullName: string
├── email: string
├── phoneNumber: string
├── specialty: string
├── medicalLicense: string
├── medicalDegree: string
├── clinicName: string
├── clinicAddress: string
├── documentUrls: array[string]
├── status: string (pending, approved, rejected)
├── rejectionReason: string
├── createdAt: timestamp
├── reviewedAt: timestamp
├── reviewedBy: string (adminId)
├── rating: number
├── reviewCount: number
├── bio: string
├── specialties: array[string]
└── yearsOfExperience: string
```

### 3. مجموعة `admin_logs`
```
admin_logs/{logId}
├── adminId: string
├── adminName: string
├── action: string (approve_doctor, reject_doctor, etc)
├── doctorId: string
├── doctorName: string
├── requestId: string
├── rejectionReason: string (if applicable)
└── timestamp: timestamp
```

---

## 🔐 الأمان والصلاحيات

### قواعد الأمان (Firestore):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // الأدمن فقط يمكنه الوصول
    match /admins/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    match /doctor_requests/{document=**} {
      allow read, write: if hasRole('admin');
    }
    
    match /admin_logs/{document=**} {
      allow read, write: if hasRole('admin');
    }
  }
  
  function hasRole(role) {
    return request.auth != null && 
           get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.role == role;
  }
}
```

---

## 🌐 الخدمات (AdminService)

### الوظائف الأساسية:

#### 1. المصادقة
```dart
// تسجيل دخول
AdminUser? admin = await AdminService.loginAdmin(email, password);

// تسجيل خروج
await AdminService.logoutAdmin();
```

#### 2. إدارة الطلبات
```dart
// جلب الطلبات المعلقة
List<DoctorRequest> pending = await AdminService.getPendingDoctorRequests();

// جلب جميع الطلبات (بتصفية اختيارية)
List<DoctorRequest> all = await AdminService.getAllDoctorRequests(status: 'pending');

// جلب تفاصيل طلب
DoctorRequest? request = await AdminService.getDoctorRequest(requestId);

// البحث
List<DoctorRequest> results = await AdminService.searchDoctorRequests(query);
```

#### 3. الموافقة والرفض
```dart
// الموافقة على طلب
await AdminService.approveDoctorRequest(requestId, adminId, adminName);

// رفض طلب
await AdminService.rejectDoctorRequest(requestId, adminId, adminName, reason);
```

#### 4. الإحصائيات
```dart
// جلب الإحصائيات
AdminStats stats = await AdminService.getAdminStats();

// السجلات
List<Map> logs = await AdminService.getAdminLogs(limit: 50);
```

---

## 🎨 التصميم والواجهة

### الألوان المستخدمة:
- **الأزرق الأساسي:** `#3A86FF` - عنوان رئيسي
- **الأزرق الفاتح:** `#4CC9F0` - تدرجات
- **الأخضر:** `Colors.green` - الموافقة
- **الأحمر:** `Colors.red` - الرفض/الخطأ
- **البرتقالي:** `Colors.orange` - التنبيهات
- **الأبيض:** `Colors.white` - خلفيات

### المكونات الرئيسية:
- **AppBar:** أزرق بتصميم عصري
- **Cards:** بظل خفيف وزوايا مستديرة
- **Buttons:** متدرج وملون حسب الحالة
- **Lists:** بتمرير سلس وتحديث فوري

---

## 📱 الشاشات بالتفصيل

### 1. شاشة تسجيل الدخول (`admin_login_screen.dart`)
```
┌─────────────────────────────┐
│   🔒 لوحة التحكم الإدارية  │
│    تسجيل دخول المسؤول      │
├─────────────────────────────┤
│ البريد الإلكتروني:         │
│ [_______@example.com_______]│
│                             │
│ كلمة المرور:               │
│ [_______________] 👁️      │
│                             │
│ [تسجيل الدخول] ✅          │
└─────────────────────────────┘
```

### 2. لوحة التحكم (`admin_dashboard_screen.dart`)
```
┌──────────────────────────────┐
│ لوحة التحكم الإدارية        │
├──────────────────────────────┤
│ مرحباً، اسم المسؤول 👋      │
├──────────────────────────────┤
│ ┌─────────┐ ┌─────────┐     │
│ │ أطباء  │ │ طلبات  │     │
│ │  100    │ │   5    │     │
│ └─────────┘ └─────────┘     │
│                             │
│ ⚠️ طلبات معلقة (5)        │
│ [عرض الطلبات]              │
│                             │
│ إجراءات سريعة:            │
│ [الطلبات] [إضافة] [تقارير]│
└──────────────────────────────┘
```

### 3. طلبات الأطباء (`doctor_requests_screen.dart`)
```
┌──────────────────────────────┐
│ [قيد الانتظار] [موافق عليها] │
├──────────────────────────────┤
│ 👤 اسم الطبيب              │
│    التخصص: طبيب قلب        │
│    🟠 قيد الانتظار        │
│    منذ 2 أيام             │
├──────────────────────────────┤
│ 👤 اسم الطبيب              │
│    التخصص: طبيب عام       │
│    🟢 موافق عليها         │
│    من شهر                  │
└──────────────────────────────┘
```

### 4. تفاصيل الطلب (`doctor_request_details_screen.dart`)
```
┌──────────────────────────────┐
│ ⏳ قيد الانتظار             │
├──────────────────────────────┤
│ البيانات الشخصية:         │
│ الاسم: أحمد محمد           │
│ الإيميل: ahmed@example.com │
│ الهاتف: 0501234567        │
├──────────────────────────────┤
│ البيانات المهنية:         │
│ التخصص: طبيب قلب          │
│ الخبرة: 10 سنوات         │
│ العيادة: عيادة القلب       │
├──────────────────────────────┤
│ الوثائق:                   │
│ ✅ رخصة الممارسة          │
│ ✅ شهادة التخرج           │
│ ✅ وثائق إضافية          │
├──────────────────────────────┤
│ [✅ الموافقة] [❌ الرفض]  │
└──────────────────────────────┘
```

---

## 🔄 سير العمل (Workflow)

```
1. الطبيب يتقدم بطلب تسجيل
   ↓
2. البيانات تُحفظ في doctor_requests (status: pending)
   ↓
3. المسؤول يدخل لوحة التحكم (/admin)
   ↓
4. يشاهد الطلبات المعلقة
   ↓
5. يفتح تفاصيل الطلب
   ↓
6. يراجع البيانات والوثائق
   ↓
7. يختار:
   ✅ الموافقة → يتحول الطبيب إلى verified
   ❌ الرفض → يكتب السبب ويتم تجميد الحساب
   ↓
8. يُسجل الإجراء في admin_logs
```

---

## 🧪 اختبار النظام

### بيانات اختبار:
```
المسؤول:
البريد: admin@digl.com
كلمة المرور: Admin@123

الطبيب:
البريد: doctor@example.com
التخصص: طبيب قلب
```

### خطوات الاختبار:
1. ادخل إلى `/admin`
2. سجل دخول ببيانات المسؤول
3. تصفح لوحة التحكم
4. اعرض الطلبات المعلقة
5. اختبر الموافقة والرفض

---

## 🐛 استكشاف الأخطاء

### المشكلة: لا تظهر الطلبات
**الحل:**
- تحقق من توفر البيانات في Firestore
- تحقق من قواعد الأمان
- تحقق من اتصال الإنترنت

### المشكلة: فشل تسجيل الدخول
**الحل:**
- تحقق من صحة البريد الإلكتروني
- تحقق من كلمة المرور
- تأكد من أن الحساب موجود في مجموعة `admins`

### المشكلة: بطء في التحميل
**الحل:**
- استخدم إعادة التحميل (Pull to Refresh)
- تحقق من سرعة الإنترنت
- استخدم pagination للطلبات الكثيرة

---

## 📞 التواصل والدعم

للمشاكل التقنية:
- البريد الإلكتروني: support@digl.com
- الهاتف: +966 XX XXX XXXX
- الموقع: www.digl.com/support

---

## 📝 ملاحظات مهمة

1. **الحفاظ على الأمان:**
   - غير كلمة المرور بانتظام
   - استخدم بريد إلكتروني آمن
   - لا تشارك بيانات الدخول

2. **الاحتفاظ بالسجلات:**
   - كل الإجراءات تُسجل في `admin_logs`
   - يمكنك مراجعة السجلات لاحقاً
   - احتفظ بنسخ احتياطية

3. **الإجراءات المهمة:**
   - راجع الطلبات بعناية قبل الموافقة
   - وضح سبب الرفض بوضوح
   - حافظ على احترافية التعامل

---

## 🎓 دورة الحياة للطبيب

```
التسجيل
  ↓
انتظار المراجعة (pending)
  ↓
├─ الموافقة → حساب نشط (verified)
│
└─ الرفض → حساب معطل (يمكن إعادة التقديم)
```

---

**آخر تحديث:** 2025-01-30
**الإصدار:** 1.0.0

