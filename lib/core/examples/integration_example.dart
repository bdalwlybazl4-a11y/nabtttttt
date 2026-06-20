/// 📚 مثال عملي لاستخدام جميع الميزات الجديدة معاً
/// يوضح هذا الملف كيفية دمج:
/// - نظام الصلاحيات
/// - Bottom Navigation Bar المحسّنة
/// - Animations والانتقالات
/// - صفحة الإعدادات الاحترافية

import 'package:flutter/material.dart';
import 'package:digl/services/user_role_service.dart';
import 'package:digl/core/widgets/modern_bottom_nav_bar.dart';
import 'package:digl/core/utils/animations_utils.dart';
import 'package:digl/features/settings/presentation/pages/settings_screen.dart';
import 'package:digl/core/config/theme.dart';

/// ✅ مثال على شاشة رئيسية محسّنة مع جميع الميزات
class EnhancedHomeScreenExample extends StatefulWidget {
  const EnhancedHomeScreenExample({Key? key}) : super(key: key);

  @override
  State<EnhancedHomeScreenExample> createState() =>
      _EnhancedHomeScreenExampleState();
}

class _EnhancedHomeScreenExampleState extends State<EnhancedHomeScreenExample> {
  int _currentIndex = 0;
  bool _isDoctor = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  /// ✅ التحقق من نوع المستخدم
  Future<void> _checkUserRole() async {
    final isDoctor = await UserRoleService.isDoctor();
    setState(() {
      _isDoctor = isDoctor;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الصفحة الرئيسية'),
        elevation: 0,
        actions: [
          // ✅ زر الإعدادات مع Animated Button
          AnimatedButton(
            onTap: () {
              // استخدام انتقال مع Fade
              navigateFade(context, const SettingsScreen());
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.settings,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
      body: _buildContent(),
      // ✅ Bottom Navigation Bar المحسّنة
      bottomNavigationBar: ModernBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: [
          BottomNavItem(label: 'الرئيسية', icon: Icons.home),
          BottomNavItem(label: 'الأدوية', icon: Icons.medication),
          BottomNavItem(label: 'المواعيد', icon: Icons.calendar_today),
          BottomNavItem(label: 'الملف الشخصي', icon: Icons.person),
        ],
      ),
    );
  }

  /// ✅ بناء محتوى الصفحة حسب الـ Tab المختار
  Widget _buildContent() {
    // ✅ استخدام FadeInAnimation لعرض المحتوى
    return FadeInAnimation(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getTabTitle(_currentIndex),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // ✅ رسالة مختلفة حسب نوع المستخدم
            if (_isDoctor)
              _buildDoctorCard()
            else
              _buildPatientCard(),

            const SizedBox(height: 24),

            // ✅ زر عام مع Animated Button
            AnimatedButton(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم الضغط على الزر')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlue, Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'اضغط هنا',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ بطاقة خاصة بالأطباء
  Widget _buildDoctorCard() {
    return AnimatedCard(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_hospital,
              size: 48,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(height: 12),
            const Text(
              'أهلاً وسهلاً بك دكتور/ة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'يمكنك إضافة الأدوية ووصفها للمرضى',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ بطاقة خاصة بالمرضى
  Widget _buildPatientCard() {
    return AnimatedCard(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.positiveGreen.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite,
              size: 48,
              color: AppTheme.positiveGreen,
            ),
            const SizedBox(height: 12),
            const Text(
              'أهلاً وسهلاً بك في تطبيقنا',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'استخدم التطبيق للاستشارة وإدارة أدويتك',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ الحصول على عنوان الـ Tab
  String _getTabTitle(int index) {
    const titles = [
      'الصفحة الرئيسية',
      'إدارة الأدوية',
      'سجل المواعيد',
      'الملف الشخصي',
    ];
    return titles[index];
  }
}

/// ✅ مثال على استخدام جميع أنواع الانتقالات
class TransitionsExampleScreen extends StatelessWidget {
  const TransitionsExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أمثلة الانتقالات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ Fade Transition
          ElevatedButton(
            onPressed: () {
              navigateFade(
                context,
                const Scaffold(
                  body: Center(child: Text('Fade Transition')),
                ),
              );
            },
            child: const Text('Fade Transition'),
          ),
          const SizedBox(height: 12),

          // ✅ Slide Right Transition
          ElevatedButton(
            onPressed: () {
              navigateSlideRight(
                context,
                const Scaffold(
                  body: Center(child: Text('Slide Right Transition')),
                ),
              );
            },
            child: const Text('Slide Right Transition'),
          ),
          const SizedBox(height: 12),

          // ✅ Slide Left Transition
          ElevatedButton(
            onPressed: () {
              navigateSlideLeft(
                context,
                const Scaffold(
                  body: Center(child: Text('Slide Left Transition')),
                ),
              );
            },
            child: const Text('Slide Left Transition'),
          ),
          const SizedBox(height: 12),

          // ✅ Scale Transition
          ElevatedButton(
            onPressed: () {
              navigateScale(
                context,
                const Scaffold(
                  body: Center(child: Text('Scale Transition')),
                ),
              );
            },
            child: const Text('Scale Transition'),
          ),
        ],
      ),
    );
  }
}

/// ✅ مثال على استخدام الـ Animations Widgets
class AnimationsWidgetsExample extends StatelessWidget {
  const AnimationsWidgetsExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animations Widgets')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ Pulse Animation
          Center(
            child: PulseAnimation(
              child: Icon(
                Icons.favorite,
                color: Colors.red,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ✅ FadeIn Animation
          FadeInAnimation(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'هذا نص يظهر مع حركة Fade In السلسة',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ✅ Animated Card مع Hover Effect
          AnimatedCard(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'حرك الماوس فوق هذه البطاقة لرؤية التأثير',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ مثال على استخدام نظام الصلاحيات
class PermissionsExampleScreen extends StatefulWidget {
  const PermissionsExampleScreen({Key? key}) : super(key: key);

  @override
  State<PermissionsExampleScreen> createState() =>
      _PermissionsExampleScreenState();
}

class _PermissionsExampleScreenState extends State<PermissionsExampleScreen> {
  bool _isDoctor = false;
  bool _canAddMedications = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  /// ✅ تحميل الصلاحيات
  Future<void> _loadPermissions() async {
    final isDoc = await UserRoleService.isDoctor();
    final canAdd = await UserRoleService.canAddMedication();

    setState(() {
      _isDoctor = isDoc;
      _canAddMedications = canAdd;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('نظام الصلاحيات')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'معلومات المستخدم:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('نوع الحساب: ${_isDoctor ? "دكتور" : "مريض"}'),
                    const SizedBox(height: 8),
                    Text(
                      'صلاحية إضافة الأدوية: ${_canAddMedications ? "✅ نعم" : "❌ لا"}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ✅ زر يظهر فقط للأطباء
            if (_canAddMedications) ...[
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم الضغط على زر إضافة دواء')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('إضافة دواء جديد'),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Text(
                  'فقط الأطباء يمكنهم إضافة الأدوية',
                  style: TextStyle(color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
