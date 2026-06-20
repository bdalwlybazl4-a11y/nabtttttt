import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();

  /// فحص الاتصال مرة واحدة
  static Future<bool> isConnected() async {
    final ConnectivityResult result =
    await _connectivity.checkConnectivity();
    return _isConnected(result);
  }

  /// الاستماع لتغير حالة الاتصال
  static Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_isConnected);
  }

  /// دالة مساعدة لتحديد حالة الاتصال
  static bool _isConnected(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }

  /// عرض Dialog عند انقطاع الإنترنت
  static void showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red),
            SizedBox(width: 8),
            Text('لا يوجد اتصال بالإنترنت'),
          ],
        ),
        content: const Text(
          'يجب أن يكون جهازك متصلاً بالإنترنت لاستخدام التطبيق.\n'
              'يرجى التحقق من اتصال Wi-Fi أو بيانات الجوال.',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  /// عرض SnackBar عند انقطاع الإنترنت
  static void showNoInternetSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 8),
            Text('غير متصل بالإنترنت'),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
