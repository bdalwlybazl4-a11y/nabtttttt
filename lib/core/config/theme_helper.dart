import 'package:flutter/material.dart';
import 'medical_theme.dart';

/// ملف مساعد يوفر دوال سهلة للتعامل مع الثيمات
class ThemeHelper {
  /// احصل على لون الخطأ بناءً على الثيم
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: MedicalTheme.dangerRed,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// اعرض رسالة نجاح
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: MedicalTheme.successGreen,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// اعرض رسالة تحذير
  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: MedicalTheme.warningOrange,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// اعرض رسالة معلومات
  static void showInfoSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: MedicalTheme.infoBlue,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// احصل على لون النص بناءً على الثيم
  static Color getTextColor(BuildContext context) {
    return MedicalTheme.getTextColor(context);
  }

  /// احصل على لون الخلفية بناءً على الثيم
  static Color getBackgroundColor(BuildContext context) {
    return MedicalTheme.getBackgroundColor(context);
  }

  /// احصل على لون السطح بناءً على الثيم
  static Color getSurfaceColor(BuildContext context) {
    return MedicalTheme.getSurfaceColor(context);
  }

  /// احصل على لون الحدود بناءً على الثيم
  static Color getBorderColor(BuildContext context) {
    return MedicalTheme.getBorderColor(context);
  }

  /// احصل على لون الفاصل بناءً على الثيم
  static Color getDividerColor(BuildContext context) {
    return MedicalTheme.getDividerColor(context);
  }

  /// تحقق من الثيم الحالي
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// احصل على لون بناءً على الثيم
  static Color getColor(
    BuildContext context,
    Color lightColor,
    Color darkColor,
  ) {
    return MedicalTheme.getColor(context, lightColor, darkColor);
  }

  /// احصل على لون الأيقونة بناءً على الثيم
  static Color getIconColor(BuildContext context) {
    return MedicalTheme.getColor(
      context,
      MedicalTheme.darkGray600,
      MedicalTheme.lightGray400,
    );
  }

  /// احصل على لون النص الثانوي بناءً على الثيم
  static Color getSecondaryTextColor(BuildContext context) {
    return MedicalTheme.getColor(
      context,
      MedicalTheme.darkGray600,
      MedicalTheme.lightGray400,
    );
  }
}
