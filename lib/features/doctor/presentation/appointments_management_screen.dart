import 'package:flutter/material.dart';

class AppointmentsManagementScreen extends StatelessWidget {
  const AppointmentsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode? Colors.grey[900]: Colors.white,
        foregroundColor: Colors.blue,
        elevation: 2,
        title: const Text('شاشة الاعدادات'),
      ),
      body: const Center(
        child: Text('لا يوجد '),
      ),
    );
  }
}
