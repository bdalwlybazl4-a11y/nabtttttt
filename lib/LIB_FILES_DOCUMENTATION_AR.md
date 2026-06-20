0000# توثيق ملفات مجلد `lib` في مشروع Nabth / Digl

> هذا الملف يشرح بنية مجلد `lib` فقط، مع توضيح وظيفة كل ملف/صفحة والخدمات أو الدوال المهمة الموجودة فيها. الهدف أن يكون مرجعاً سريعاً لأي مطور جديد يريد فهم المشروع بدون فتح كل ملف على حدة.

## 1. نظرة عامة على بنية `lib`

يعتمد المشروع على Flutter مع Firebase، وتنقسم ملفات `lib` إلى طبقات واضحة:

- `main.dart` و `firebase_options.dart`: نقطة تشغيل التطبيق وإعدادات Firebase.
- `Provider/`: بوابة المصادقة وحالة عامة بسيطة وبعض شاشات الحالة.
- `core/`: إعدادات التصميم، الثيم، المسارات، الخدمات الأساسية، الويدجت المشتركة، وأدوات الحركة.
- `features/`: ميزات التطبيق الرئيسية، مثل الأدمن، الأطباء، المرضى، الاستشارات، المواعيد، الأدوية، الملف الطبي، الإعدادات، الأخبار، الترجمة.
- `services/`: خدمات عامة عابرة للميزات، مثل الإشعارات، الاتصال، المستخدم، المواعيد، الأدوية، Zego calls.

---

## 2. ملفات الجذر داخل `lib`

### `lib/main.dart`

- نقطة البداية الفعلية للتطبيق.
- يهيئ Firebase، الإشعارات، مراقبة الاتصال بالإنترنت، وخدمات الخلفية قبل تشغيل `MyApp`.
- يحتوي عادةً على:
  - `main()`: تهيئة التطبيق وتشغيل `runApp`.
  - `_firebaseMessagingBackgroundHandler`: استقبال رسائل Firebase في الخلفية.
  - `initializeNotifications()`: تجهيز الإشعارات المحلية/FCM.
  - `checkInternetAndWarn()`: فحص الاتصال وإظهار تنبيه عند عدم وجود إنترنت.
  - `MyApp`: الجذر الذي يربط الثيم، الـ routes، وبوابة الدخول.

### `lib/firebase_options.dart`

- ملف مولد غالباً من FlutterFire CLI.
- يحتوي `DefaultFirebaseOptions` لإرجاع إعدادات Firebase لكل منصة: Android / iOS / Web / macOS.
- لا يفضل تعديله يدوياً إلا عند إعادة توليد إعدادات Firebase.

### `lib/features/model.dart`

- ملف Models عام لبعض كيانات المشروع، وغالباً يستخدم في الأدوية أو البيانات المشتركة القديمة.
- يفضل مستقبلاً تقسيم أي Model عام إلى مجلد الميزة الخاصة به إذا كبر حجمه.

---

## 3. مجلد `Provider`

### `lib/Provider/auth_gate.dart`

- بوابة الدخول الرئيسية التي تقرر ما يظهر للمستخدم حسب حالة تسجيل الدخول والإنترنت.
- يتعامل مع Firebase Auth وحالة الاتصال وربما تهيئة Zego عند الحاجة.
- الدوال المهمة:
  - `initZegoIfNeeded()`: تهيئة Zego للمكالمات إذا كان المستخدم مناسباً لذلك.
  - `_checkInitialConnection()`: فحص الإنترنت عند فتح التطبيق.
  - `_setupConnectivityListener()`: الاستماع لتغير حالة الاتصال.
  - `_buildAuthContent()`: اختيار الشاشة المناسبة حسب المصادقة والدور.
  - `_buildNoInternetScreen()`: عرض شاشة لا يوجد إنترنت.

### `lib/Provider/provider.dart`

- يحتوي `HomeProvider` لإدارة حالة بسيطة في الصفحة الرئيسية، مثل المزاج أو قيمة مختارة.
- الدالة المهمة:
  - `setMood()`: تغيير الحالة وإبلاغ الواجهة عبر `notifyListeners()`.

### `lib/Provider/underReviewScreen.dart`

- شاشة تعرض للمستخدم/الطبيب أن الحساب تحت المراجعة.
- تستخدم غالباً بعد تسجيل طبيب جديد ينتظر موافقة الأدمن.

---

## 4. مجلد `core/config`

### `lib/core/config/design_helpers.dart`

- أدوات تصميم مشتركة لتوحيد الألوان، الظلال، الخلفيات، والـ decorations.
- يحتوي `DesignHelpers` و `ShadowLevel`.
- الدوال المهمة:
  - `getBackgroundColor()`: لون الخلفية حسب الثيم.
  - `getMessageBubbleColor()` و `getMessageTextColor()`: ألوان فقاعات الدردشة.
  - `getPrimaryGradient()` و `getButtonGradient()`: تدرجات لونية للأزرار/العناصر.
  - `getBorderDecoration()` و `getFilledDecoration()`: Decorations جاهزة للكروت والمدخلات.

### `lib/core/config/medical_theme.dart`

- ملف ثيم طبي موحد يحتوي ألوان المشروع الأساسية مثل الأزرق الطبي، الأحمر التحذيري، الأصفر، الأخضر.
- يحتوي `MedicalTheme` ودوال مساعدة للثيم.
- مهم للحفاظ على تناسق الواجهة في كل الشاشات.

### `lib/core/config/noInternet_screen.dart`

- شاشة مستقلة تظهر عند انقطاع الإنترنت.
- تعرض رسالة توضيحية وربما زر إعادة المحاولة حسب التنفيذ.

### `lib/core/config/presenceService.dart`

