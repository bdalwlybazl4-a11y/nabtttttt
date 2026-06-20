import 'package:flutter/material.dart';
import 'medical_theme.dart';

/// ✅ مساعدات التصميم والألوان
/// توفر دوال وثوابت مساعدة لتحسين الواجهات البصرية
class DesignHelpers {
  // ============ Box Shadows ============
  
  /// ظل خفيف - للعناصر البسيطة
  static const List<BoxShadow> shadowLight = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  /// ظل متوسط - للعناصر الرئيسية
  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /// ظل قوي - للعناصر البارزة
  static List<BoxShadow> shadowStrong = [
    BoxShadow(
      color: Colors.black.withOpacity(0.20),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  // ============ Border Radius ============
  
  /// حواف صغيرة جداً - 4px
  static const BorderRadius radiusXSmall = BorderRadius.all(Radius.circular(4));
  
  /// حواف صغيرة - 8px
  static const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(8));
  
  /// حواف متوسطة - 12px
  static const BorderRadius radiusMedium = BorderRadius.all(Radius.circular(12));
  
  /// حواف كبيرة - 16px
  static const BorderRadius radiusLarge = BorderRadius.all(Radius.circular(16));
  
  /// حواف كبيرة جداً - 24px
  static const BorderRadius radiusXLarge = BorderRadius.all(Radius.circular(24));

  // ============ Spacing Constants ============
  
  /// spacing صغير جداً - 4px
  static const double spacingXSmall = 4;
  
  /// spacing صغير - 8px
  static const double spacingSmall = 8;
  
  /// spacing متوسط - 12px
  static const double spacingMedium = 12;
  
  /// spacing كبير - 16px
  static const double spacingLarge = 16;
  
  /// spacing كبير جداً - 24px
  static const double spacingXLarge = 24;

  // ============ Helper Methods ============

  /// ✅ حصول على ظل ديناميكي حسب حالة dark mode
  static List<BoxShadow> getShadow({
    required bool isDarkMode,
    ShadowLevel level = ShadowLevel.medium,
  }) {
    if (isDarkMode) return []; // لا ظل في الوضع الليلي
    
    switch (level) {
      case ShadowLevel.light:
        return shadowLight;
      case ShadowLevel.medium:
        return shadowMedium;
      case ShadowLevel.strong:
        return shadowStrong;
    }
  }

  /// ✅ حصول على لون الخلفية حسب dark mode
  static Color getBackgroundColor(bool isDarkMode) {
    return isDarkMode 
      ? MedicalTheme.darkGray900 
      : MedicalTheme.lightGray100;
  }

  /// ✅ حصول على لون الرسالة (الفقاعة)
  static Color getMessageBubbleColor({
    required bool isMe,
    required bool isDarkMode,
    required ColorScheme colorScheme,
  }) {
    if (isMe) {
      return colorScheme.primary;
    }
    return isDarkMode 
      ? MedicalTheme.darkGray800 
      : Colors.white;
  }

  /// ✅ حصول على لون النص على الفقاعة
  static Color getMessageTextColor({
    required bool isMe,
    required bool isDarkMode,
  }) {
    if (isMe) {
      return Colors.white;
    }
    return isDarkMode 
      ? Colors.white 
      : MedicalTheme.darkGray900;
  }

  /// ✅ إنشاء gradient احترافي للـ AppBar
  static LinearGradient getPrimaryGradient({bool reversed = false}) {
    if (reversed) {
      return const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          MedicalTheme.primaryMedicalBlueDark,
          MedicalTheme.primaryMedicalBlue,
        ],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        MedicalTheme.primaryMedicalBlue,
        MedicalTheme.primaryMedicalBlueLight,
      ],
    );
  }

  /// ✅ إنشاء gradient للأزرار
  static LinearGradient getButtonGradient(Color color) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color,
        color.withOpacity(0.8),
      ],
    );
  }

  /// ✅ إنشاء Border Decoration احترافية
  static BoxDecoration getBorderDecoration({
    required Color borderColor,
    required BorderRadius borderRadius,
    bool isDarkMode = false,
    Color? backgroundColor,
  }) {
    return BoxDecoration(
      border: Border.all(
        color: borderColor,
        width: 1,
      ),
      borderRadius: borderRadius,
      color: backgroundColor ?? Colors.transparent,
      boxShadow: isDarkMode ? [] : shadowLight,
    );
  }

  /// ✅ إنشاء Filled Container احترافية
  static BoxDecoration getFilledDecoration({
    required Color backgroundColor,
    required BorderRadius borderRadius,
    bool isDarkMode = false,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: borderRadius,
      boxShadow: isDarkMode ? [] : shadowLight,
    );
  }
}

/// مستويات الظلال
enum ShadowLevel {
  light,
  medium,
  strong,
}
