import 'package:digl/features/auth/presentation/pages/login_screen.dart';
import 'package:digl/features/auth/presentation/pages/register_screen.dart';
import 'package:digl/features/consultations/presentation/pages/consultation_screen.dart';
import 'package:digl/features/consultations/presentation/pages/incoming_call_screen.dart';
import 'package:digl/features/consultations/presentation/pages/call_page.dart';
import 'package:digl/features/home/presentation/pages/home_screen.dart';
import 'package:digl/features/medications/presentation/pages/medications_screen.dart';
import 'package:digl/features/medical_records/presentation/pages/medical_records_screen.dart';
import 'package:digl/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:digl/features/profile/presentation/pages/profile_screen.dart';
import 'package:digl/features/appointments/presentation/pages/appointments_list_screen.dart';
import 'package:digl/features/appointments/presentation/pages/book_appointment_screen.dart';
import 'package:digl/features/medical_profile/presentation/pages/health_questions_screen.dart';
import 'package:digl/features/admin/presentation/pages/admin_auth_gate.dart';
import 'package:digl/features/admin/services/admin_setup_service.dart';
import 'package:digl/firebase_options.dart';
import 'package:digl/services/appointmentNotificationService.dart';
import 'package:digl/services/appointment_service.dart';
import 'package:digl/services/medication_notification_service.dart';
import 'package:digl/services/medication_service.dart';
import 'package:digl/services/notification_service.dart';
import 'package:digl/services/internet_checker_service.dart';
import 'package:digl/services/advanced_medication_reminder_service.dart';
import 'package:digl/services/patient_medication_reminder_service.dart';
import 'package:digl/services/local_in_app_notification_service.dart';
import 'package:digl/services/chat_realtime_notification_service.dart';
import 'package:digl/services/enhanced_incoming_call_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'Provider/auth_gate.dart';
import 'core/config/medical_theme.dart';
import 'core/config/theme_provider.dart';
import 'features/admin/presentation/pages/admin_login_screen.dart';
import 'features/ai_chat/presentation/pages/medical_ai_chat_screen.dart';
import 'features/auth/presentation/pages/verification_pending_screen.dart';
import 'features/doctor/presentation/pages/doctor_dashboard_screen.dart';
import 'features/medications/presentation/pages/medication_reminder_screen.dart';
import 'features/medications/presentation/pages/medication_details_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<FirebaseApp> _ensureFirebaseInitialized() async {
  if (Firebase.apps.isNotEmpty) {
    return Firebase.app();
  }

  try {
    return await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      return Firebase.app();
    }
    rethrow;
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _ensureFirebaseInitialized();

  print("🔔 رسالة FCM بالخلفية: ${message.messageId}");
}
Future<bool> checkInternetAndWarn(BuildContext context) async {
  final hasInternet = await InternetCheckerService.hasInternet();

  if (!hasInternet) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('يرجى التحقق من اتصال الإنترنت'),
      ),
    );
  }

  return hasInternet;
}

