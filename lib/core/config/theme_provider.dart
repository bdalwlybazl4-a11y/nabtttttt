import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎨 مزود الثيمات - يدير حالة الثيمات والتبديل بين الفاتح والداكن
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  late SharedPreferences _prefs;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.dark) {
      return true;
    } else if (_themeMode == ThemeMode.light) {
      return false;
    }
    // إذا كان system، نتحقق من إعدادات النظام
    return WidgetsBinding.instance.window.platformDispatcher.views.first
        .platformDispatcher.implicitView?.physicalSize.isEmpty ?? false;
  }

  /// ✅ تهيئة المزود من Shared Preferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final savedThemeMode = _prefs.getString(_themeKey) ?? 'system';
    
    switch (savedThemeMode) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  /// ✅ تبديل إلى الوضع الفاتح
  Future<void> setLightMode() async {
    _themeMode = ThemeMode.light;
    await _prefs.setString(_themeKey, 'light');
    notifyListeners();
  }

  /// ✅ تبديل إلى الوضع الداكن
  Future<void> setDarkMode() async {
    _themeMode = ThemeMode.dark;
    await _prefs.setString(_themeKey, 'dark');
    notifyListeners();
  }

  /// ✅ تبديل إلى وضع النظام
  Future<void> setSystemMode() async {
    _themeMode = ThemeMode.system;
    await _prefs.setString(_themeKey, 'system');
    notifyListeners();
  }

  /// ✅ تبديل بين الفاتح والداكن
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setDarkMode();
    } else {
      await setLightMode();
    }
  }

  /// ✅ الحصول على اسم الوضع الحالي
  String getThemeModeName() {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'فاتح';
      case ThemeMode.dark:
        return 'داكن';
      case ThemeMode.system:
        return 'إعدادات النظام';
    }
  }
}
