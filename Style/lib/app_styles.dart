import 'package:flutter/material.dart';

/// Central design tokens for the Circle application.
///
/// Flutter does not use CSS. These constants are the native Flutter
/// equivalent of CSS variables and reusable classes.
abstract final class AppColors {
  static const transparent = Color(0x00000000);
  static const black = Color(0xFF000000);
  static const black26 = Color(0x42000000);
  static const white70 = Color(0xB3FFFFFF);
  static const materialRed = Color(0xFFF44336);
  static const materialRedAccent = Color(0xFFFF5252);

  static const primary = Color(0xFFFF5B49);
  static const primaryDark = Color(0xFFD94735);
  static const primarySoft = Color(0xFFFFF2EF);
  static const primaryBorder = Color(0xFFFFC9C1);

  static const accent = Color(0xFFFF774A);
  static const accentDark = Color(0xFFE85A35);
  static const accentSoft = Color(0xFFFFF4EE);
  static const accentBorder = Color(0xFFFFD5C2);

  static const background = Color(0xFFFCFBFA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceBorder = Color(0xFFF0E3DF);

  static const textPrimary = Color(0xFF1F2937); // Deep slate gray for bold/headings
  static const textBody = Color(0xFF4B5563);    // Balanced neutral gray for body text
  static const textSecondary = Color(0xFF6B7280); // Muted gray for captions/subtitles
  static const textDisabled = Color(0xFF9CA3AF);
  static const inputBorder = Color(0xFFD1D5DB);

  static const success = Color(0xFF22C55E);
  static const successDark = Color(0xFF15803D);
  static const successSoft = Color(0xFFDCFCE7);
  static const warning = Color(0xFFF97316);
  static const danger = Color(0xFFEF4444);
  static const dangerDark = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEE2E2);
}

