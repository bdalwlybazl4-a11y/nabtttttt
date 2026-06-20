import 'dart:convert';
import 'package:digl/features/profile/presentation/pages/supportScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digl/features/settings/presentation/pages/settings_screen.dart';
import 'package:digl/services/logout_service.dart';

import '../../../appointments/presentation/pages/appointments_list_screen.dart';
import '../../../medications/presentation/pages/medication_form.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Color get _pageBackground => Theme.of(context).scaffoldBackgroundColor;
  Color get _primary => Theme.of(context).colorScheme.primary;
  Color get _primaryDark => Theme.of(context).colorScheme.primary.withOpacity(0.85);
  Color get _text => Theme.of(context).colorScheme.onSurface;
  Color get _muted => Theme.of(context).colorScheme.onSurface.withOpacity(.64);
  Color get _cardBorder => Theme.of(context).dividerColor.withOpacity(0.35);
  Color get _profileCardColor => Theme.of(context).cardColor;

  String? userId;
  bool isLoading = true;

  String fullName = '';
  String email = '';
  String phone = '';
  String gender = '';
  int? age;
  String workPlace = '';
  String? profileImageUrl;
  String? profileImageBase64;
  bool isDoctor = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    userId = user.uid;
    email = user.email ?? '';

    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) {
      setState(() => isLoading = false);
      return;
    }

    final data = doc.data()!;
    setState(() {
      fullName = (data['fullName'] ?? data['name'] ?? '').toString();
      phone = (data['phone'] ?? data['phoneNumber'] ?? '').toString();
      gender = (data['gender'] ?? '').toString();
      age = int.tryParse(data['age']?.toString() ?? '');
      workPlace = (data['workPlace'] ?? data['clinicName'] ?? '').toString();
      profileImageUrl = (data['photoURL'] ?? data['profileImage'] ?? '').toString();
      profileImageBase64 = (data['profileImageBase64'] ?? '').toString();
      isDoctor = data['accountType'] == 'doctor';
      isLoading = false;
    });
  }

  Future<void> _openEditProfile() async {
    if (userId == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(userId: userId!)),
    );
    if (mounted) _loadUserProfile();
  }

  Future<void> _logout() async {
    await LogoutService.showLogoutConfirmationDialog(context);
  }

  Future<void> _openSupport() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SupportScreen()),
    );
  }

  Future<void> _launchSupportEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@digl.com',
      queryParameters: {
        'subject': 'طلب دعم فني - $fullName',
        'body': 'السلام عليكم،\n\nأحتاج إلى مساعدة بخصوص...',
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن فتح تطبيق البريد')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: _pageBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final displayName = fullName.trim().isEmpty ? 'مستخدم نبض' : fullName.trim();

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.paddingOf(context).bottom + 72),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderBar(),
                const SizedBox(height: 14),
                _buildProfileHero(displayName),
                const SizedBox(height: 14),
                _buildInfoSummary(),
                const SizedBox(height: 18),
                Text(
                  'الخدمات',
                  style: TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                _buildServicesList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          style: IconButton.styleFrom(
            backgroundColor: _profileCardColor,
            foregroundColor: _text,
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'الملف الشخصي',
            style: TextStyle(color: _text, fontSize: 22, fontWeight: FontWeight.w900),
          ),
        ),
        FilledButton.icon(
          onPressed: _openEditProfile,
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text('تعديل'),
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHero(String displayName) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryDark, _primary, _primary.withOpacity(0.72)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.85), width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 8)),
                  ],
                ),
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: Colors.white.withOpacity(0.18),
                  backgroundImage: _profileImageProvider(),
                  child: _profileImageProvider() != null
                      ? null
                      : Text(
                    _initials(displayName),
                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              Positioned(
                bottom: -4,
                right: -2,
                child: Material(
                  color: _profileCardColor,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _openEditProfile,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.camera_alt_rounded, color: _primary, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            email.isEmpty ? 'لا يوجد بريد إلكتروني' : email,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: 14),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroBadge(isDoctor ? 'طبيب' : 'مريض', isDoctor ? Icons.local_hospital_rounded : Icons.favorite_rounded),
              _heroBadge(phone.isNotEmpty ? phone : 'رقم غير مضاف', Icons.phone_rounded),
              _heroBadge(age != null && age! > 0 ? '$age سنة' : 'العمر غير محدد', Icons.cake_rounded),
            ],
          ),
        ],
      ),
    );
  }


  ImageProvider? _profileImageProvider() {
    if (profileImageBase64 != null && profileImageBase64!.isNotEmpty) {
      return MemoryImage(base64Decode(profileImageBase64!));
    }
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      return NetworkImage(profileImageUrl!);
    }
    return null;
  }

  Widget _buildInfoSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _profileCardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _smallIcon(Icons.verified_user_rounded, _primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text('بيانات الحساب', style: TextStyle(color: _text, fontSize: 17, fontWeight: FontWeight.w900)),
              ),
              TextButton.icon(
                onPressed: _openEditProfile,
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: const Text('تعديل الصورة'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _infoCard(Icons.person_outline_rounded, 'الجنس', gender.isNotEmpty ? gender : 'غير محدد')),
              const SizedBox(width: 10),
              Expanded(child: _infoCard(Icons.badge_outlined, 'نوع الحساب', isDoctor ? 'طبيب' : 'مريض')),
            ],
          ),
          if (isDoctor) ...[
            const SizedBox(height: 10),
            _wideInfoCard(Icons.business_center_outlined, 'مكان العمل', workPlace.isNotEmpty ? workPlace : 'غير محدد'),
          ],
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    return Column(
      children: [
        _modernOptionTile(
          icon: Icons.calendar_month_rounded,
          title: 'سجل المواعيد',
          subtitle: 'جميع المواعيد الحالية والسابقة',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppointmentsListScreen()),
          ),
        ),
        if (isDoctor)
          _modernOptionTile(
            icon: Icons.dashboard_rounded,
            title: 'لوحة تحكم الطبيب',
            subtitle: 'إدارة لوحة الطبيب والإحصائيات',
            onTap: () => Navigator.pushNamed(context, '/doctor_dashboard'),
          ),
        if (isDoctor && userId != null)
          _modernOptionTile(
            icon: Icons.medication_rounded,
            title: 'إضافة دواء للمريض',
            subtitle: 'إنشاء وصفة دوائية جديدة وإرسالها للمريض',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MedicationFormScreen(userId: userId!)),
            ),
          ),
        _modernOptionTile(
          icon: Icons.support_agent_rounded,
          title: 'الدعم الفني',
          subtitle: 'تواصل مباشر أو عبر البريد الإلكتروني',
          onTap: _openSupport,
          trailing: IconButton(
            onPressed: _launchSupportEmail,
            icon: Icon(Icons.email_outlined, color: _primary),
          ),
        ),
        _modernOptionTile(
          icon: Icons.settings_rounded,
          title: 'الإعدادات',
          subtitle: 'الثيم، الإشعارات، والخيارات العامة',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          ),
        ),
        _modernOptionTile(
          icon: Icons.logout_rounded,
          title: 'تسجيل الخروج',
          subtitle: 'إنهاء الجلسة الحالية بأمان',
          onTap: _logout,
          danger: true,
        ),
      ],
    );
  }

  Widget _heroBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.lerp(Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.secondaryContainer, .35)!.withOpacity(0.38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _smallIcon(icon, _primary),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(color: _text, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _wideInfoCard(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.lerp(Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.secondaryContainer, .35)!.withOpacity(0.38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          _smallIcon(icon, _primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(value, style: TextStyle(color: _text, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _modernOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
    Widget? trailing,
  }) {
    final iconColor = danger ? Theme.of(context).colorScheme.error : _primary;
    final bgColor = danger ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.35) : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _profileCardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: TextStyle(color: danger ? iconColor : _text, fontWeight: FontWeight.w900)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: TextStyle(color: _muted, fontSize: 12.5)),
        ),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, size: 16, color: danger ? iconColor : _muted),
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'ن';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}