- خدمة حضور المستخدمين Online/Offline.
- ترتبط بـ Firestore أو Realtime updates لحفظ حالة المستخدم.
- الدوال المهمة:
  - `initialize()`: بدء خدمة الحضور.
  - `_setupPresenceListener()`: مراقبة حالة الاتصال.
  - `_updatePresence()`: تحديث بيانات الحضور.
  - `setOnline()` و `setOffline()`: تغيير حالة المستخدم.
  - `getUserPresence()`: قراءة حالة مستخدم محدد.

### `lib/core/config/routes.dart`

- ملف تجميع مسارات التطبيق.
- يربط أسماء الصفحات بالشاشات الفعلية لتسهيل التنقل.
- إذا تمت إضافة صفحة جديدة يفضل تسجيلها هنا إن كان المشروع يستخدم named routes.

### `lib/core/config/theme.dart`

- يحتوي `AppTheme` لتعريف الثيم العام للتطبيق.
- يستخدم لضبط `ThemeData` مثل الألوان، الخطوط، AppBar، Buttons، Inputs.

### `lib/core/config/theme_helper.dart`

- أدوات سريعة للتعامل مع الثيم والرسائل.
- الدوال المهمة:
  - `showErrorSnackBar()`، `showSuccessSnackBar()`، `showWarningSnackBar()`، `showInfoSnackBar()`.
  - `getTextColor()`، `getBackgroundColor()`، `getSurfaceColor()`.
  - `isDarkMode()`: معرفة إذا كان الوضع الليلي مفعلاً.

### `lib/core/config/theme_provider.dart`

- Provider لإدارة وضع الثيم: فاتح، داكن، أو حسب النظام.
- الدوال المهمة:
  - `initialize()`: قراءة إعداد الثيم المحفوظ.
  - `setLightMode()`، `setDarkMode()`، `setSystemMode()`.
  - `toggleTheme()`: التبديل بين الوضعين.
  - `getThemeModeName()`: اسم الوضع الحالي للعرض في الإعدادات.

---

## 5. مجلد `core/examples`

### `lib/core/examples/integration_example.dart`

- ملف أمثلة يوضح كيفية دمج مكونات المشروع المتقدمة.
- يحتوي شاشات مثل `EnhancedHomeScreenExample` و `TransitionsExampleScreen` و `AnimationsWidgetsExample`.
- مفيد للمطورين لفهم استخدام Widgets، التنقل، الصلاحيات، والكروت.
- لا يعتبر غالباً جزءاً أساسياً من تجربة المستخدم النهائية.

---

## 6. مجلد `core/services`

### `lib/core/services/firestore_setup.dart`

- يحتوي `setupFirestore()` لإعداد بيانات Firestore الأولية أو التأكد من وجود Collections/Docs أساسية.
- يستخدم عند أول تشغيل أو أثناء التطوير لضمان وجود بنية قاعدة البيانات المطلوبة.

---

## 7. مجلد `core/utils`

### `lib/core/utils/animations_utils.dart`

- أدوات انتقال وحركات مشتركة.
- يحتوي transitions مثل:
  - `FadePageTransition`.
  - `SlideRightPageTransition`.
  - `SlideLeftPageTransition`.
  - `ScalePageTransition`.
  - `RotateScalePageTransition`.
- يحتوي أيضاً `AnimatedButton` و `FadeInAnimation` لتحسين تجربة المستخدم.

---

## 8. مجلد `core/widgets`

### `lib/core/widgets/modern_bottom_nav_bar.dart`

- Bottom Navigation مخصص وحديث.
- يحتوي:
  - `ModernBottomNavBar`: شريط سفلي أساسي.
  - `BottomNavItem`: نموذج عنصر التنقل.
  - `AdvancedBottomNavBar`: نسخة أكثر تفاعلاً مع AnimationController.
  - `SimpleBottomNavBar`: نسخة بسيطة.
- الدوال المهمة:
  - `_buildNavItem()` و `_buildAdvancedNavItem()` لرسم عناصر التنقل.

### `lib/core/widgets/upcoming_appointments_widget.dart`

- Widget تعرض المواعيد القادمة للمستخدم.
- الدوال المهمة:
  - `formatArabicDate()` و `getArabicMonthName()`: تنسيق التاريخ بالعربية.
  - `_buildAppointmentCard()`: رسم بطاقة الموعد.
  - `getStatusText()`: ترجمة حالة الموعد.

---

## 9. ميزة الأدمن `features/admin`

### `lib/features/admin/models/admin_models.dart`

- نماذج بيانات لوحة الإدارة.
- يحتوي:
  - `AdminUser`: بيانات المسؤول، الدور، الصلاحيات، حالة النشاط.
  - `DoctorRequest`: طلب تسجيل الطبيب والوثائق وحالة المراجعة.
  - `AdminStats`: إحصائيات لوحة التحكم مثل عدد الأطباء، المرضى، المواعيد، الاستشارات، التقييمات الصحية، أكثر التخصصات والأطباء استخداماً.
- أهم الدوال/المصانع:
  - `fromFirestore()`: تحويل DocumentSnapshot إلى Model.
  - `toFirestore()`: تجهيز البيانات للحفظ.
  - `copyWith()` في `DoctorRequest`: نسخ الطلب مع تعديل قيم محددة.

### `lib/features/admin/services/admin_service.dart`

- الخدمة الأساسية للوحة الأدمن.
- مسؤولة عن تسجيل دخول المسؤول، إدارة طلبات الأطباء، إحصائيات لوحة التحكم، وسجل الأنشطة.
- الدوال المهمة:
  - `loginAdmin()`: تسجيل الدخول والتأكد أن الحساب موجود في Collection `admins`.
  - `logoutAdmin()`: تسجيل خروج الأدمن.
  - `getPendingDoctorRequests()` و `getAllDoctorRequests()`: جلب طلبات الأطباء.
  - `getDoctorRequest()`: جلب تفاصيل طلب واحد.
  - `approveDoctorRequest()`: الموافقة على الطبيب وتحديث حسابه كموثق.
  - `rejectDoctorRequest()`: رفض الطلب وتسجيل السبب.
  - `getAdminStats()`: جلب إحصائيات مباشرة من Firestore.
  - `getAdminLogs()`: قراءة سجل عمليات الأدمن.
  - `searchDoctorRequests()`: بحث عن طلبات الأطباء بالاسم.
  - `updateAdminProfile()`: تحديث بيانات المسؤول.

