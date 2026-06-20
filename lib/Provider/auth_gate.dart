// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:digl/Provider/underReviewScreen.dart';
// import 'package:digl/features/auth/presentation/pages/login_screen.dart';
// import 'package:digl/features/home/presentation/pages/home_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
// import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
//
// /// 🔁 نستخدم هذا المتغير لمنع التهيئة المتكررة لـ Zego
// bool _zegoInitialized = false;
//
// /// ✅ دالة تهيئة Zego لمرة واحدة فقط
// Future<void> initZegoIfNeeded({
//   required String userID,
//   required String userName,
// }) async {
//   if (_zegoInitialized) return;
//   _zegoInitialized = true;
//
//   ZegoUIKitPrebuiltCallInvitationService().init(
//     appID: 472822999, // App ID من ZegoCloud
//     appSign:
//     'ce9c9c64bb1ec7a06fcdb15e4fe94fa6e4ff221b9630569c3e362913ce9d0286', // App Sign من ZegoCloud
//     userID: userID,
//     userName: userName,
//     plugins: [ZegoUIKitSignalingPlugin()],
//   );
// }
//
// class AuthGate extends StatelessWidget {
//   const AuthGate({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return const Scaffold(
//             body: Center(
//               child: Text('حدث خطأ ما. حاول مرة أخرى.',
//                   style: TextStyle(color: Colors.red)),
//             ),
//           );
//         }
//
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//               body: Center(child: CircularProgressIndicator()));
//         }
//
//         final user = snapshot.data;
//         if (user == null) return const LoginScreen();
//
//         return FutureBuilder<DocumentSnapshot>(
//           future: FirebaseFirestore.instance
//               .collection('users')
//               .doc(user.uid)
//               .get(),
//           builder: (context, userSnapshot) {
//             if (userSnapshot.connectionState == ConnectionState.waiting) {
//               return const Scaffold(
//                   body: Center(child: CircularProgressIndicator()));
//             }
//
//             if (userSnapshot.hasError ||
//                 !userSnapshot.hasData ||
//                 !userSnapshot.data!.exists) {
//               return const LoginScreen();
//             }
//
//             final userData =
//             userSnapshot.data!.data() as Map<String, dynamic>;
//             final accountType = userData['accountType'] ?? 'patient';
//             final userName =
//                 userData['fullName'] ?? 'User_${user.uid.substring(0, 5)}';
//
//             /// ✅ تهيئة Zego لمرة واحدة
//             initZegoIfNeeded(userID: user.uid, userName: userName);
//
//             if (accountType == 'doctor') {
//               final isVerified = userData['isVerified'] == true;
//               final hasLicense = userData['hasLicenseDocuments'] == true;
//
//               if (!isVerified || !hasLicense) {
//                 return const UnderReviewScreen(); // طبيب غير موثق
//               }
//
//               return const HomeScreen(); // طبيب موثق
//             }
//
//             return const HomeScreen(); // مريض
//           },
//         );
//       },
//     );
//   }
// }
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digl/Provider/underReviewScreen.dart';
import 'package:digl/features/auth/presentation/pages/login_screen.dart';
import 'package:digl/features/home/presentation/pages/home_screen.dart';
import 'package:digl/features/medical_profile/presentation/pages/health_questions_screen.dart';
import 'package:digl/features/medical_profile/services/medical_profile_service.dart';
import 'package:digl/services/zego_call_service.dart';
import 'package:digl/services/zego_incoming_call_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/connectivity_service.dart';

