import 'package:flutter/material.dart';

/// ملف الثيمات الطبي الشامل
/// تصميم احترافي وجذاب مع دعم الثيمين (Light و Dark)
class MedicalTheme {
  // ============ الألوان الرئيسية - Primary Colors ============
  static const Color primaryMedicalBlue = Color(0xFF2E5CB8); // أزرق طبي أساسي
  static const Color primaryMedicalBlueDark = Color(0xFF1E3A8A); // أزرق داكن للـ hover
  static const Color primaryMedicalBlueLight = Color(0xFF6FA8DC); // أزرق فاتح
  static const Color primaryColor = primaryMedicalBlue;
  // ============ الألوان الثانوية - Secondary Colors ============
  static const Color secondaryMedicalGreen = Color(0xFF27AE60); // أخضر صحة
  static const Color secondaryMedicalGreenLight = Color(0xFF52BE80); // أخضر فاتح
  static const Color tertiaryMedicalCyan = Color(0xFF17A2B8); // أزرق مائي (معلومات)

  // ============ ألوان الحالات - Status Colors ============
  static const Color successGreen = Color(0xFF27AE60); // نجاح (أخضر)
  static const Color warningOrange = Color(0xFFE67E22); // تحذير (برتقالي)
  static const Color dangerRed = Color(0xFFE74C3C); // خطر (أحمر)
  static const Color infoBlue = Color(0xFF3498DB); // معلومات (أزرق فاتح)
  static const Color pendingYellow = Color(0xFFF39C12); // معلق (أصفر)

  // ============ ألوان خاصة طبية ============
  static const Color doctorPurple = Color(0xFF9B59B6); // لون الأطباء (بنفسجي)
  static const Color patientPink = Color(0xFFE91E63); // لون المرضى (وردي)
  static const Color urgentCrimson = Color(0xFFC0392B); // حالات عاجلة
  static const Color stableGreen = Color(0xFF16A085); // حالة مستقرة

  // ============ الألوان الحيادية - Neutral Colors ============
  static const Color darkGray900 = Color(0xFF1A1A1A);
  static const Color darkGray800 = Color(0xFF2D2D2D);
  static const Color darkGray700 = Color(0xFF404040);
  static const Color darkGray600 = Color(0xFF525252);
  static const Color darkGray500 = Color(0xFF666666);
  static const Color darkGray400 = Color(0xFF808080);

  static const Color lightGray100 = Color(0xFFF5F5F5);
  static const Color lightGray200 = Color(0xFFEEEEEE);
  static const Color lightGray300 = Color(0xFFE0E0E0);
  static const Color lightGray400 = Color(0xFFBDBDBD);
  static const Color lightGray500 = Color(0xFF9E9E9E);