### `lib/features/admin/services/admin_report_service.dart`

- خدمة إنشاء تقارير PDF للوحة الأدمن.
- تستخدم حزم `pdf` و `printing`.
- الدالة المهمة:
  - `printDashboardReport()`: ينشئ تقريراً عربياً يحتوي المرضى، الأطباء، الاستشارات، الحجوزات، نتائج التقييم الصحي، أكثر التخصصات، وأكثر الأطباء استخداماً، ثم يفتحه للطباعة أو الحفظ.

### `lib/features/admin/services/admin_setup_service.dart`

- خدمة تجهيز وإدارة حسابات الأدمن وصلاحياتها.
- الدوال المهمة:
  - `ensureAdminExists()`: التأكد من وجود مسؤول أساسي.
  - `isCurrentUserAdmin()`: معرفة هل المستخدم الحالي أدمن.
  - `hasPermission()`: فحص صلاحية محددة.
  - `addPermissionToAdmin()` و `removePermissionFromAdmin()`: تعديل صلاحيات الأدمن.
  - `toggleAdminStatus()`: تفعيل/تعطيل حساب أدمن.
  - `changeAdminPassword()`: تغيير كلمة مرور المسؤول.

### `lib/features/admin/presentation/pages/admin_auth_gate.dart`

- بوابة خاصة بالأدمن.
- تتحقق من تسجيل الدخول ومن وجود المستخدم في مجموعة `admins`.
- توجه إما إلى Login أو Dashboard.

### `lib/features/admin/presentation/pages/admin_dashboard_screen.dart`

- صفحة Dashboard الرئيسية للأدمن.
- تعرض الترحيب، الإحصائيات، الطلبات المعلقة، إجراءات سريعة، تقارير PDF، ورسوم بيانية.
- الدوال المهمة:
  - `_buildDashboardContent()`: محتوى لوحة التحكم.
  - `_buildStatsGrid()`: شبكة الإحصائيات.
  - `_buildPendingRequestsCard()`: بطاقة الطلبات التي تحتاج مراجعة.
  - `_buildInsightsSection()`: قسم التقارير والرسوم البيانية.
  - `_buildReportsCard()`: بطاقة إنشاء تقرير PDF.
  - `_buildModernCharts()`: رسوم بيانية مبسطة داخل اللوحة.
  - `_printReport()`: استدعاء خدمة PDF.
  - `_logout()`: تسجيل خروج المسؤول.

### `lib/features/admin/presentation/pages/admin_login_screen.dart`

- شاشة تسجيل دخول الأدمن الأساسية.
- الدوال المهمة:
  - `_loginAdmin()`: تنفيذ تسجيل الدخول عبر `AdminService`.
  - `_getFirebaseErrorMessage()`: ترجمة أخطاء Firebase للمستخدم.

### `lib/features/admin/presentation/pages/admin_login_screen1.dart`

- نسخة أخرى/قديمة من شاشة دخول الأدمن.
- يبدو أنها تؤدي نفس وظيفة `admin_login_screen.dart` مع اختلافات تصميمية أو تجريبية.
- يفضل مستقبلاً توحيد النسختين لتقليل التكرار.

### `lib/features/admin/presentation/pages/doctor_requests_screen.dart`

- صفحة قائمة طلبات الأطباء.
- تعرض الطلبات حسب الحالة: pending / approved / rejected.
- الدوال المهمة:
  - `_loadRequests()`: تحميل الطلبات.
  - `_buildFilterBar()` و `_buildFilterButton()`: فلترة حسب الحالة.
  - `_buildRequestCard()`: بطاقة طلب الطبيب.
  - `_buildEmptyState()`: حالة عدم وجود نتائج.
  - `_formatDate()`: تنسيق تاريخ الطلب.

### `lib/features/admin/presentation/pages/doctor_request_details_screen.dart`

- صفحة تفاصيل طلب طبيب محدد.
- تعرض بيانات الطبيب، الوثائق، الحالة، وأزرار الموافقة أو الرفض.
- الدوال المهمة:
  - `_buildStatusCard()`: بطاقة الحالة.
  - `_buildInfoCard()` و `_buildInfoRow()`: عرض المعلومات.
  - `_buildDocumentItem()`: عنصر الوثيقة.
  - `_buildActionButtons()`: أزرار مراجعة الطلب.
  - `_approveRequest()` و `_rejectRequest()`: تنفيذ القرار.

### `lib/features/admin/presentation/widgets/admin_protection_widget.dart`

- Widget لحماية شاشات الأدمن من الوصول غير المصرح.
- الدوال المهمة:
  - `_checkAdminAccess()`: التحقق من الصلاحيات.
  - `_buildLoadingScreen()`: شاشة انتظار.
  - `_buildAccessDeniedScreen()`: شاشة رفض الوصول.
  - `protectAdminScreen()`: helper لتغليف أي صفحة تحتاج حماية.

---

## 10. ميزة المواعيد `features/appointments`

### `lib/features/appointments/presentation/appointments_screen.dart`

- شاشة مدخل/غلاف للمواعيد.
- غالباً تنقل المستخدم إلى قائمة المواعيد أو صفحة الحجز حسب الدور.

### `lib/features/appointments/presentation/pages/appointments_list_screen.dart`