/// ✅ تهيئة Zego عند الحاجة
/// هذه الدالة تقوم بـ:
/// 1. تهيئة خدمة المكالمات من Zego
/// 2. تهيئة معالج المكالمات الواردة
/// 3. التحقق من الاتصال بالإنترنت
Future<void> initZegoIfNeeded({
  required String userID,
  required String userName,
}) async {
  // ✅ تخطي إذا كانت Zego مهيأة بالفعل
  if (ZegoCallService.isInitialized) {
    print('✅ Zego مهيأ بالفعل');
    return;
  }

  // ✅ التحقق من الاتصال بالإنترنت
  final isConnected = await ConnectivityService.isConnected();
  if (!isConnected) {
    print('⚠️ لا يوجد اتصال - تخطي تهيئة Zego');
    return;
  }

  print('🔄 جاري تهيئة Zego لـ $userID...');

  // ✅ تهيئة Zego باستخدام الخدمة المحسّنة
  final initialized = await ZegoCallService.initialize(
    userID: userID,
    userName: userName,
  );

  if (initialized) {
    print('✅ تم تهيئة خدمة Zego بنجاح');

    // ✅ تهيئة معالج المكالمات الواردة
    try {
      await ZegoIncomingCallHandler.initialize();
      print('✅ تم تهيئة معالج المكالمات الواردة');
    } catch (e) {
      print('⚠️ تحذير: فشل تهيئة معالج المكالمات: $e');
    }

    // ⏱️ انتظر قليلاً لضمان الاتصال الكامل
    await Future.delayed(const Duration(seconds: 1));
  } else {
    print('⚠️ تحذير: فشل تهيئة خدمة Zego (قد تعمل بدونها)');
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isConnected = true;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _setupConnectivityListener();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel(); // تأكد من إلغاء الاشتراك:cite[4]
    super.dispose();
  }

  Future<void> _checkInitialConnection() async {
    final connected = await ConnectivityService.isConnected();
    if (mounted) {
      setState(() => _isConnected = connected);
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(
              (ConnectivityResult result) {
            final connected = result != ConnectivityResult.none;

            if (!mounted) return;

            setState(() => _isConnected = connected);

            if (!connected) {
              ConnectivityService.showNoInternetSnackBar(context);
            } else {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.wifi, color: Colors.white),
                      SizedBox(width: 8),
                      Text('تم استعادة الاتصال بالإنترنت'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        );
  }


  @override
  Widget build(BuildContext context) {
    if (!_isConnected) {
      return _buildNoInternetScreen();
    }
    return _buildAuthContent();
  }

  Widget _buildNoInternetScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              const Text(
                'غير متصل بالإنترنت',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'يجب أن يكون جهازك متصلاً بالإنترنت لاستخدام التطبيق.\n'
                    'يرجى التحقق من اتصال Wi-Fi أو بيانات الجوال.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _checkInitialConnection,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthContent() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorScreen('حدث خطأ ما. حاول مرة أخرى.');
        if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingScreen();

        final user = snapshot.data;
        if (user == null) return const LoginScreen();

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) return _buildLoadingScreen();
            if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const LoginScreen();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final accountType = userData['accountType'] ?? 'patient';
            final userName = userData['fullName'] ?? 'User_${user.uid.substring(0, 5)}';

            if (_isConnected) {
              initZegoIfNeeded(userID: user.uid, userName: userName);
            }

            if (accountType == 'doctor') {
              final isVerified = userData['isVerified'] == true;
              final hasLicense = userData['hasLicenseDocuments'] == true;
              if (!isVerified || !hasLicense) return const UnderReviewScreen();
              return const HomeScreen();
            }

            // للمريض: التحقق من وجود الملف الصحي فقط
            // ملاحظة: أسئلة الذكاء الاصطناعي أصبحت متاحة يدويًا من شاشة الإعدادات.
            if (accountType == 'patient') {
              return FutureBuilder<bool>(
                future: MedicalProfileService.hasHealthProfile(),
                builder: (context, profileSnapshot) {
                  if (profileSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingScreen();
                  }
                  if (profileSnapshot.hasError) {
                    return _buildErrorScreen('حدث خطأ أثناء التحقق من الملف الصحي.');
                  }
                  final hasProfile = profileSnapshot.data ?? false;
                  if (!hasProfile) {
                    return const HealthQuestionsScreen();
                  }
                  return const HomeScreen();
                },
              );
            }

            return const HomeScreen();
          },
        );
      },
    );
  }


  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري التحميل...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AuthGate()),
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}