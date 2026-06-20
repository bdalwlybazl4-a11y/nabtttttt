import 'package:flutter/material.dart';
import 'package:digl/features/admin/services/admin_setup_service.dart';

/// 🔐 Widget لحماية واجهات الأدمن
/// يتحقق من أن المستخدم الحالي هو أدمن قبل السماح بالوصول إلى الواجهة
class AdminProtectionWidget extends StatefulWidget {
  /// الواجهة المراد حمايتها
  final Widget protectedWidget;

  /// الصلاحيات المطلوبة (اختياري)
  final List<String>? requiredPermissions;

  /// رسالة الخطأ المخصصة (اختياري)
  final String? errorMessage;

  /// رد النداء عند فشل الحماية (اختياري)
  final VoidCallback? onAccessDenied;

  const AdminProtectionWidget({
    Key? key,
    required this.protectedWidget,
    this.requiredPermissions,
    this.errorMessage,
    this.onAccessDenied,
  }) : super(key: key);

  @override
  State<AdminProtectionWidget> createState() => _AdminProtectionWidgetState();
}

class _AdminProtectionWidgetState extends State<AdminProtectionWidget> {
  late Future<bool> _accessCheck;

  @override
  void initState() {
    super.initState();
    _accessCheck = _checkAdminAccess();
  }

  /// ✅ دالة التحقق من صلاحيات الأدمن
  Future<bool> _checkAdminAccess() async {
    try {
      // 1️⃣ التحقق من أن المستخدم أدمن
      final isAdmin = await AdminSetupService.isCurrentUserAdmin();
      if (!isAdmin) {
        print('❌ المستخدم ليس أدمن');
        return false;
      }

      // 2️⃣ التحقق من الصلاحيات المطلوبة (إن وُجدت)
      if (widget.requiredPermissions != null &&
          widget.requiredPermissions!.isNotEmpty) {
        for (String permission in widget.requiredPermissions!) {
          final hasPermission =
              await AdminSetupService.hasPermission(permission);
          if (!hasPermission) {
            print('❌ الأدمن لا يملك الصلاحية: $permission');
            return false;
          }
        }
      }

      print('✅ تم التحقق من صلاحيات الأدمن بنجاح');
      return true;
    } catch (e) {
      print('❌ خطأ في التحقق من صلاحيات الأدمن: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _accessCheck,
      builder: (context, snapshot) {
        // ⏳ في حالة التحميل
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // ❌ في حالة الخطأ أو عدم الحصول على الصلاحيات
        if (snapshot.hasError || !(snapshot.data ?? false)) {
          // استدعاء رد النداء عند فشل الحماية
          Future.delayed(Duration.zero, () {
            widget.onAccessDenied?.call();
          });

          return _buildAccessDeniedScreen();
        }

        // ✅ إذا كانت جميع الفحوصات ناجحة، عرض الواجهة المحمية
        return widget.protectedWidget;
      },
    );
  }

  /// 🔄 شاشة التحميل
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'جاري التحقق من الصلاحيات...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  /// 🚫 شاشة الرفض
  Widget _buildAccessDeniedScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock,
                size: 80,
                color: Color(0xFFFF6B6B),
              ),
              const SizedBox(height: 24),
              const Text(
                'وصول محظور',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B6B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                widget.errorMessage ??
                    'عذراً، ليس لديك الصلاحيات اللازمة للوصول إلى هذه الواجهة.\n'
                    'يرجى التواصل مع مدير النظام.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('العودة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A86FF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🔐 دالة مساعدة لحماية واجهة معينة
/// الاستخدام: protectAdminScreen(yourWidget, context)
Widget protectAdminScreen(
  Widget widget, {
  List<String>? requiredPermissions,
  String? errorMessage,
  VoidCallback? onAccessDenied,
}) {
  return AdminProtectionWidget(
    protectedWidget: widget,
    requiredPermissions: requiredPermissions,
    errorMessage: errorMessage,
    onAccessDenied: onAccessDenied,
  );
}