- تعرض قائمة المواعيد الحالية والسابقة.
- الدوال المهمة:
  - `_buildDaySection()`: تجميع المواعيد حسب اليوم.
  - `_buildAppointmentCard()`: بطاقة الموعد.
  - `_statusChip()`: عرض حالة الموعد.
  - `_confirmDelete()` و `_deleteAppointment()`: حذف/إلغاء موعد.
  - `_showFilterDialog()`: فلترة المواعيد.

### `lib/features/appointments/presentation/pages/appointment_details_screen.dart`

- صفحة تفاصيل الموعد.
- تعرض الطبيب/المريض، التاريخ، الوقت، الحالة، وأزرار الإجراءات.
- الدوال المهمة:
  - `_checkUserType()`: معرفة دور المستخدم.
  - `_markInSession()`: تحديث الموعد إلى قيد الجلسة.
  - `_buildDetailRow()` و `_buildInfoChip()`: عناصر واجهة.
  - `formatArabicDate()` و `getArabicMonthName()`: تنسيق عربي.
  - `_translateStatus()`: ترجمة حالة الموعد.
  - `_confirmCancel()`: تأكيد إلغاء الموعد.

### `lib/features/appointments/presentation/pages/book_appointment_screen.dart`

- صفحة حجز موعد مع طبيب.
- الدوال المهمة:
  - `_loadDoctors()`: تحميل الأطباء.
  - `_loadDoctorWorkplaces()`: تحميل أماكن عمل الطبيب.
  - `_loadAvailableTimes()`: تحميل الأوقات المتاحة.
  - `_bookAppointment()`: حفظ الحجز في Firestore.
  - `_buildDoctorSelector()`، `_buildDateSelector()`، `_buildTimeSelector()`: أجزاء الواجهة.

---

## 11. ميزة المصادقة `features/auth`

### `lib/features/auth/presentation/pages/login_screen.dart`

- شاشة تسجيل دخول المستخدمين.
- تتعامل مع Firebase Auth وتوجيه المستخدم حسب الدور.
- تشمل عادةً فحص المدخلات، إظهار الأخطاء، والانتقال للشاشة المناسبة.

### `lib/features/auth/presentation/pages/login_screen1.dart`

- نسخة بديلة/قديمة لشاشة الدخول.
- يفضل مراجعتها لاحقاً وتوحيدها مع `login_screen.dart` إذا كانت مكررة.

### `lib/features/auth/presentation/pages/register_screen.dart`

- شاشة تسجيل مستخدم جديد.
- تجمع بيانات الحساب، نوع المستخدم، وتحفظ بياناته في Firestore.
- إذا كان المستخدم طبيباً فقد تنقله إلى مرحلة توثيق/مراجعة.

### `lib/features/auth/presentation/pages/verification_pending_screen.dart`

- شاشة انتظار التحقق.
- تعرض للطبيب أن حسابه بانتظار موافقة الإدارة.

### `lib/features/auth/presentation/pages/no_internet_app.dart`

- شاشة أو تطبيق مصغر عند عدم وجود اتصال.
- تستخدم كبديل آمن بدلاً من تحميل صفحات تعتمد على Firebase.

---

## 12. ميزة الاستشارات `features/consultations`

### `lib/features/consultations/models/message_reaction_model.dart`

- Model لتفاعل المستخدمين مع الرسائل مثل إعجاب أو رمز تعبيري.
- يستخدم في الدردشة لتخزين التفاعل وربطه بالرسالة والمستخدم.

### `lib/features/consultations/services/message_reactions_service.dart`

- خدمة إضافة/تحديث/حذف تفاعلات الرسائل.
- تتعامل مع Firestore لتنظيم reactions داخل المحادثة.

### `lib/features/consultations/presentation/pages/consultation_screen.dart`

- شاشة الدردشة أو الاستشارة الفردية.
- غالباً تعرض الرسائل، الإرسال، المرفقات، المكالمات، وحالة الطرف الآخر.
- الدوال المهمة عادةً تشمل تحميل الرسائل، إرسال رسالة، بناء فقاعة الرسالة، بدء مكالمة.

### `lib/features/consultations/presentation/pages/groupConsultationScreen.dart`

- شاشة استشارة جماعية.
- تسمح بوجود أكثر من مشارك داخل محادثة أو مجموعة طبية.

### `lib/features/consultations/presentation/pages/instant_consultation_screen.dart`

- شاشة بدء استشارة فورية.
- تبحث عن طبيب متاح أو تخصص مناسب وتبدأ التواصل بسرعة.

### `lib/features/consultations/presentation/pages/incoming_call_screen.dart`

- شاشة استقبال مكالمة واردة.
- تعرض بيانات المتصل وأزرار قبول/رفض.

### `lib/features/consultations/presentation/pages/call_page.dart`

- صفحة المكالمة نفسها، صوتية أو فيديو.
- ترتبط بخدمات Zego أو خدمة المكالمات المستخدمة.

### `lib/features/consultations/presentation/pages/tj.dart`

- ملف تجريبي أو صفحة اختبار داخل الاستشارات.
- يحتاج تسمية أوضح إذا كان سيبقى في الإنتاج.

### `lib/features/consultations/presentation/widgets/message_reactions_widget.dart`

- Widget لعرض وإدارة reactions على الرسائل.
- تستخدم `MessageReactionsService` و `MessageReactionModel`.

---

## 13. ميزة الطبيب `features/doctor`

### `lib/features/doctor/presentation/pages/doctor_register_screen.dart`

- صفحة تسجيل الطبيب أو استكمال بياناته المهنية.
- تجمع التخصص، الرخصة، الشهادات، العيادة، وسنوات الخبرة.

### `lib/features/doctor/presentation/pages/doctor_dashboard_screen.dart`

- لوحة الطبيب الرئيسية.
- تعرض إحصائيات الطبيب، مواعيده، وربما الاستشارات والتنبيهات.

### `lib/features/doctor/presentation/pages/doctor_appointments_screen.dart`