/// Complete app palette. Legacy identifiers are retained temporarily for API
/// compatibility, but all former purple/cyan brand values resolve to Circle's
/// coral and warm-neutral design system.
abstract final class AppPalette {
  static const hexFF0077B6 = AppColors.primaryDark;
  static const hexFF007A5A = Color(0XFF007A5A);
  static const hexFF0096C7 = AppColors.primary;
  static const hexFF00B0FF = AppColors.accent;
  static const hexFF00B2E2 = AppColors.primary;
  static const hexFF00B4D8 = AppColors.primary;
  static const hexFF00B894 = Color(0XFF00B894);
  static const hexFF00BCD4 = AppColors.accent;
  static const hexFF0284C7 = AppColors.accentDark;
  static const hexFF0288D1 = AppColors.primaryDark;
  static const hexFF0369A1 = AppColors.primaryDark;
  static const hexFF10B981 = Color(0XFF10B981);
  static const hexFF15803D = Color(0XFF15803D);
  static const hexFF16A34A = Color(0XFF16A34A);
  static const hexFF22C55E = Color(0XFF22C55E);
  static const hexFF2E1A47 = AppColors.textPrimary;
  static const hexFF3498DB = AppColors.primary;
  static const hexFF3B2A68 = AppColors.textPrimary;
  static const hexFF3C096C = AppColors.dangerDark;
  static const hexFF4A148C = AppColors.primaryDark;
  static const hexFF4A3E5C = AppColors.textSecondary;
  static const hexFF4ADE80 = Color(0XFF4ADE80);
  static const hexFF512DA8 = AppColors.primaryDark;
  static const hexFF57CC99 = Color(0XFF57CC99);
  static const hexFF5B21B6 = AppColors.primaryDark;
  static const hexFF5E2B97 = AppColors.primaryDark;
  static const hexFF5E35B1 = AppColors.primary;
  static const hexFF673AB7 = AppColors.primary;
  static const hexFF7B2CBF = AppColors.warning;
  static const hexFF7E57C2 = AppColors.accent;
  static const hexFF7E6E91 = AppColors.textSecondary;
  static const hexFF7E72A2 = AppColors.textSecondary;
  static const hexFF80DEEA = AppColors.primaryBorder;
  static const hexFF8A7D9D = AppColors.textSecondary;
  static const hexFF8B5CF6 = AppColors.accent;
  static const hexFF8E44AD = AppColors.primaryDark;
  static const hexFF8F8CA3 = AppColors.textSecondary;
  static const hexFF92400E = Color(0XFF92400E);
  static const hexFF9C27B0 = AppColors.primaryDark;
  static const hexFFA0AEC0 = AppColors.textDisabled;
  static const hexFFABA7BE = AppColors.textDisabled;
  static const hexFFB39DDB = AppColors.primaryBorder;
  static const hexFFB3E5FC = AppColors.primaryBorder;
  static const hexFFB45309 = Color(0XFFB45309);
  static const hexFFBAE6FD = AppColors.primaryBorder;
  static const hexFFC7F9CC = Color(0XFFC7F9CC);
  static const hexFFCCC8DC = AppColors.inputBorder;
  static const hexFFCDC6E2 = AppColors.primaryBorder;
  static const hexFFD1C4E9 = AppColors.primaryBorder;
  static const hexFFD1FAE5 = Color(0XFFD1FAE5);
  static const hexFFD35400 = Color(0XFFD35400);
  static const hexFFD3CCE8 = AppColors.primaryBorder;
  static const hexFFD63031 = Color(0XFFD63031);
  static const hexFFD6D1E8 = AppColors.surfaceBorder;
  static const hexFFD97706 = Color(0XFFD97706);
  static const hexFFDC2626 = Color(0XFFDC2626);
  static const hexFFDCFCE7 = Color(0XFFDCFCE7);
  static const hexFFDDD2F0 = AppColors.primaryBorder;
  static const hexFFDDD8EC = AppColors.surfaceBorder;
  static const hexFFE0F2FE = AppColors.primarySoft;
  static const hexFFE0F7FD = AppColors.primarySoft;
  static const hexFFE11D48 = Color(0XFFE11D48);
  static const hexFFE1F5FE = AppColors.primarySoft;
  static const hexFFE2D9F3 = AppColors.primaryBorder;
  static const hexFFE5DCF4 = AppColors.primaryBorder;
  static const hexFFE67E22 = Color(0XFFE67E22);
  static const hexFFE6F9EE = Color(0XFFE6F9EE);
  static const hexFFE74C3C = Color(0XFFE74C3C);
  static const hexFFE8F5E9 = Color(0XFFE8F5E9);
  static const hexFFE8F8F0 = Color(0XFFE8F8F0);
  static const hexFFEAB308 = Color(0XFFEAB308);
  static const hexFFEADBFA = AppColors.primarySoft;
  static const hexFFECE6F5 = AppColors.primarySoft;
  static const hexFFECEAF4 = AppColors.surfaceBorder;
  static const hexFFEDE7F6 = AppColors.primarySoft;
  static const hexFFEF4444 = Color(0XFFEF4444);
  static const hexFFEFEBF6 = AppColors.surfaceBorder;
  static const hexFFF0ECF8 = AppColors.primarySoft;
  static const hexFFF0F7FF = AppColors.primarySoft;
  static const hexFFF0F9FF = AppColors.primarySoft;
  static const hexFFF0FDF4 = Color(0XFFF0FDF4);
  static const hexFFF1EEF6 = AppColors.primarySoft;
  static const hexFFF1FBF4 = Color(0XFFF1FBF4);
  static const hexFFF2EEF8 = AppColors.primarySoft;
  static const hexFFF2EEF9 = AppColors.primarySoft;
  static const hexFFF39C12 = Color(0XFFF39C12);
  static const hexFFF3E8FF = AppColors.primarySoft;
  static const hexFFF3EDF9 = AppColors.primarySoft;
  static const hexFFF3F7FF = AppColors.primarySoft;
  static const hexFFF4ECF7 = AppColors.primarySoft;
  static const hexFFF4EFF8 = AppColors.primarySoft;
  static const hexFFF59E0B = Color(0XFFF59E0B);
  static const hexFFF5F3FB = AppColors.primarySoft;
  static const hexFFF6F3FA = AppColors.primarySoft;
  static const hexFFF6F3FB = AppColors.primarySoft;
  static const hexFFF7F4FB = AppColors.background;
  static const hexFFF7F5FC = AppColors.background;
  static const hexFFF7F6FB = AppColors.background;
  static const hexFFF8F9FE = AppColors.background;
  static const hexFFF97316 = Color(0XFFF97316);
  static const hexFFF9F7FC = AppColors.background;
  static const hexFFF9F9FC = AppColors.background;
  static const hexFFFADBD8 = Color(0XFFFADBD8);
  static const hexFFFAF8FE = AppColors.background;
  static const hexFFFBD0D0 = Color(0XFFFBD0D0);
  static const hexFFFBF9FD = AppColors.background;
  static const hexFFFBFBFE = AppColors.background;
  static const hexFFFDEBD0 = Color(0XFFFDEBD0);
  static const hexFFFDF2E9 = Color(0XFFFDF2E9);
  static const hexFFFEE2E2 = Color(0XFFFEE2E2);
  static const hexFFFEF3C7 = Color(0XFFFEF3C7);
  static const hexFFFFE4E6 = Color(0XFFFFE4E6);
  static const hexFFFFEBEE = Color(0XFFFFEBEE);
  static const hexFFFFF1F2 = Color(0XFFFFF1F2);
  static const hexFFFFF3E0 = Color(0XFFFFF3E0);
  static const hexFFFFF5F5 = Color(0XFFFFF5F5);
  static const hexFFFFF9E6 = Color(0XFFFFF9E6);
  static const hexFFFFF9F0 = Color(0XFFFFF9F0);
}

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double section = 32;
}

