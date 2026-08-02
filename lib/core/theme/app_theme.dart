import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────────
/// Design tokens dari DESIGN.md (Airbnb-inspired / "Rausch" palette)
/// ─────────────────────────────────────────────────────────────────
abstract class AppColors {
  // Brand & Accent
  static const Color primary = Color(0xFFFF385C); // Rausch
  static const Color primaryActive = Color(0xFFE00B41);
  static const Color primaryDisabled = Color(0xFFFFD1DA);

  // Text
  static const Color ink = Color(0xFF222222);
  static const Color body = Color(0xFF3F3F3F);
  static const Color muted = Color(0xFF6A6A6A);
  static const Color mutedSoft = Color(0xFF929292);

  // Surface / Canvas
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF7F7F7);
  static const Color surfaceStrong = Color(0xFFF2F2F2);

  // Borders / Hairlines
  static const Color hairline = Color(0xFFDDDDDD);
  static const Color hairlineSoft = Color(0xFFEBEBEB);
  static const Color borderStrong = Color(0xFFC1C1C1);

  // On-colors
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const Color error = Color(0xFFC13515);

  // Status (non-Airbnb, untuk konteks medis)
  static const Color success = Color(0xFF2D9C5B);
  static const Color warning = Color(0xFFD97706);
}

/// ─────────────────────────────────────────────────────────────────
/// Border radius tokens
/// ─────────────────────────────────────────────────────────────────
abstract class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 32;
  static const double full = 9999;
}

/// ─────────────────────────────────────────────────────────────────
/// Spacing tokens
/// ─────────────────────────────────────────────────────────────────
abstract class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double section = 64;
}

/// ─────────────────────────────────────────────────────────────────
/// Single shadow tier (Airbnb design — only one elevation level)
/// ─────────────────────────────────────────────────────────────────
abstract class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x05000000), // rgba(0,0,0,0.02)
      blurRadius: 0,
      spreadRadius: 1,
      offset: Offset(0, 0),
    ),
    BoxShadow(
      color: Color(0x0A000000), // rgba(0,0,0,0.04)
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x1A000000), // rgba(0,0,0,0.10)
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
}

/// ─────────────────────────────────────────────────────────────────
/// Main theme builder
/// ─────────────────────────────────────────────────────────────────
abstract class AppTheme {
  static ThemeData get lightTheme {
    // Gunakan Inter sebagai pengganti Airbnb Cereal VF
    final textTheme = GoogleFonts.interTextTheme(
      const TextTheme(
        // display-xl: 28px / 700
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.43,
          letterSpacing: 0,
          color: AppColors.ink,
        ),
        // display-lg: 22px / 500
        displayMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          height: 1.18,
          letterSpacing: -0.44,
          color: AppColors.ink,
        ),
        // display-sm / display-md: 20–21px / 600–700
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.20,
          letterSpacing: -0.18,
          color: AppColors.ink,
        ),
        // title-md: 16px / 600
        headlineMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.25,
          color: AppColors.ink,
        ),
        // title-sm: 16px / 500
        headlineSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.25,
          color: AppColors.ink,
        ),
        // body-md: 16px / 400
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: AppColors.body,
        ),
        // body-sm: 14px / 400
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.43,
          color: AppColors.body,
        ),
        // caption: 14px / 500
        bodySmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.29,
          color: AppColors.muted,
        ),
        // button-md: 16px / 500
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.25,
          color: AppColors.ink,
        ),
        // caption-sm / micro: 12–13px
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.33,
          color: AppColors.muted,
        ),
        // nav-link / titleMedium: 16px / 600
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.25,
          color: AppColors.ink,
        ),
        // button-sm: 14px / 500
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.29,
          color: AppColors.ink,
        ),
      ),
    );

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryDisabled,
      onPrimaryContainer: AppColors.primaryActive,
      secondary: AppColors.ink,
      onSecondary: AppColors.canvas,
      secondaryContainer: AppColors.surfaceStrong,
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.muted,
      onTertiary: AppColors.canvas,
      tertiaryContainer: AppColors.surfaceSoft,
      onTertiaryContainer: AppColors.ink,
      error: AppColors.error,
      onError: AppColors.canvas,
      errorContainer: const Color(0xFFFEE2DC),
      onErrorContainer: AppColors.error,
      surface: AppColors.canvas,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.muted,
      outline: AppColors.hairline,
      outlineVariant: AppColors.hairlineSoft,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: AppColors.ink,
      onInverseSurface: AppColors.canvas,
      inversePrimary: AppColors.primaryDisabled,
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.canvas,

      // ─── AppBar ────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        shape: const Border(
          bottom: BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),

      // ─── NavigationBar ────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.canvas,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return const IconThemeData(color: AppColors.muted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.muted,
          );
        }),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // ─── Cards ──────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.canvas,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.hairline, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        clipBehavior: Clip.antiAlias,
      ),

      // ─── ElevatedButton ─────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primaryDisabled,
          disabledForegroundColor: AppColors.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ─── FilledButton ────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primaryDisabled,
          disabledForegroundColor: AppColors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ─── OutlinedButton ─────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ─── TextButton ─────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),

      // ─── FloatingActionButton ────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 2,
        shape: CircleBorder(),
      ),

      // ─── InputDecoration (text-input) ────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.canvas,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        constraints: const BoxConstraints(minHeight: 56),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.hairline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.hairline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.ink, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.muted,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.mutedSoft,
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.error,
        ),
        prefixIconColor: AppColors.muted,
      ),

      // ─── Divider ────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.hairlineSoft,
        thickness: 1,
        space: 1,
      ),

      // ─── AlertDialog ────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.canvas,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.body,
        ),
      ),

      // ─── SnackBar ───────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.canvas,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ─── Chip ───────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceSoft,
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ─── ListTile ───────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: AppColors.muted,
      ),

      // ─── ProgressIndicator ──────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primaryDisabled,
      ),

      // ─── CircleAvatar ───────────────────────────────────────
      // (set via individual widgets)

      // ─── BottomSheet ────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }
}