- صفحة مواعيد الطبيب.
- تتيح عرض المواعيد القادمة/السابقة وتغيير حالاتها.

### `lib/features/doctor/presentation/pages/doctor_profil_screen.dart`

- صفحة ملف الطبيب العام.
- تعرض الاسم، الصورة، التخصص، التقييم، الخبرة، ومعلومات العيادة.

### `lib/features/doctor/presentation/doctorsListScreen.dart`

- شاشة قائمة الأطباء.
- تستخدم للبحث أو عرض الأطباء حسب التخصص.

### `lib/features/doctor/presentation/doctorsListWidget.dart`

- Widget لقائمة الأطباء يمكن إعادة استخدامها داخل صفحات أخرى.
- تعرض كروت مختصرة للطبيب.

### `lib/features/doctor/presentation/shimmer_doctor_card.dart`

- Shimmer/Skeleton loading card أثناء تحميل الأطباء.
- يحسن تجربة الانتظار.

### `lib/features/doctor/presentation/appointments_management_screen.dart`

- شاشة إدارة المواعيد للطبيب أو الإدارة.
- قد تحتوي على قبول/رفض/تعديل حالة المواعيد.

### `lib/features/doctor/dashboard/appointments_screen.dart`

- تبويب أو صفحة مواعيد داخل Dashboard الطبيب.

### `lib/features/doctor/dashboard/bookings_screen.dart`

- صفحة الحجوزات داخل لوحة الطبيب.

### `lib/features/doctor/dashboard/performance_screen.dart`

- صفحة أداء الطبيب.
- تعرض مؤشرات مثل عدد الاستشارات، التقييم، والحجوزات.

---

## 14. ميزة الأخبار الصحية `features/healthNews`

### `lib/features/healthNews/all_HealthNewsScreen.dart`

- شاشة عرض جميع الأخبار الصحية.
- تستخدم غالباً خدمة `HealthNewsService` لجلب الأخبار.

### `lib/features/healthNews/newsDetailScreen.dart`

- صفحة تفاصيل خبر صحي واحد.
- تعرض العنوان، الصورة، المحتوى، والتاريخ.

### `lib/features/healthNews/medical_news_widget.dart`

- Widget مختصر لعرض أخبار طبية في الصفحة الرئيسية.

### `lib/features/healthNews/medical_tips_widget.dart`

- Widget لعرض نصائح صحية قصيرة.

---

## 15. ميزة الصفحة الرئيسية `features/home`

### `lib/features/home/presentation/pages/home_screen.dart`

- الصفحة الرئيسية للمستخدم.
- تعرض أقساماً مثل الأخبار، المواعيد القادمة، الأدوية، الاستشارات، وربما اختصارات حسب الدور.

### `lib/features/home/presentation/pages/notificationsScreen.dart`

- شاشة الإشعارات داخل التطبيق.
- تعرض إشعارات الرسائل، المواعيد، الأدوية، المكالمات، وغيرها.

### `lib/features/home/presentation/pages/upcomingMedicationsSection.dart`

- قسم يعرض الأدوية القادمة أو الجرعات التالية.
- يستخدم في الصفحة الرئيسية لمساعدة المريض على الالتزام بالدواء.

---

## 16. ميزة الملف الطبي `features/medical_profile`

### Models

#### `lib/features/medical_profile/models/health_profile_model.dart`

- Model يمثل الملف الصحي للمريض.
- يحتوي بيانات مثل العمر، الجنس، الأمراض المزمنة، الأعراض، تاريخ بداية العرض، مستوى الألم.
- يستخدمه تحليل التشخيص الذكي.

#### `lib/features/medical_profile/models/patient_symptoms_model.dart`

- Model لبيانات أعراض المريض التي يتم جمعها من أسئلة الذكاء الاصطناعي.
- يحفظ العرض الرئيسي، الأعراض الإضافية، شدة الألم، التوقيت، وغيرها.

#### `lib/features/medical_profile/models/doctor_recommendation_model.dart`

- Model للطبيب الموصى به.
- يحتوي: `doctorId`، الاسم، التخصص، التقييم، عدد الاستشارات، التوفر، الصورة، الرخصة، سنوات الخبرة، نسبة التطابق، أسباب التوصية.
- يحتوي `overallScore` لحساب ترتيب الطبيب بناءً على التقييم، الاستشارات، والخبرة.

### Services

#### `lib/features/medical_profile/services/advanced_diagnosis_service.dart`

- خدمة التشخيص الذكية المتقدمة.
- تحلل `HealthProfile` وتقترح أدوية، تخصصات، أطباء، وإجراءات فورية.
- الدوال المهمة:
  - `analyzeHealthProfile()`: نقطة التحليل الرئيسية.
  - `_calculateSeverity()`: تقدير مستوى الخطورة.
  - `_parseSymptoms()`: استخراج الأعراض المطابقة.
  - `_recommendMedicines()`: اقتراح أدوية من قاعدة داخلية.
  - `_recommendSpecialties()`: اقتراح تخصصات.
  - `saveMedicalAnalysis()`: حفظ نتيجة التحليل في Firestore.

#### `lib/features/medical_profile/services/diagnosis_service.dart`

- خدمة تشخيص أبسط أو قديمة.
- تستخدم غالباً لتحليل مبدئي قبل الخدمة المتقدمة.

#### `lib/features/medical_profile/services/doctor_matching_service.dart`

- خدمة اختيار الطبيب المناسب بناءً على التخصصات والأعراض.
- تبحث في Collection `users` عن أطباء موثقين، وتطابق التخصص مع aliases مثل صدرية/رئة/قلب.
- الدوال المهمة:
  - `findMatchingDoctors()`: جلب وترتيب أفضل الأطباء.
  - `_searchDoctorsBySpecialty()`: البحث المرن حسب التخصص.
  - `_calculateMatchPercentage()`: حساب نسبة التطابق.
  - `_generateRecommendationReasons()`: أسباب التوصية.
  - `getDoctorDetails()`: جلب طبيب محدد.
  - `getAllVerifiedDoctors()`: fallback للأطباء الموثقين.
  - `saveDoctorRecommendation()`: حفظ توصيات الطبيب للمريض.

