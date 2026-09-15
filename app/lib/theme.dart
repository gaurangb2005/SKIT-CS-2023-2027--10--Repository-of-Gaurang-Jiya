import 'package:flutter/material.dart';

/// Spacing scale: 4/8/12/16/24/32.
class Spacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class AppRadius {
  static const card = 16.0;
  static const sm = BorderRadius.all(Radius.circular(8));
  static const md = BorderRadius.all(Radius.circular(16));
}

class AppColors {
  static const seed = Color(0xFF3730A3); // deep indigo
  static const accent = Color(0xFFF97316); // warm orange
  static const success = Color(0xFF16A34A);
  static const error = Color(0xFFDC2626);
  static const surfaceSoft = Color(0xFFF4F5FB);
}

/// Each subject gets a stable colour + icon so students recognise it at a glance.
class SubjectStyle {
  final Color color;
  final IconData icon;
  const SubjectStyle(this.color, this.icon);
}

const Map<String, SubjectStyle> kSubjectStyles = {
  'maths': SubjectStyle(Color(0xFF2563EB), Icons.calculate_rounded),
  'mathematics': SubjectStyle(Color(0xFF2563EB), Icons.calculate_rounded),
  'science': SubjectStyle(Color(0xFF16A34A), Icons.science_rounded),
  'english': SubjectStyle(Color(0xFF7C3AED), Icons.menu_book_rounded),
  'hindi': SubjectStyle(Color(0xFFDB2777), Icons.translate_rounded),
};

const _fallbackSubjectStyles = [
  SubjectStyle(Color(0xFF0D9488), Icons.auto_stories_rounded),
  SubjectStyle(Color(0xFFCA8A04), Icons.public_rounded),
  SubjectStyle(Color(0xFFE11D48), Icons.palette_rounded),
];

SubjectStyle subjectStyleFor(String subjectName) {
  final key = subjectName.trim().toLowerCase();
  if (kSubjectStyles.containsKey(key)) return kSubjectStyles[key]!;
  final index = key.hashCode.abs() % _fallbackSubjectStyles.length;
  return _fallbackSubjectStyles[index];
}

final appTheme = _buildTheme();

ThemeData _buildTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    secondary: AppColors.accent,
    error: AppColors.error,
  );

  const fontFamily = 'Nunito';

  final textTheme = const TextTheme(
    displaySmall: TextStyle(fontWeight: FontWeight.w800, fontSize: 32, height: 1.2),
    titleLarge: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, height: 1.3),
    titleMedium: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, height: 1.3),
    bodyLarge: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, height: 1.4),
    bodyMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, height: 1.4),
    labelLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.2),
  ).apply(fontFamily: fontFamily);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: AppColors.surfaceSoft,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      titleTextStyle: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48), textStyle: textTheme.labelLarge),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceSoft,
      contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.lg),
      border: const OutlineInputBorder(borderRadius: AppRadius.sm, borderSide: BorderSide.none),
      enabledBorder: const OutlineInputBorder(borderRadius: AppRadius.sm, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.sm,
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      selectedIconTheme: IconThemeData(color: colorScheme.primary),
      selectedLabelTextStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w700),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: Colors.grey.shade500,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}