Future<void> initializeNotifications() async {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();

  const settings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );

  await flutterLocalNotificationsPlugin.initialize(settings);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  await _ensureFirebaseInitialized();

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );



  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await initializeNotifications();
  await LocalInAppNotificationService.initialize();
  LocalInAppNotificationService.setNavigatorKey(navigatorKey);
  ChatRealtimeNotificationService().start();

  final notificationService = NotificationService();
  await notificationService.initialize();

  final medicationNotificationService = MedicationNotificationService();
  await medicationNotificationService.initialize();

  final appointmentNotificationService = AppointmentNotificationService();
  await appointmentNotificationService.initialize();

  await Hive.initFlutter();

  await AdvancedMedicationReminderService.initialize();
  await PatientMedicationReminderService.initialize();
  await PatientMedicationReminderService.rescheduleApprovedForCurrentPatient();

  await AdminSetupService.ensureAdminExists();

  /// ✅ تهيئة خدمة استقبال الاتصالات المحسّنة (تعمل في الخلفية)
  try {
    print("🔔 تهيئة خدمة استقبال الاتصالات");
    await EnhancedIncomingCallService.initialize();
    print("✅ خدمة الاتصالات جاهزة");
  } catch (e) {
    print("⚠️ تحذير: فشل تهيئة خدمة الاتصالات: $e");
  }

  /// إعداد Zego
  try {
    print("🚀 تهيئة Zego");

    ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

    ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI(
      [ZegoUIKitSignalingPlugin()],
    );

    print("✅ Zego جاهز");
  } catch (e) {
    print("❌ خطأ Zego: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        Provider(create: (_) => AppointmentService()),
        Provider(create: (_) => MedicationService()),
      ],
      child: MyApp(navigatorKey: navigatorKey),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: "صحتي",
          debugShowCheckedModeBanner: false,

          theme: MedicalTheme.lightTheme,
          darkTheme: MedicalTheme.darkTheme,
          themeMode: themeProvider.themeMode,

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          supportedLocales: const [
            Locale('ar', 'SA'),
            Locale('en', 'US'),
          ],

          locale: const Locale('ar', 'SA'),

          home: const AuthGate(),
          //AuthGate AdminLoginScreen
          routes: {
            '/login': (_) => const LoginScreen(),
            '/register': (_) => const RegisterScreen(),
            '/home': (_) => const HomeScreen(),
            '/verification_pending': (_) => const VerificationPendingScreen(),
            '/medicalrecords': (_) => const MedicalRecordsScreen(),
            '/medications': (_) => const MedicationsScreen(),
            '/medication_reminders': (_) => const MedicationReminderScreen(),
            '/appointments': (_) => AppointmentsListScreen(),
            '/book_appointment': (_) => const BookAppointmentScreen(),
            '/doctorDashboard': (_) => const DoctorDashboardScreen(),
            '/doctor_dashboard': (_) => const DoctorDashboardScreen(),
            '/profill': (_) => const ProfileScreen(),
            '/health_questions': (_) => const HealthQuestionsScreen(),
            '/medical_ai_chat': (_) => const MedicalAiChatScreen(),
            '/admin': (_) => const AdminAuthGate(),
          },

          onGenerateRoute: (settings) {
            // ✅ شاشة الاستشارة
            if (settings.name == '/consultation') {
              final args = settings.arguments as Map<String, dynamic>?;

              if (args != null) {
                return MaterialPageRoute(
                  builder: (_) => ConsultationScreen(
                    consultationId: args['consultationId'],
                    doctorUid: args['doctorId'] ?? '',
                    patientUid: args['userId'] ?? '',
                    doctorName: args['doctorName'] ?? '',
                    patientName: args['patientName'] ?? '',
                    doctorImage: args['doctorImage'],
                    userImage: args['userImage'],
                    isDoctor: args['isDoctor'],
                  ),
                );
              }
            }

            // ✅ شاشة المكالمة الواردة
            if (settings.name == '/incoming_call') {
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => IncomingCallScreen(
                    callID: args['callID'] ?? '',
                    callerID: args['callerID'] ?? '',
                    callerName: args['callerName'] ?? 'متصل',
                    callerImage: args['callerImage'],
                    isVideoCall: args['isVideoCall'] ?? true,
                    doctorID: args['doctorID'] ?? '',
                    patientID: args['patientID'] ?? '',
                  ),
                );
              }
            }

            // ✅ شاشة المكالمة
            if (settings.name == '/call') {
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => CallPage(
                    callID: args['callID'] ?? '',
                    doctorID: args['doctorID'] ?? '',
                    patientID: args['patientID'] ?? '',
                    isDoctor: args['isDoctor'] ?? true,
                    userName: args['userName'] ?? 'User',
                    isVideoCall: args['isVideoCall'] ?? true,
                  ),
                );
              }
            }

            if (settings.name == '/edit_profile') {
              final args = settings.arguments as Map<String, dynamic>?;

              return MaterialPageRoute(
                builder: (_) =>
                    EditProfileScreen(userId: args?['userId'] ?? ''),
              );
            }

            return null;
          },
        );
      },
    );
  }
}