#### `lib/features/medical_profile/services/medical_profile_service.dart`

- خدمة CRUD للملف الطبي.
- مسؤولة عن حفظ وقراءة وتحديث ملف المريض الصحي من Firestore.

#### `lib/features/medical_profile/services/patient_symptoms_service.dart`

- خدمة حفظ وقراءة أعراض المريض.
- تستخدمها أسئلة الذكاء الاصطناعي وشاشة التقييم الصحي.

#### `lib/features/medical_profile/services/ai_questions_scheduler_service.dart`

- خدمة لتحديد متى تظهر أسئلة الذكاء الاصطناعي للمريض.
- تساعد على عدم إزعاج المستخدم بالأسئلة كل مرة.

### Pages

#### `lib/features/medical_profile/presentation/pages/health_questions_screen.dart`

- شاشة أسئلة صحية عامة.
- تجمع بيانات الملف الصحي الأولية.

#### `lib/features/medical_profile/presentation/pages/ai_symptom_questions_screen.dart`

- شاشة أسئلة ذكية عن الأعراض.
- تجمع العرض الرئيسي، تفاصيل إضافية، وشدة الحالة.

#### `lib/features/medical_profile/presentation/pages/ai_symptom_questions_screen1.dart`

- نسخة بديلة/قديمة من شاشة أسئلة الأعراض.
- يفضل توحيدها لاحقاً إذا كانت مكررة.

#### `lib/features/medical_profile/presentation/pages/diagnosis_result_screen.dart`

- شاشة عرض نتيجة التشخيص.
- تعرض الخطورة والتوصيات وربما الأدوية.

#### `lib/features/medical_profile/presentation/pages/medical_analysis_result_screen.dart`

- شاشة نتيجة التحليل الطبي المتقدم.
- تعرض التخصصات، الإجراءات، والأطباء الموصى بهم.

#### `lib/features/medical_profile/presentation/pages/suggested_doctor_screen.dart`

- شاشة الأطباء المقترحين للمريض.
- تعرض قائمة أطباء مناسبة بناءً على الحالة.

---

## 17. ميزة السجلات الطبية `features/medical_records`

### `lib/features/medical_records/presentation/pages/medical_records_screen.dart`

- شاشة السجلات الطبية للمريض.
- تعرض أو تدير ملفات/تقارير طبية محفوظة.
- يمكن أن تشمل فحوصات، وصفات، تقارير، أو مرفقات.

---

## 18. ميزة الأدوية `features/medications`

### `lib/features/medications/presentation/pages/medications_screen.dart`

- شاشة قائمة الأدوية.
- تعرض الأدوية الخاصة بالمريض أو الأدوية التي وصفها الطبيب حسب الدور.

### `lib/features/medications/presentation/pages/medication_form.dart`

- نموذج إضافة أو تعديل دواء.
- يجمع الاسم، الجرعة، المواعيد، مدة الاستخدام، وربما تعليمات الطبيب.

### `lib/features/medications/presentation/pages/medication_details_screen.dart`

- صفحة تفاصيل دواء محدد.
- تعرض الجرعات، الوقت، الحالة، والملاحظات.

### `lib/features/medications/presentation/pages/medication_reminder_screen.dart`

- شاشة تذكيرات الدواء.
- تعرض المواعيد القادمة وتسمح بإدارة التنبيهات.

---

## 19. ميزة الملف الشخصي `features/profile`

### `lib/features/profile/presentation/pages/profile_screen.dart`

- شاشة ملف المستخدم.
- تعرض بيانات الحساب، الإحصائيات، الإعدادات السريعة، وتسجيل الخروج.
- الدوال المهمة غالباً:
  - `_loadUserProfile()`: قراءة بيانات المستخدم.
  - `_logout()`: تسجيل الخروج.
  - `_openSupport()`: فتح الدعم.

### `lib/features/profile/presentation/pages/edit_profile_screen.dart`

- شاشة تعديل الملف الشخصي.
- تسمح بتغيير الاسم، الهاتف، الصورة، وبعض البيانات الشخصية.

### `lib/features/profile/presentation/pages/supportScreen.dart`

- شاشة الدعم الفني.
- تعرض معلومات التواصل ونموذج اتصال.
- الدوال المهمة:
  - `_buildEngineerCard()`: بطاقة بيانات المسؤول/المهندس.
  - `_launchEmail()`، `_launchPhone()`، `_launchWhatsApp()`: فتح وسائل التواصل.

---

## 20. ميزة الإعدادات `features/settings`

### `lib/features/settings/models/symptom_keyword_analysis_model.dart`

- Model جديد لتحليل الأعراض بالكلمات المفتاحية.
- يحتوي:
  - `SymptomKeywordRule`: قاعدة تربط أعراضاً وكلمات مفتاحية بعضو وتخصص ورسالة.
  - `SymptomKeywordAnalysisResult`: نتيجة تحليل القاعدة المختارة.
- الدوال المهمة:
  - `matchScore()`: حساب درجة مطابقة أعراض المريض مع القاعدة.
  - `toSpecialtyRecommendation()`: تحويل القاعدة إلى توصية تخصص.
  - `toFirestore()`: تجهيز نتيجة التحليل للحفظ.

### `lib/features/settings/services/symptom_keyword_analysis_service.dart`

