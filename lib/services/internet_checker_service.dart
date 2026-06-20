import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class InternetCheckerService {
  /// يتحقق من وجود اتصال فعلي بالإنترنت
  static Future<bool> hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = await InternetConnectionChecker().hasConnection;

    // إذا لم يكن هناك اتصال بالشبكة أو الاتصال الحقيقي بالإنترنت غير موجود
    return connectivityResult != ConnectivityResult.none && isOnline;
  }
}
