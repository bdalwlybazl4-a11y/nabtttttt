import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digl/core/config/medical_theme.dart';
import 'package:digl/core/config/theme_provider.dart';
import 'package:digl/core/config/theme_helper.dart';
import 'package:digl/core/widgets/premium_ui.dart';
import 'package:digl/services/user_role_service.dart';
import 'package:digl/services/logout_service.dart';
import 'package:digl/features/settings/presentation/pages/health_assessment_screen.dart';
import 'package:digl/features/settings/presentation/pages/static_info_pages.dart';
import 'package:provider/provider.dart';

/// ⚙️ صفحة الإعدادات المحترفة
/// تحتوي على معلومات الحساب، تغيير كلمة المرور، تسجيل الخروج، وإعدادات التطبيق
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ متغيرات الحالة
  bool isLoading = true;
  bool _enableNotifications = true;
  String fullName = '';
  String email = '';
  String? profileImageUrl;
  String userRole = 'patient';
  bool _isChangingPassword = false;

  // ✅ Controllers للنماذج
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  // ✅ Animation Controller
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// ✅ تحميل بيانات المستخدم من Firebase
  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userData = await UserRoleService.getUserFullData();
      if (userData == null) return;

      setState(() {
        fullName = userData['fullName'] ?? 'المستخدم';
        email = user.email ?? '';
        profileImageUrl = userData['photoURL'];
        userRole = userData['accountType'] ?? 'patient';
        isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      print('❌ خطأ في تحميل البيانات: $e');
      setState(() => isLoading = false);
    }
  }

  /// ✅ دالة تغيير كلمة المرور
  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('كلمات المرور غير متطابقة', isError: true);
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showSnackBar('يجب أن تكون كلمة المرور 6 أحرف على الأقل', isError: true);
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // إعادة المصادقة
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // تغيير كلمة المرور
      await user.updatePassword(_newPasswordController.text);

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (mounted) {
        ThemeHelper.showSuccessSnackBar(context, 'تم تغيير كلمة المرور بنجاح');
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        if (e.code == 'wrong-password') {
          ThemeHelper.showErrorSnackBar(context, 'كلمة المرور الحالية غير صحيحة');
        } else {
          ThemeHelper.showErrorSnackBar(context, 'حدث خطأ: ${e.message}');
        }
      }
    } finally {
      setState(() => _isChangingPassword = false);
    }
  }

  /// ✅ دالة تسجيل الخروج الآمنة
  Future<void> _logout() async {
    await LogoutService.showLogoutConfirmationDialog(
      context,
      title: 'تسجيل الخروج',
      message: 'هل تريد تسجيل الخروج من التطبيق؟',
      confirmText: 'تسجيل خروج',
      cancelText: 'إلغاء',
    );
  }

  /// ✅ عرض رسالة Snackbar
  void _showSnackBar(String message, {bool isError = false}) {
    if (isError) {
      ThemeHelper.showErrorSnackBar(context, message);
    } else {
      ThemeHelper.showSuccessSnackBar(context, message);
    }
  }

  /// ✅ دالة فتح نموذج تغيير كلمة المرور
  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // كلمة المرور الحالية
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور الحالية',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // كلمة المرور الجديدة
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // تأكيد كلمة المرور
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _isChangingPassword ? null : _changePassword,
            child: _isChangingPassword
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('تغيير كلمة المرور'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : PremiumGradientBackground(
        child: FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1)
              .animate(_animationController),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // ✅ قسم معلومات الحساب
              _buildAccountInfoSection(),
              const SizedBox(height: 24),

              // ✅ قسم تقييم الصحة - يظهر للمريض فقط
              if (userRole == 'patient') ...[
                _buildHealthAssessmentSection(),
                const SizedBox(height: 24),
              ],

              // ✅ قسم الأمان
              _buildSecuritySection(),
              const SizedBox(height: 24),

              // ✅ قسم إعدادات التطبيق
              _buildAppSettingsSection(),
              const SizedBox(height: 24),

              // ✅ قسم أخرى
              _buildMiscellaneousSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ قسم معلومات الحساب
  Widget _buildAccountInfoSection() {
    return Card(
      elevation: 2,
      color: Theme.of(context).brightness == Brightness.dark
          ? MedicalTheme.darkGray900
          : MedicalTheme.pure,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات الحساب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 16),
            const SizedBox(height: 16),

            // صورة الملف الشخصي
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : null,
                    child: profileImageUrl == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      // يمكن إضافة اختيار صورة جديدة هنا
                      _showSnackBar('سيتم تطوير هذه الميزة قريباً');
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('تغيير الصورة'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // الاسم
            _buildInfoField(
              label: 'الاسم الكامل',
              value: fullName,
              icon: Icons.person,
            ),
            const SizedBox(height: 16),

            // البريد الإلكتروني
            _buildInfoField(
              label: 'البريد الإلكتروني',
              value: email,
              icon: Icons.email,
            ),
            const SizedBox(height: 16),

            // نوع الحساب
            _buildInfoField(
              label: 'نوع الحساب',
              value: userRole == 'doctor' ? 'دكتور' : 'مريض',
              icon: userRole == 'doctor' ? Icons.local_hospital : Icons.person_4,
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ قسم تقييم الصحة والأسئلة الذكية
  Widget _buildHealthAssessmentSection() {
    return Card(
      elevation: 2,
      color: Theme.of(context).brightness == Brightness.dark
          ? MedicalTheme.darkGray900
          : MedicalTheme.pure,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تقييم الصحة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 16),
            const SizedBox(height: 8),

            // وصف الخدمة
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'أجب على أسئلة ذكية عن أعراضك وحالتك الصحية للحصول على تقييم أولي والحصول على توصيات طبية',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // زر الدخول لقسم تقييم الصحة
            ListTile(
              leading: const Icon(Icons.health_and_safety),
              title: const Text('تقييم الصحة والتشخيص'),
              subtitle: const Text('أسئلة ذكية واختيار الطبيب المناسب'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HealthAssessmentScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.psychology_alt_rounded),
              title: const Text('أسئلة الذكاء الاصطناعي'),
              subtitle: const Text('فتح أسئلة الذكاء الاصطناعي يدويًا عند الحاجة'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HealthAssessmentScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ قسم الأمان
  Widget _buildSecuritySection() {
    return Card(
      elevation: 2,
      color: Theme.of(context).brightness == Brightness.dark
          ? MedicalTheme.darkGray900
          : MedicalTheme.pure,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الأمان',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 16),
            const SizedBox(height: 8),

            // زر تغيير كلمة المرور
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('تغيير كلمة المرور'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showChangePasswordDialog,
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ قسم إعدادات التطبيق
  Widget _buildAppSettingsSection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إعدادات التطبيق',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 16),
                const SizedBox(height: 8),

                // ✅ تغيير الثيمة (فاتح / داكن / نظام)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'نمط الثيمة',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('فاتح'),
                            icon: Icon(Icons.light_mode),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('داكن'),
                            icon: Icon(Icons.dark_mode),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('نظام'),
                            icon: Icon(Icons.phone_iphone),
                          ),
                        ],
                        selected: <ThemeMode>{themeProvider.themeMode},
                        onSelectionChanged: (Set<ThemeMode> newSelection) {
                          final selected = newSelection.first;
                          switch (selected) {
                            case ThemeMode.light:
                              themeProvider.setLightMode();
                              break;
                            case ThemeMode.dark:
                              themeProvider.setDarkMode();
                              break;
                            case ThemeMode.system:
                              themeProvider.setSystemMode();
                              break;
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),

                // ✅ تفعيل الإخطارات
                ListTile(
                  leading: Icon(
                    _enableNotifications
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('تفعيل الإخطارات'),
                  trailing: Switch(
                    value: _enableNotifications,
                    onChanged: (value) {
                      setState(() => _enableNotifications = value);
                    },
                  ),
                ),

              ],
            ),
          ),
        );
      },
    );
  }

  /// ✅ قسم أخرى
  Widget _buildMiscellaneousSection() {
    return Card(
      elevation: 2,
      color: Theme.of(context).brightness == Brightness.dark
          ? MedicalTheme.darkGray900
          : MedicalTheme.pure,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أخرى',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 16),
            const SizedBox(height: 8),

            // عن التطبيق
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('عن التطبيق'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AboutAppPage()),
              ),
            ),

            const Divider(),

            // سياسة الخصوصية
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('سياسة الخصوصية'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
              ),
            ),

            const Divider(),

            // شروط الاستخدام
            ListTile(
              leading: const Icon(Icons.gavel_rounded),
              title: const Text('شروط الاستخدام'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TermsOfUsePage()),
              ),
            ),

            const Divider(),

            // الدعم الفني
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('الدعم الفني'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SupportPage()),
              ),
            ),

            const Divider(),

            // تسجيل الخروج
            ListTile(
              leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
              title: Text(
                'تسجيل الخروج',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Widget لعرض حقل معلومات
  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Color.lerp(Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.secondaryContainer, .35)!
            : Color.lerp(Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.secondaryContainer, .35)!.withOpacity(.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(.64),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