abstract final class AppRadii {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 26;
  static const double pill = 999;

  static const borderSm = BorderRadius.all(Radius.circular(sm));
  static const borderMd = BorderRadius.all(Radius.circular(md));
  static const borderLg = BorderRadius.all(Radius.circular(lg));
  static const borderXl = BorderRadius.all(Radius.circular(xl));

  static const r2 = BorderRadius.all(Radius.circular(2));
  static const r3 = BorderRadius.all(Radius.circular(3));
  static const r4 = BorderRadius.all(Radius.circular(4));
  static const r6 = BorderRadius.all(Radius.circular(6));
  static const r8 = BorderRadius.all(Radius.circular(8));
  static const r10 = borderSm;
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r14 = borderMd;
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r18 = BorderRadius.all(Radius.circular(18));
  static const r20 = borderLg;
  static const r22 = BorderRadius.all(Radius.circular(22));
  static const r24 = BorderRadius.all(Radius.circular(24));
  static const r26 = borderXl;
  static const r28 = BorderRadius.all(Radius.circular(28));
}

abstract final class AppInsets {
  static const screen = EdgeInsets.symmetric(
    horizontal: AppSpacing.xl,
    vertical: AppSpacing.lg,
  );
  static const card = EdgeInsets.all(AppSpacing.lg);
  static const cardLarge = EdgeInsets.all(AppSpacing.xl);
  static const button = EdgeInsets.symmetric(
    horizontal: AppSpacing.xl,
    vertical: AppSpacing.md,
  );

  static const all3 = EdgeInsets.all(3);
  static const all5 = EdgeInsets.all(5);
  static const all6 = EdgeInsets.all(6);
  static const all7 = EdgeInsets.all(7);
  static const all8 = EdgeInsets.all(8);
  static const all10 = EdgeInsets.all(10);
  static const all12 = EdgeInsets.all(12);
  static const all14 = EdgeInsets.all(14);
  static const all16 = card;
  static const all18 = EdgeInsets.all(18);
  static const all20 = cardLarge;
  static const all22 = EdgeInsets.all(22);
  static const all24 = EdgeInsets.all(24);
  static const all32 = EdgeInsets.all(32);
}

abstract final class AppTextStyles {
  static const display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const pageTitle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static const title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textBody,
  );

  static const bodyMuted = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const button = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}

abstract final class AppShadows {
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x0F201C1B), blurRadius: 16, offset: Offset(0, 6)),
  ];

  static const primary = <BoxShadow>[
    BoxShadow(color: Color(0x3DFF5B49), blurRadius: 18, offset: Offset(0, 8)),
  ];
}

abstract final class AppDecorations {
  static const card = BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadii.borderLg,
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.surfaceBorder, width: 1.2),
    ),
  );

  static const softPrimaryCard = BoxDecoration(
    color: AppColors.primarySoft,
    borderRadius: AppRadii.borderLg,
    border: Border.fromBorderSide(BorderSide(color: AppColors.primaryBorder)),
  );

  static const errorBanner = BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadii.borderMd,
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}

/// Application-wide Material theme plus compatibility aliases used by the
/// existing screens. New UI should prefer [AppColors], [AppTextStyles], and
/// the other token classes above.
class AppTheme {
  const AppTheme._();

  static const primaryPurple = AppColors.primary;
  static const darkPurple = AppColors.textPrimary;
  static const lightPurpleBg = AppColors.primarySoft;
  static const purpleBorder = AppColors.primaryBorder;
  static const accentCyan = AppColors.accent;
  static const lightCyanBg = AppColors.accentSoft;
  static const cyanBorder = AppColors.accentBorder;
  static const scaffoldBg = AppColors.background;
  static const cardBg = AppColors.surface;
  static const textDark = AppColors.textPrimary;
  static const textMuted = AppColors.textSecondary;
  static const textLight = AppColors.textDisabled;
  static const successGreen = AppColors.success;
  static const successBg = AppColors.successSoft;
  static const warningOrange = AppColors.warning;
  static const dangerRed = AppColors.danger;
  static const dangerBg = AppColors.dangerSoft;

  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.danger,
    ),
    textTheme: const TextTheme(
      headlineLarge: AppTextStyles.display,
      headlineMedium: AppTextStyles.pageTitle,
      titleLarge: AppTextStyles.sectionTitle,
      titleMedium: AppTextStyles.title,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.caption,
      labelLarge: AppTextStyles.button,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: TextStyle(
        fontFamily: 'Manrope',
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.borderLg,
        side: const BorderSide(color: AppColors.surfaceBorder, width: 1.2),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(color: AppColors.textDisabled),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.inputBorder, width: 1.2),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
      },
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.surfaceBorder,
      thickness: 1,
    ),
  );
}
