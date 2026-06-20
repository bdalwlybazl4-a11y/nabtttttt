import 'package:digl/features/admin/models/admin_models.dart';
import 'package:digl/features/admin/presentation/pages/admin_login_screen.dart';
import 'package:digl/features/admin/presentation/pages/doctor_requests_screen.dart';
import 'package:digl/features/admin/services/admin_service.dart';
import 'package:digl/features/admin/services/admin_report_service.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AdminUser admin;

  const AdminDashboardScreen({super.key, required this.admin});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color _adminBackground = Color(0xFFF6F8FC);
  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF101828);
  static const Color _mutedTextColor = Color(0xFF667085);
  static const Color _borderColor = Color(0xFFE6ECF5);

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _adminBackground,
      appBar: _buildAppBar(theme),
      body: Theme(
        data: theme.copyWith(
          scaffoldBackgroundColor: _adminBackground,
          cardColor: _cardColor,
          iconTheme: const IconThemeData(color: _textColor),
          textTheme: theme.textTheme.apply(bodyColor: _textColor, displayColor: _textColor),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: IndexedStack(
            key: ValueKey(_currentIndex),
            index: _currentIndex,
            children: [
              _buildDashboardContent(theme),
              const DoctorRequestsScreen(),
              _buildSettingsContent(theme),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF1E4FBF),
        unselectedItemColor: _mutedTextColor,
        backgroundColor: _cardColor,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.space_dashboard_rounded),
            label: 'لوحة التحكم',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in_rounded),
            label: 'طلبات الأطباء',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_suggest_rounded),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const [Color(0xFF1E4FBF), Color(0xFF123A8C)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
      ),
      title: const Text('لوحة التحكم الإدارية'),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_active_outlined),
          onPressed: _showComingSoon,
        ),
        IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: _showAdminProfile,
        ),
      ],
    );
  }

  Widget _buildDashboardContent(ThemeData theme) {
    return StreamBuilder<AdminStats>(
      stream: AdminService.watchAdminStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text('حدث خطأ في تحميل البيانات', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        final stats = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWelcomeCard(theme),
                const SizedBox(height: 18),
                _buildStatsGrid(stats, theme),
                const SizedBox(height: 18),
                _buildPendingRequestsCard(stats, theme),
                const SizedBox(height: 18),
                _buildInsightsSection(stats, theme),
                const SizedBox(height: 18),
                _buildQuickActionsCard(theme, stats),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, const Color(0xFF4D7CFE)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: _cardColor, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً، ${widget.admin.fullName}',
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.admin.role == 'super_admin' ? 'مسؤول عام • كامل الصلاحيات' : 'مسؤول • صلاحيات تشغيلية',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.insights_rounded, color: _cardColor, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تابع مؤشرات النظام وراجع الطلبات الجديدة بسرعة.',
                    style: TextStyle(color: _cardColor, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AdminStats stats, ThemeData theme) {
    final statsList = [
      {'title': 'إجمالي الأطباء', 'value': stats.totalDoctors.toString(), 'icon': Icons.local_hospital_rounded, 'color': const Color(0xFF3A86FF)},
      {'title': 'طلبات معلقة', 'value': stats.pendingRequests.toString(), 'icon': Icons.pending_actions_rounded, 'color': const Color(0xFFFFA62B)},
      {'title': 'أطباء موافق عليهم', 'value': stats.approvedDoctors.toString(), 'icon': Icons.verified_user_rounded, 'color': const Color(0xFF2CB67D)},
      {'title': 'إجمالي المرضى', 'value': stats.totalPatients.toString(), 'icon': Icons.groups_rounded, 'color': const Color(0xFF7B61FF)},
      {'title': 'إجمالي المواعيد', 'value': stats.totalAppointments.toString(), 'icon': Icons.calendar_month_rounded, 'color': const Color(0xFF00A6A6)},
      {'title': 'متوسط التقييم', 'value': stats.averageDoctorRating.toStringAsFixed(1), 'icon': Icons.star_rate_rounded, 'color': const Color(0xFFFFC857)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.08,
      ),
      itemCount: statsList.length,
      itemBuilder: (context, index) {
        final item = statsList[index];
        final color = item['color'] as Color;

        return Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.14),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item['icon'] as IconData, color: color, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['value'] as String,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['title'] as String,
                    style: const TextStyle(fontSize: 12.5, color: _mutedTextColor, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingRequestsCard(AdminStats stats, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4E3), Color(0xFFFFFBF3)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD6A2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA62B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: _cardColor, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('طلبات تحتاج مراجعة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textColor)),
                      const SizedBox(height: 4),
                      Text(
                        'يوجد ${stats.pendingRequests} طلب بانتظار قرارك الآن',
                        style: const TextStyle(fontSize: 13.5, color: _mutedTextColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => setState(() => _currentIndex = 1),
              icon: const Icon(Icons.arrow_circle_left_outlined),
              label: const Text('الانتقال إلى الطلبات'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFFFFA62B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildInsightsSection(AdminStats stats, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildReportsCard(stats, theme),
        const SizedBox(height: 14),
        _buildModernCharts(stats, theme),
      ],
    );
  }

  Widget _buildReportsCard(AdminStats stats, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF7B61FF).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF7B61FF)),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('تقارير PDF احترافية', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textColor))),
            ],
          ),
          const SizedBox(height: 8),
          const Text('يشمل التقرير المرضى، الأطباء، الاستشارات، الحجوزات، التقييمات الصحية، وأكثر التخصصات والأطباء استخداماً.', style: TextStyle(color: _mutedTextColor, height: 1.5)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _printReport(stats),
            icon: const Icon(Icons.print_rounded),
            label: const Text('تحميل أو طباعة التقرير'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B61FF), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCharts(AdminStats stats, ThemeData theme) {
    return Card(
      elevation: 0,
      color: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('رسوم بيانية مباشرة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
            const SizedBox(height: 14),
            _buildHorizontalBars('أكثر التخصصات طلباً', stats.topSpecialties, const Color(0xFF3A86FF)),
            const SizedBox(height: 18),
            _buildHorizontalBars('أكثر الأطباء حجزاً', stats.topDoctors, const Color(0xFF2CB67D)),
            const SizedBox(height: 18),
            _buildMiniPie(stats),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalBars(String title, Map<String, int> values, Color color) {
    final maxValue = values.values.fold<int>(0, (max, value) => value > max ? value : max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: _textColor)),
        const SizedBox(height: 8),
        if (values.isEmpty)
          const Text('لا توجد بيانات كافية حالياً', style: TextStyle(color: _mutedTextColor))
        else
          ...values.entries.map((entry) {
            final factor = maxValue == 0 ? 0.0 : entry.value / maxValue;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(width: 92, child: Text(entry.key, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _mutedTextColor, fontWeight: FontWeight.w700))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: factor,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(entry.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: _textColor)),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMiniPie(AdminStats stats) {
    final total = (stats.totalPatients + stats.totalDoctors + stats.totalConsultations + stats.totalAppointments).clamp(1, 1 << 31);
    final patient = stats.totalPatients / total;
    final doctor = stats.totalDoctors / total;
    final consultations = stats.totalConsultations / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pie Chart لتوزيع النشاط', style: TextStyle(fontWeight: FontWeight.w800, color: _textColor)),
        const SizedBox(height: 10),
        Row(
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: CircularProgressIndicator(
                strokeWidth: 13,
                value: patient,
                backgroundColor: const Color(0xFF2CB67D).withOpacity(doctor + consultations),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3A86FF)),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _legend('المرضى', const Color(0xFF3A86FF), stats.totalPatients),
                  _legend('الأطباء', const Color(0xFF2CB67D), stats.totalDoctors),
                  _legend('الاستشارات', const Color(0xFFFFA62B), stats.totalConsultations),
                  _legend('الحجوزات', const Color(0xFF7B61FF), stats.totalAppointments),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legend(String label, Color color, int value) {
    return Chip(
      avatar: CircleAvatar(backgroundColor: color, radius: 5),
      label: Text('$label: $value', style: const TextStyle(color: _textColor, fontWeight: FontWeight.w600)),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildQuickActionsCard(ThemeData theme, AdminStats stats) {
    final actions = [
      {'icon': Icons.assignment_rounded, 'label': 'الطلبات', 'color': const Color(0xFF3A86FF), 'tap': () => setState(() => _currentIndex = 1)},
      {'icon': Icons.person_add_alt_1_rounded, 'label': 'إضافة مسؤول', 'color': const Color(0xFF2CB67D), 'tap': _showComingSoon},
      {'icon': Icons.picture_as_pdf_rounded, 'label': 'PDF', 'color': const Color(0xFF7B61FF), 'tap': () => _printReport(stats)},
    ];

    return Card(
      elevation: 0,
      color: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('إجراءات سريعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.95,
              children: actions.map((action) {
                final color = action['color'] as Color;
                return InkWell(
                  onTap: action['tap'] as VoidCallback,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: color.withOpacity(0.1),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(action['icon'] as IconData, color: color, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          action['label'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsContent(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: _cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: _borderColor)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('معلومات الحساب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textColor)),
                const SizedBox(height: 16),
                _buildInfoRow('الاسم', widget.admin.fullName, theme),
                _buildInfoRow('البريد الإلكتروني', widget.admin.email, theme),
                _buildInfoRow('رقم الهاتف', widget.admin.phoneNumber, theme),
                _buildInfoRow('الدور', widget.admin.role == 'super_admin' ? 'مسؤول عام' : 'مسؤول', theme),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('تسجيل الخروج'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, color: _mutedTextColor),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700, color: _textColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printReport(AdminStats stats) async {
    await AdminReportService.printDashboardReport(admin: widget.admin, stats: stats);
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('هذه الميزة ستكون متاحة قريباً.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAdminProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ملف المسؤول', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textColor)),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.person_outline, color: _mutedTextColor),
              title: const Text('الملف الشخصي', style: TextStyle(color: _textColor, fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.security_outlined, color: _mutedTextColor),
              title: const Text('الأمان', style: TextStyle(color: _textColor, fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.support_agent_outlined, color: _mutedTextColor),
              title: const Text('الدعم والمساعدة', style: TextStyle(color: _textColor, fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لا'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AdminService.logoutAdmin();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AdminLoginScreen(),
        ),
      );
    }
  }
}