- خدمة تشغيل قواعد تحليل الكلمات المفتاحية.
- تحتوي قواعد قابلة للتوسعة للرئة، القلب، الجلدية، والعيون.
- الدوال المهمة:
  - `allSymptoms`: قائمة كل الأعراض المتاحة للواجهة.
  - `analyze()`: اختيار أفضل قاعدة حسب أعراض المريض.
  - `saveResult()`: حفظ نتيجة التقييم الصحي في `patients/{id}/health_assessments`.

### `lib/features/settings/presentation/pages/settings_screen.dart`

- شاشة إعدادات المستخدم.
- تعرض بيانات الحساب، إعدادات الثيم، التقييم الصحي، تغيير كلمة المرور، وتسجيل الخروج.
- الدوال المهمة:
  - `_loadUserData()`: قراءة بيانات المستخدم.
  - `_changePassword()`: تغيير كلمة المرور.
  - `_logout()`: تسجيل الخروج.
  - `_buildHealthAssessmentSection()`: قسم التقييم الصحي.

### `lib/features/settings/presentation/pages/health_assessment_screen.dart`

- شاشة التقييم الصحي الذكي.
- تجمع بين النظام القديم لأسئلة الأعراض ونظام الكلمات المفتاحية الجديد.
- أهم ما تقوم به:
  - اختيار أعراض من Chips.
  - تحليل الأعراض وربطها بالتخصص والعضو.
  - حفظ النتيجة في Firestore.
  - جلب أطباء مناسبين تلقائياً من قاعدة البيانات.
  - عرض النتائج والأطباء بتصميم Cards.
- الدوال المهمة:
  - `_loadAssessmentData()`: تحميل آخر نتيجة تقييم أو تحليل.
  - `_analyzeSelectedSymptoms()`: تحليل الأعراض المختارة بالكلمات المفتاحية.
  - `_analyzeSymptoms()`: تحليل آخر أعراض محفوظة بالنظام القديم.
  - `_buildKeywordAssessmentCard()`: واجهة اختيار الأعراض.
  - `_buildKeywordResultCard()`: عرض نتيجة العضو/التخصص.
  - `_buildDoctorCard()`: عرض الطبيب المقترح.

---

## 21. ميزة الترجمة `features/translation`

### `lib/features/translation/presentation/pages/translation_screen.dart`

- شاشة ترجمة رسائل أو نصوص.
- الدوال المهمة:
  - `_translateAndAddMessage()`: ترجمة النص وإضافته للمحادثة/القائمة.
  - `dispose()`: التخلص من Controllers.

---

## 22. الخدمات العامة `lib/services`

### `lib/services/user_service.dart`

- خدمة CRUD عامة للمستخدمين.
- الدوال المهمة:
  - `addUser()`، `getUser()`، `updateUser()`، `deleteUser()`.

### `lib/services/user_role_service.dart`

- خدمة معرفة دور المستخدم وصلاحياته.
- الدوال المهمة:
  - `getUserRole()`، `isDoctor()`، `isPatient()`.
  - `hasPermission()`.
  - `canAddMedication()`، `canPrescribeMedicine()`، `canViewPatientReports()`، `canAddMedicalNews()`.
  - `updateUserRole()`.
  - `isDoctorVerified()`.

### `lib/services/logout_service.dart`

- خدمة تسجيل خروج آمن.
- تقوم بتنظيف FCM token، البيانات المحلية، جلسة Zego، ثم توجه المستخدم لشاشة الدخول.
- الدوال المهمة:
  - `performSecureLogout()`.
  - `_clearFcmToken()`، `_clearLocalData()`، `_endZegoSession()`، `_navigateToLoginScreen()`.

### `lib/services/connectivity_service.dart`

- خدمة فحص الاتصال بالإنترنت.
- الدوال المهمة:
  - `isConnected()`.
  - `showNoInternetDialog()`.
  - `showNoInternetSnackBar()`.

### `lib/services/internet_checker_service.dart`

- خدمة فحص إنترنت أبسط.
- الدالة المهمة:
  - `hasInternet()`.

### `lib/services/appointment_service.dart`

- خدمة CRUD للمواعيد.
- الدوال المهمة:
  - `addAppointment()`، `getAppointment()`، `updateAppointment()`، `deleteAppointment()`.

### `lib/services/appointmentNotificationService.dart`

- خدمة تذكيرات المواعيد.
- الدوال المهمة:
  - `initialize()`.
  - `scheduleAppointmentReminders()`.
  - `_scheduleSingleReminder()`.
  - `listenToUserAppointments()` لمتابعة مواعيد المستخدم وجدولة تنبيهات لها.

### `lib/services/medication_service.dart`

- خدمة CRUD للأدوية.
- الدوال المهمة:
  - `addMedication()`، `getMedication()`، `updateMedication()`، `deleteMedication()`.

### `lib/services/medication_notification_service.dart`

- خدمة إشعارات أدوية أساسية.
- الدوال المهمة:
  - `initialize()`.
  - `scheduleMedicationReminder()`.
  - `cancelMedicationReminder()`.
  - `cancelAllMedicationReminders()`.

### `lib/services/advanced_medication_reminder_service.dart`

- خدمة تذكيرات أدوية متقدمة.
- تدعم جدولة متكررة وإدارة معرفات التنبيهات.
- الدوال المهمة:
  - `initialize()` و `_requestPermissions()`.
  - `scheduleMedicationReminders()`.
  - `cancelMedicationReminders()` و `cancelAllReminders()`.
  - `_generateReminderId()`.
  - `_handleNotificationResponse()`.

### `lib/services/patient_medication_reminder_service.dart`

- خدمة خاصة بتذكيرات أدوية المريض.
- الدوال المهمة:
  - `approveMedication()` و `rejectMedication()`.
  - `rescheduleApprovedForCurrentPatient()`.
  - `scheduleMedicationById()`.
  - `cancelMedicationReminders()`.
  - `formatTime24()`.

### `lib/services/notification_service.dart`

