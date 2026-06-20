import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digl/features/consultations/presentation/pages/instant_consultation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/modern_bottom_nav_bar.dart';
import '../../../../core/widgets/premium_ui.dart';
import '../../../../core/widgets/upcoming_appointments_widget.dart';
import '../../../../services/appointment_service.dart';
import '../../../../services/health_News_Service.dart';
import '../../../../services/internet_checker_service.dart';
import '../../../../services/medication_service.dart';
import '../../../appointments/presentation/pages/appointments_list_screen.dart';
import '../../../appointments/presentation/pages/book_appointment_screen.dart';
import '../../../doctor/presentation/doctorsListWidget.dart';
import '../../../healthNews/medical_news_widget.dart';
import '../../../healthNews/medical_tips_widget.dart';
import '../../../medications/presentation/pages/medications_screen.dart';
import '../../../model.dart';
import '../../../profile/presentation/pages/profile_screen.dart';
import 'UpcomingMedicationsSection.dart';
import 'notificationsScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  bool _isConnected = true;

  String userName = "";
  String userType = "patient";
  String selectedMood = "";

  UserModel? currentUserModel;

  List<Appointment> appointments = [];
  List<Map<String, dynamic>> medications = [];
  List<HealthNewsItem> chronicTips = [], nutritionTips = [], preventionTips = [], medicalNews = [];

  int unreadNotifications = 0;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadInitialData();
  }

  Future<void> _checkConnection() async {
    _isConnected = await InternetCheckerService.hasInternet();
    setState(() {});
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _fetchCurrentUser(),
      _fetchUserData(),
      _fetchAppointments(),
      _fetchMedications(),
      _fetchHealthStats(),
      _loadTipsAndNews(),
    ]);
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> _fetchCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        currentUserModel = UserModel.fromFirestore(doc);
      });
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          userName = data['fullName']?.toString() ?? "مستخدم";
          userType = data['accountType']?.toString() ?? "patient";
          selectedMood = data['mood']?.toString() ?? "";
        });
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<void> _fetchAppointments() async {
    try {
      final appointmentService = Provider.of<AppointmentService>(context, listen: false);
      appointments = await appointmentService.getAppointments().first;
      setState(() {});
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
      appointments = [];
    }
  }

  Future<void> _fetchMedications() async {
    try {
      final medicationService = Provider.of<MedicationService>(context, listen: false);
      final userMedications = await medicationService.getMedications().first;

      medications = userMedications.take(2).map((med) {
        return {
          "id": med.id,
          "name": med.name,
          "dose": med.dose,
          "schedule": med.schedule,
          "next": med.next,
          "userId": med.userId,
          "history": med.history,
          "times": med.times,
        };
      }).toList();

      setState(() {});
    } catch (e) {
      debugPrint('Error fetching medications: $e');
      medications = [];
    }
  }
  Future<void> _fetchHealthStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final doc = await _firestore.collection('healthStats').doc(user.uid).get();
      if (doc.exists) {
        // يمكن معالجة الإحصائيات هنا إذا احتجت
      }
    } catch (e) {
      debugPrint('Error fetching health stats: $e');
    }
  }

  Future<void> _loadTipsAndNews() async {
    try {
      chronicTips = await HealthNewsService.fetchChronicDiseaseTips();
      nutritionTips = await HealthNewsService.fetchNutritionTips();
      preventionTips = await HealthNewsService.fetchPreventionTips();
      medicalNews = await HealthNewsService.fetchMedicalNews();
      setState(() {});
    } catch (e) {
      debugPrint('Error loading tips: $e');
    }
  }

  Future<void> updateMood(String mood) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'mood': mood,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        setState(() => selectedMood = mood);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث حالتك المزاجية بنجاح')),
        );
      }
    } catch (e) {
      debugPrint('Error updating mood: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحديث الحالة المزاجية: $e')),
      );
    }
  }

  PreferredSizeWidget buildAppBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        "نبض",
        style: theme.textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        Stack(
          children: [
            Container(
              margin: const EdgeInsetsDirectional.only(end: 8, top: 6, bottom: 6),
              decoration: BoxDecoration(
                color: Color.lerp(colorScheme.primaryContainer, colorScheme.secondaryContainer, .35)!.withOpacity(0.78),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.35)),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.notifications_none_rounded, color: colorScheme.primary),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
              ),
            ),
            if (unreadNotifications > 0)
              Positioned(
                right: 12,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unreadNotifications.toString(),
                    style: TextStyle(
                      color: colorScheme.onError,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || currentUserModel == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _currentIndex == 0 ? buildAppBar() : null,
      body: SafeArea(
        bottom: false,
        child: PremiumGradientBackground(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 118),
          child: IndexedStack(
          index: _currentIndex,
          children: [
            RefreshIndicator(
              onRefresh: _loadInitialData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    WelcomeMoodSection(
                      userName: userName,
                      userType: userType,
                      selectedMood: selectedMood,
                      onMoodSelected: updateMood,
                    ),
                    UpcomingAppointmentsWidget(appointments: appointments),
                    if (currentUserModel!.isPatient)
                      UpcomingMedicationsSection(medications: medications),
                    if (currentUserModel!.isPatient) const DoctorsListWidget(),
                    const MedicalTipsWidget(),
                    const MedicalNewsWidget(),
                  ],
                ),
              ),
            ),
            currentUserModel!.isPatient
                ? const BookAppointmentScreen()
                : const AppointmentsListScreen(),
            const InstantConsultationScreen(),
            currentUserModel!.isPatient
                ? const MedicationsScreen()
                : const AppointmentsListScreen(),
            const ProfileScreen(),
          ],
        ),
        ),
      ),
      ),
      extendBody: true,
      floatingActionButton: currentUserModel!.isPatient
          ? FloatingActionButton.extended(
              heroTag: 'global_ai_chat_fab',
              elevation: 0,
              highlightElevation: 0,
              onPressed: () => Navigator.of(context).pushNamed('/medical_ai_chat'),
              icon: const Icon(Icons.smart_toy_rounded),
              label: const Text('مساعد AI'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: ModernBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavItem(icon: Icons.home_rounded, label: 'الرئيسية'),
          const BottomNavItem(icon: Icons.calendar_month_rounded, label: 'المواعيد'),
          const BottomNavItem(icon: Icons.auto_awesome_rounded, label: 'استشارة'),
          BottomNavItem(
            icon: currentUserModel!.isPatient
                ? Icons.medication_liquid_rounded
                : Icons.fact_check_rounded,
            label: currentUserModel!.isPatient ? 'الأدوية' : 'الطلبات',
          ),
          const BottomNavItem(icon: Icons.person_rounded, label: 'حسابي'),
        ],
      ),
    );
  }
}

