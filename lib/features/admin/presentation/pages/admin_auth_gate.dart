import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digl/features/admin/models/admin_models.dart';
import 'package:digl/features/admin/presentation/pages/admin_login_screen.dart';
import 'package:digl/features/admin/presentation/pages/admin_dashboard_screen.dart';

class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = userSnapshot.data;

        if (user == null) {
          return const AdminLoginScreen();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('admins')
              .doc(user.uid)
              .get(),
          builder: (context, adminSnapshot) {
            if (adminSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (adminSnapshot.hasError ||
                !adminSnapshot.hasData ||
                !adminSnapshot.data!.exists) {
              return const Scaffold(
                body: Center(
                  child: Text('خطأ: لم يتم العثور على بيانات المسؤول'),
                ),
              );
            }

            final admin = AdminUser.fromFirestore(adminSnapshot.data!);

            if (!admin.isActive) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.block, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'حسابك معطل',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('الرجاء التواصل مع فريق الدعم'),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          FirebaseAuth.instance.signOut();
                        },
                        child: const Text('تسجيل الخروج'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return AdminDashboardScreen(admin: admin);
          },
        );
      },
    );
  }
}