- خدمة إشعارات عامة تشمل FCM والمحلية.
- الدوال المهمة:
  - `initialize()` و `_setupFCM()`.
  - `_handleIncomingNotification()`.
  - `_showCallNotification()`.
  - `_showMessageNotification()`.
  - `_showAppointmentNotification()`.
  - `_showGeneralNotification()`.
  - `getDeviceToken()`.

### `lib/services/enhanced_notifications_service.dart`

- خدمة إشعارات محسنة للمواعيد والأدوية.
- الدوال المهمة:
  - `initialize()`.
  - `_createNotificationChannels()`.
  - `scheduleAppointmentReminder()`.
  - `scheduleMedicationReminder()`.
  - `cancelNotification()` و `cancelAllNotifications()`.

### `lib/services/local_in_app_notification_service.dart`

- خدمة إشعارات داخل التطبيق وتخزينها.
- الدوال المهمة:
  - `setNavigatorKey()`.
  - `initialize()`.
  - `showAndStore()`.
  - `storeNotification()`.
  - `_handleNotificationTap()`.

### `lib/services/call_message_notification_service.dart`

- خدمة إشعارات المكالمات والرسائل.
- الدوال المهمة:
  - `initialize()`.
  - `_createNotificationChannels()`.
  - `_handleForegroundMessage()` و `_handleBackgroundMessage()`.
  - `_showLocalNotification()`.
  - `_saveDeviceToken()`.
  - `_navigateToScreen()`.

### `lib/services/chat_realtime_notification_service.dart`

- خدمة تنبيهات الرسائل اللحظية.
- الدوال المهمة:
  - `start()`.
  - `_listenForIncomingMessages()`.
  - `_notifyForLatestMessage()`.

### `lib/services/incoming_call_service.dart`

- خدمة استقبال المكالمات الأساسية.
- قد تحتوي logic قديم أو helper لمكالمات واردة.
- يجب مراجعتها مع الخدمات المحسنة لتجنب التكرار.

### `lib/services/enhanced_incoming_call_service.dart`

- خدمة محسنة للتعامل مع المكالمات الواردة عبر FCM/Zego.
- الدوال المهمة:
  - `initialize()`.
  - `_handleForegroundMessage()`.
  - `_handleMessageOpenedApp()`.
  - `_processIncomingCall()`.
  - `logMissedCall()`.
  - `sendCallNotification()`.

### `lib/services/zego_call_service.dart`

- خدمة تشغيل مكالمات Zego.
- الدوال المهمة:
  - `initialize()`.
  - `_requestPermissions()`.
  - `_waitForSignalingConnection()`.
  - `startVideoCall()` و `startAudioCall()`.
  - `_saveCallLog()`.
  - `endCall()`.

### `lib/services/zego_incoming_call_handler.dart`

- Handler لمكالمات Zego الواردة.
- الدوال المهمة:
  - `initialize()`.
  - `_setupZegoCallInvitationListener()`.
  - `logCallCompletion()`.
  - `updateCallStatus()`.
  - `dispose()`.

### `lib/services/ai_questions_service.dart`

- خدمة تحديد ظهور أسئلة الذكاء الاصطناعي وحفظ إكمالها.
- الدوال المهمة:
  - `shouldShowAiQuestions()`.
  - `_shouldShowAgainAfterDays()`.
  - `saveAiQuestionsCompletion()`.
  - `resetAiQuestionsForDebug()`.

### `lib/services/health_News_Service.dart`

- خدمة الأخبار الصحية.
- تحتوي غالباً:
  - `HealthNewsItem`: Model للخبر.
  - `HealthNewsService`: مصدر الأخبار أو البيانات.

---

## 23. ملاحظات تنظيمية مهمة

1. توجد بعض الملفات المكررة أو التجريبية مثل `login_screen1.dart` و `ai_symptom_questions_screen1.dart` و `tj.dart`. يفضل لاحقاً تحديد النسخة المعتمدة وحذف أو أرشفة النسخ القديمة.
2. يفضل عند إضافة أي Feature جديدة اتباع نفس التقسيم:
   - `models/`
   - `services/`
   - `presentation/pages/`
   - `presentation/widgets/`
3. كل خدمة تتعامل مع Firestore يجب أن توثق أسماء Collections والحقول المتوقعة لتقليل أخطاء runtime.
4. ملفات التصميم والثيم في `core/config` يجب استخدامها بدلاً من كتابة ألوان ثابتة في كل صفحة، لضمان دعم الوضع الليلي وتناسق الهوية.
5. أي صفحة جديدة يجب أن تراعي: loading state، empty state، error state، وتجربة مستخدم واضحة.

---

## 24. خريطة سريعة حسب الهدف

- تريد تعديل تسجيل الدخول؟ ابدأ من `features/auth` و `Provider/auth_gate.dart`.
- تريد تعديل صلاحيات الأدمن؟ ابدأ من `features/admin/services/admin_service.dart` و `admin_setup_service.dart`.
- تريد تعديل طلبات الأطباء؟ ابدأ من `doctor_requests_screen.dart` و `doctor_request_details_screen.dart`.
- تريد تعديل تقييم الصحة؟ ابدأ من `features/settings/presentation/pages/health_assessment_screen.dart` و `features/settings/services/symptom_keyword_analysis_service.dart`.
- تريد تعديل مطابقة الأطباء؟ ابدأ من `features/medical_profile/services/doctor_matching_service.dart`.
- تريد تعديل الإشعارات؟ ابدأ من `services/notification_service.dart` و `enhanced_notifications_service.dart`.
- تريد تعديل المكالمات؟ ابدأ من `services/zego_call_service.dart` و `zego_incoming_call_handler.dart`.
- تريد تعديل الأدوية؟ ابدأ من `features/medications` و `services/medication_service.dart`.
- تريد تعديل المواعيد؟ ابدأ من `features/appointments` و `services/appointment_service.dart`.