/// ===========================
/// Welcome & Mood Section Widget
/// ===========================
class WelcomeMoodSection extends StatelessWidget {
  final String userName;
  final String userType;
  final String selectedMood;
  final void Function(String) onMoodSelected;

  const WelcomeMoodSection({
    super.key,
    required this.userName,
    required this.userType,
    required this.selectedMood,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return PremiumSurface(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      padding: const EdgeInsets.all(18),
      radius: 32,
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          colorScheme.primary.withOpacity(theme.brightness == Brightness.dark ? .42 : .92),
          colorScheme.secondary.withOpacity(theme.brightness == Brightness.dark ? .22 : .72),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -18,
            top: -18,
            child: Icon(
              Icons.blur_on_rounded,
              size: 118,
              color: colorScheme.onPrimary.withOpacity(.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withOpacity(.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.onPrimary.withOpacity(.18)),
                    ),
                    child: Icon(Icons.health_and_safety_rounded, color: colorScheme.onPrimary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userType == 'patient' ? "مرحباً، $userName" : "مرحباً، دكتور $userName",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "مساعدك الصحي الذكي جاهز لمتابعة يومك",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimary.withOpacity(.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (userType == 'patient') ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withOpacity(.10),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colorScheme.onPrimary.withOpacity(.14)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "كيف تشعر اليوم؟",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMoodButton(Icons.sentiment_very_satisfied_rounded, "ممتاز", theme),
                          _buildMoodButton(Icons.sentiment_satisfied_rounded, "جيد", theme),
                          _buildMoodButton(Icons.sentiment_neutral_rounded, "عادي", theme),
                          _buildMoodButton(Icons.sentiment_dissatisfied_rounded, "سيء", theme),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodButton(IconData icon, String label, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final isSelected = selectedMood == label;
    return SizedBox(
      width: 112,
      child: ElevatedButton.icon(
        onPressed: () => onMoodSelected(label),
        icon: Icon(icon, color: isSelected ? colorScheme.primary : colorScheme.onPrimary),
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.primary : colorScheme.onPrimary,
            fontSize: 12,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? colorScheme.onPrimary : colorScheme.onPrimary.withOpacity(0.12),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: BorderSide(color: colorScheme.onPrimary.withOpacity(isSelected ? 0 : .24)),
        ),
      ),
    );
  }
}