  static const Color pure = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE8E8E8);
  static const Color dividerDark = Color(0xFF3A3A3A);

  // ============ ألوان الحقول والحدود ============
  static const Color borderLight = Color(0xFFD1D5DB);
  static const Color borderDark = Color(0xFF4B5563);
  static const Color focusLight = Color(0xFF2E5CB8);
  static const Color focusDark = Color(0xFF6FA8DC);

  // ============ LIGHT THEME ============
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primaryMedicalBlue,
        onPrimary: pure,
        primaryContainer: primaryMedicalBlueLight,
        onPrimaryContainer: primaryMedicalBlueDark,
        secondary: secondaryMedicalGreen,
        onSecondary: pure,
        secondaryContainer: secondaryMedicalGreenLight,
        onSecondaryContainer: Color(0xFF2C679F),
        tertiary: tertiaryMedicalCyan,
        onTertiary: pure,
        error: dangerRed,
        onError: pure,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410E0B),
        background: lightGray100,
        onBackground: darkGray900,
        surface: pure,
        onSurface: darkGray900,
        surfaceVariant: lightGray200,
        onSurfaceVariant: darkGray600,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryMedicalBlue,
        foregroundColor: pure,
        elevation: 2,
        shadowColor: Colors.black26,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: pure,
        ),
        iconTheme: const IconThemeData(color: pure),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkGray900,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: darkGray900,
          height: 1.3,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: darkGray900,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkGray900,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkGray900,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkGray900,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkGray900,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkGray900,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkGray600,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: darkGray900,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: darkGray900,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: darkGray600,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkGray900,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkGray700,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: darkGray600,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightGray100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryMedicalBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dangerRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dangerRed, width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: darkGray600,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: darkGray500,
          fontSize: 14,
        ),
        errorStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: dangerRed,
          fontSize: 12,
        ),
        prefixIconColor: darkGray600,
        suffixIconColor: darkGray600,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMedicalBlue,
          foregroundColor: pure,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: primaryMedicalBlue.withOpacity(0.4),
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryMedicalBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryMedicalBlue,
          side: const BorderSide(color: primaryMedicalBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: pure,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: dividerLight, width: 1),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
        clipBehavior: Clip.antiAlias,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: lightGray200,
        selectedColor: primaryMedicalBlue,
        labelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: darkGray900,
          fontSize: 14,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: pure,
          fontSize: 14,
        ),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: pure,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkGray900,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          color: darkGray700,
        ),
      ),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        textColor: darkGray900,
        iconColor: darkGray600,
        tileColor: pure,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryMedicalBlue;
          }
          return lightGray400;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryMedicalBlue.withOpacity(0.3);
          }
          return lightGray300;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryMedicalBlue;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(pure),
        side: const BorderSide(color: borderLight, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: dividerLight,
        thickness: 1,
        space: 16,
      ),

      // Scaffold Background Color
      scaffoldBackgroundColor: lightGray100,

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryMedicalBlue,
        foregroundColor: pure,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: pure,
        selectedItemColor: primaryMedicalBlue,
        unselectedItemColor: darkGray500,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkGray900,
        contentTextStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: pure,
          fontSize: 14,
        ),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actionTextColor: infoBlue,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryMedicalBlue,
        circularTrackColor: lightGray300,
        linearTrackColor: lightGray300,
      ),
    );
  }

  // ============ DARK THEME ============
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryMedicalBlueLight,
        onPrimary: darkGray900,
        primaryContainer: primaryMedicalBlueDark,
        onPrimaryContainer: primaryMedicalBlueLight,
        secondary: secondaryMedicalGreenLight,
        onSecondary: darkGray900,
        secondaryContainer: Color(0xFF094BD9),
        onSecondaryContainer: secondaryMedicalGreenLight,
        tertiary: tertiaryMedicalCyan,
        onTertiary: darkGray900,
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        background: darkGray900,
        onBackground: lightGray100,
        surface: darkGray800,
        onSurface: lightGray100,
        surfaceVariant: darkGray700,
        onSurfaceVariant: lightGray400,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: darkGray800,
        foregroundColor: lightGray100,
        elevation: 2,
        shadowColor: Colors.black54,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: lightGray100,
        ),
        iconTheme: const IconThemeData(color: lightGray100),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: lightGray100,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: lightGray100,
          height: 1.3,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: lightGray100,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: lightGray100,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightGray100,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightGray100,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: lightGray100,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: lightGray200,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: lightGray400,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: lightGray100,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: lightGray200,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: lightGray400,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: lightGray100,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: lightGray300,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: lightGray400,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkGray700,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryMedicalBlueLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB), width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: lightGray400,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: lightGray500,
          fontSize: 14,
        ),
        errorStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: Color(0xFFFFB4AB),
          fontSize: 12,
        ),
        prefixIconColor: lightGray400,
        suffixIconColor: lightGray400,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMedicalBlueLight,
          foregroundColor: darkGray900,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: Colors.black54,
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryMedicalBlueLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryMedicalBlueLight,
          side: const BorderSide(color: primaryMedicalBlueLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: darkGray800,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: dividerDark, width: 1),
        ),
        shadowColor: Colors.black.withOpacity(0.3),
        clipBehavior: Clip.antiAlias,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: darkGray700,
        selectedColor: primaryMedicalBlueLight,
        labelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: lightGray100,
          fontSize: 14,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: darkGray900,
          fontSize: 14,
        ),
        brightness: Brightness.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: darkGray800,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: lightGray100,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          color: lightGray300,
        ),
      ),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        textColor: lightGray100,
        iconColor: lightGray400,
        tileColor: darkGray800,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryMedicalBlueLight;
          }
          return lightGray500;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryMedicalBlueLight.withOpacity(0.3);
          }
          return darkGray600;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryMedicalBlueLight;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(darkGray900),
        side: const BorderSide(color: borderDark, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: dividerDark,
        thickness: 1,
        space: 16,
      ),

      // Scaffold Background Color
      scaffoldBackgroundColor: darkGray900,

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryMedicalBlueLight,
        foregroundColor: darkGray900,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkGray800,
        selectedItemColor: primaryMedicalBlueLight,
        unselectedItemColor: lightGray500,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkGray800,
        contentTextStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: lightGray100,
          fontSize: 14,
        ),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actionTextColor: infoBlue,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryMedicalBlueLight,
        circularTrackColor: darkGray700,
        linearTrackColor: darkGray700,
      ),
    );
  }

  // ============ Helper Colors Getters ============
  /// احصل على اللون بناءً على الثيم
  static Color getColor(BuildContext context, Color lightColor, Color darkColor) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? darkColor : lightColor;
  }

  /// احصل على لون النص بناءً على الثيم
  static Color getTextColor(BuildContext context) {
    return MedicalTheme.getColor(context, darkGray900, lightGray100);
  }

  /// احصل على لون الخلفية بناءً على الثيم
  static Color getBackgroundColor(BuildContext context) {
    return MedicalTheme.getColor(context, lightGray100, darkGray900);
  }

  /// احصل على لون السطح بناءً على الثيم
  static Color getSurfaceColor(BuildContext context) {
    return MedicalTheme.getColor(context, pure, darkGray800);
  }

  /// احصل على لون الحدود بناءً على الثيم
  static Color getBorderColor(BuildContext context) {
    return MedicalTheme.getColor(context, borderLight, borderDark);
  }

  /// احصل على لون الفاصل بناءً على الثيم
  static Color getDividerColor(BuildContext context) {
    return MedicalTheme.getColor(context, dividerLight, dividerDark);
  }
}
