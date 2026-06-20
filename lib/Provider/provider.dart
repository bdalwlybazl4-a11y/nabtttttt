import 'package:flutter/cupertino.dart';

class HomeProvider with ChangeNotifier {
  String _mood = '';

  String get mood => _mood;

  void setMood(String newMood) {
    _mood = newMood;
    notifyListeners();

    // يمكن هنا إرسال الحالة للسيرفر إذا لزم الأمر
    // _api.updateUserMood(newMood);
  }
}