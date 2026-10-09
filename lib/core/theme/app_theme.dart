// lib/core/theme/app_theme.dart
import 'dart:ui';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sakash Brand Analysis from Logo:
//
//  PRIMARY    → Metallic Gold   #D4AF37  (logo emblem, lettering)
//  PRIMARY HI → Bright Gold     #F0C93A  (highlight / shimmer)
//  PRIMARY DK → Deep Gold       #B8960C  (pressed / shadow)
//  SECONDARY  → Rich Black      #0B0B0B  (storefront background)
//  SURFACE BK → Charcoal        #1A1A1A  (dark panels in store)
//
//  Light Mode Background → Premium White  #FAFAFA  (marble interior vibe)
//  Dark Mode Background  → Deep Black     #0B0B0B  (storefront exterior)
//  Dark Mode Surface     → Dark Charcoal  #161616  (secondary dark panel)
//
//  Brand Mood: Online fashion store
//              Think Rolex / Louis Vuitton — NOT food delivery
// ─────────────────────────────────────────────────────────────────────────────

class AppPalette {
  AppPalette._();

  // ── Brand Core ─────────────────────────────────────────────────
  /// Primary brand gold — amber gold from the Sakash logo
  static const Color primary = Color(0xFFD4AF37);

  /// Primary dark — deeper gold for pressed / gradient end
  static const Color primaryDark = Color(0xFFB8960C);

  /// Primary light — bright gold for shimmer / highlights
  static const Color primaryLight = Color(0xFFF0C93A);

  /// Premium gold — used very sparingly for maximum luxury impact
  static const Color premiumGold = Color(0xFFFFD700);

  /// Champagne — soft gold for subtle tints
  static const Color champagne = Color(0xFFF7E7A0);

  /// Secondary — rich black (storefront + logo background)
  static const Color secondary = Color(0xFF0B0B0B);

  /// Surface black — charcoal panels seen in store interior
  static const Color surfaceBlack = Color(0xFF1A1A1A);

  /// Accent — warm bronze for depth
  static const Color accent = Color(0xFF8B6914);

  // ── Semantic ───────────────────────────────────────────────────
  static const Color success = Color(0xFF22AD5C);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFDC2626);
  static const Color info    = Color(0xFF2563EB);

  // ── Light Mode ─────────────────────────────────────────────────
  /// Premium white — clean luxury paper, like the marble interior
  static const Color lightScaffold   = Color(0xFFFAFAFA);
  static const Color lightSurface    = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF5F5F5);
  static const Color lightCard       = Color(0xFFFFFFFF);

  /// Border: warm gold-tinted silver
  static const Color lightBorder     = Color(0xFFE8E0D0);
  static const Color lightBorderSoft = Color(0xFFF0EBE0);

  static const Color lightText       = Color(0xFF111111); // near black
  static const Color lightTextSoft   = Color(0xFF666666);
  static const Color lightIcon       = Color(0xFF111111);
  static const Color lightShadow     = Color(0x14000000);

  // ── Light Gold Tint (for cards / containers) ───────────────────
  static const Color lightGoldTint   = Color(0xFFFDF8EC); // very pale gold
  static const Color lightGoldSurface = Color(0xFFF9F1D8);

  // ── Dark Mode ──────────────────────────────────────────────────
  /// Deep black — matches the Sakash logo background
  static const Color darkScaffold    = Color(0xFF0B0B0B);
  static const Color darkSurface     = Color(0xFF161616);
  static const Color darkSurfaceAlt  = Color(0xFF1E1E1E);
  static const Color darkCard        = Color(0xFF1E1E1E);

  /// Borders: gold-tinted in dark mode for luxury cohesion
  static const Color darkBorder      = Color(0x40D4AF37); // 25% gold
  static const Color darkBorderSoft  = Color(0x1AD4AF37); // 10% gold

  static const Color darkText        = Color(0xFFFFFFFF);
  static const Color darkTextSoft    = Color(0xFFB5B5B5);
  static const Color darkIcon        = Color(0xFFFFFFFF);
  static const Color darkShadow      = Color(0x66000000);

  // ── Dark gold glow (for elevated surfaces) ─────────────────────
  static const Color darkGoldGlow    = Color(0xFF2A2210); // warm dark gold
  static const Color darkGoldSurface = Color(0xFF1F1A08);

  // ── Tonal Palette ──────────────────────────────────────────────
  /// Pale gold — light tinted containers, subtle backgrounds
  static const Color paleGold    = Color(0xFFFDF8EC);

  /// Ivory — cream-like premium surface
  static const Color ivory       = Color(0xFFFFFBF0);

  /// Warm beige — soft warm tone
  static const Color warmBeige   = Color(0xFFF5EDD8);

  /// Rich brown — warm text on cream
  static const Color brown       = Color(0xFF7A5C1E);

  /// Dark brown — deep warm contrast
  static const Color darkBrown   = Color(0xFF3D2A00);

  /// Muted purple — subtle accent variety
  static const Color purple      = Color(0xFF6D28D9);

  // ── Pale tones (light backgrounds) ────────────────────────────
  static const Color palePurple  = Color(0xFFF5F0FF);
  static const Color paleBlue    = Color(0xFFEFF6FF);
  static const Color paleGreen   = Color(0xFFECFDF5);
  static const Color paleOrange  = Color(0xFFFFF7ED);
  static const Color paleRed     = Color(0xFFFFF0F0);

  // ── Dark-mode tonal backgrounds ────────────────────────────────
  static const Color darkPaleGold   = Color(0xFF1A1500);
  static const Color darkPaleOrange = Color(0xFF1F1208);
  static const Color darkPaleGreen  = Color(0xFF0A1F14);
  static const Color darkPaleBlue   = Color(0xFF0A1428);
  static const Color darkPalePurple = Color(0xFF160D2E);
  static const Color darkPaleRed    = Color(0xFF2A0A0A);
}

// ─────────────────────────────────────────────────────────────────────────────
// AppThemeColors — ThemeExtension
// ─────────────────────────────────────────────────────────────────────────────

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color brandPrimary;
  final Color brandPrimaryDark;
  final Color brandPrimaryLight;
  final Color brandSecondary;
  final Color brandAccent;
  final Color brandPremiumGold;
  final Color brandChampagne;
  final Color scaffold;
  final Color surface;
  final Color surfaceAlt;
  final Color card;
  final Color goldTint;
  final Color goldSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color iconPrimary;
  final Color border;
  final Color borderSoft;
  final Color borderGold;
  final Color shadow;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color ivory;
  final Color warmBeige;
  final Color brown;
  final Color darkBrown;
  final Color purple;
  final Color palePurple;
  final Color paleBlue;
  final Color paleGreen;
  final Color paleOrange;
  final Color paleRed;
  final Color paleGold;

  // Contrast helpers
  final Color iconOnGold;
  final Color iconOnDark;
  final Color textOnGold;
  final Color textOnDark;
  final Color textOnLight;

  const AppThemeColors({
    required this.brandPrimary,
    required this.brandPrimaryDark,
    required this.brandPrimaryLight,
    required this.brandSecondary,
    required this.brandAccent,
    required this.brandPremiumGold,
    required this.brandChampagne,
    required this.scaffold,
    required this.surface,
    required this.surfaceAlt,
    required this.card,
    required this.goldTint,
    required this.goldSurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconPrimary,
    required this.border,
    required this.borderSoft,
    required this.borderGold,
    required this.shadow,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.ivory,
    required this.warmBeige,
    required this.brown,
    required this.darkBrown,
    required this.purple,
    required this.palePurple,
    required this.paleBlue,
    required this.paleGreen,
    required this.paleOrange,
    required this.paleRed,
    required this.paleGold,
    required this.iconOnGold,
    required this.iconOnDark,
    required this.textOnGold,
    required this.textOnDark,
    required this.textOnLight,
  });

  // ── Light Factory ────────────────────────────────────────────────
  factory AppThemeColors.light() {
    return const AppThemeColors(
      brandPrimary:      AppPalette.primary,
      brandPrimaryDark:  AppPalette.primaryDark,
      brandPrimaryLight: AppPalette.primaryLight,
      brandSecondary:    AppPalette.secondary,
      brandAccent:       AppPalette.accent,
      brandPremiumGold:  AppPalette.premiumGold,
      brandChampagne:    AppPalette.champagne,
      scaffold:          AppPalette.lightScaffold,
      surface:           AppPalette.lightSurface,
      surfaceAlt:        AppPalette.lightSurfaceAlt,
      card:              AppPalette.lightCard,
      goldTint:          AppPalette.lightGoldTint,
      goldSurface:       AppPalette.lightGoldSurface,
      textPrimary:       AppPalette.lightText,
      textSecondary:     AppPalette.lightTextSoft,
      iconPrimary:       AppPalette.lightIcon,
      border:            AppPalette.lightBorder,
      borderSoft:        AppPalette.lightBorderSoft,
      borderGold:        AppPalette.primary,
      shadow:            AppPalette.lightShadow,
      success:           AppPalette.success,
      warning:           AppPalette.warning,
      error:             AppPalette.error,
      info:              AppPalette.info,
      ivory:             AppPalette.ivory,
      warmBeige:         AppPalette.warmBeige,
      brown:             AppPalette.brown,
      darkBrown:         AppPalette.darkBrown,
      purple:            AppPalette.purple,
      palePurple:        AppPalette.palePurple,
      paleBlue:          AppPalette.paleBlue,
      paleGreen:         AppPalette.paleGreen,
      paleOrange:        AppPalette.paleOrange,
      paleRed:           AppPalette.paleRed,
      paleGold:          AppPalette.paleGold,
      // Gold background → black text (best contrast)
      iconOnGold:        AppPalette.secondary,
      iconOnDark:        Colors.white,
      textOnGold:        AppPalette.secondary,
      textOnDark:        Colors.white,
      textOnLight:       AppPalette.lightText,
    );
  }

  // ── Dark Factory ─────────────────────────────────────────────────
  factory AppThemeColors.dark() {
    return const AppThemeColors(
      brandPrimary:      AppPalette.primary,
      brandPrimaryDark:  AppPalette.primaryDark,
      brandPrimaryLight: AppPalette.primaryLight,
      brandSecondary:    AppPalette.darkText,
      brandAccent:       AppPalette.primaryLight,
      brandPremiumGold:  AppPalette.premiumGold,
      brandChampagne:    AppPalette.champagne,
      scaffold:          AppPalette.darkScaffold,
      surface:           AppPalette.darkSurface,
      surfaceAlt:        AppPalette.darkSurfaceAlt,
      card:              AppPalette.darkCard,
      goldTint:          AppPalette.darkGoldGlow,
      goldSurface:       AppPalette.darkGoldSurface,
      textPrimary:       AppPalette.darkText,
      textSecondary:     AppPalette.darkTextSoft,
      iconPrimary:       AppPalette.darkIcon,
      border:            AppPalette.darkBorder,
      borderSoft:        AppPalette.darkBorderSoft,
      borderGold:        AppPalette.primary,
      shadow:            AppPalette.darkShadow,
      success:           AppPalette.success,
      warning:           AppPalette.warning,
      error:             AppPalette.error,
      info:              AppPalette.info,
      ivory:             AppPalette.darkGoldGlow,
      warmBeige:         AppPalette.darkPaleOrange,
      brown:             AppPalette.champagne,
      darkBrown:         AppPalette.warmBeige,
      purple:            AppPalette.purple,
      palePurple:        AppPalette.darkPalePurple,
      paleBlue:          AppPalette.darkPaleBlue,
      paleGreen:         AppPalette.darkPaleGreen,
      paleOrange:        AppPalette.darkPaleOrange,
      paleRed:           AppPalette.darkPaleRed,
      paleGold:          AppPalette.darkPaleGold,
      iconOnGold:        AppPalette.secondary,
      iconOnDark:        Colors.white,
      textOnGold:        AppPalette.secondary,
      textOnDark:        Colors.white,
      textOnLight:       AppPalette.darkText,
    );
  }

  @override
  AppThemeColors copyWith({
    Color? brandPrimary,
    Color? brandPrimaryDark,
    Color? brandPrimaryLight,
    Color? brandSecondary,
    Color? brandAccent,
    Color? brandPremiumGold,
    Color? brandChampagne,
    Color? scaffold,
    Color? surface,
    Color? surfaceAlt,
    Color? card,
    Color? goldTint,
    Color? goldSurface,
    Color? textPrimary,
    Color? textSecondary,
    Color? iconPrimary,
    Color? border,
    Color? borderSoft,
    Color? borderGold,
    Color? shadow,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? ivory,
    Color? warmBeige,
    Color? brown,
    Color? darkBrown,
    Color? purple,
    Color? palePurple,
    Color? paleBlue,
    Color? paleGreen,
    Color? paleOrange,
    Color? paleRed,
    Color? paleGold,
    Color? iconOnGold,
    Color? iconOnDark,
    Color? textOnGold,
    Color? textOnDark,
    Color? textOnLight,
  }) {
    return AppThemeColors(
      brandPrimary:      brandPrimary      ?? this.brandPrimary,
      brandPrimaryDark:  brandPrimaryDark  ?? this.brandPrimaryDark,
      brandPrimaryLight: brandPrimaryLight ?? this.brandPrimaryLight,
      brandSecondary:    brandSecondary    ?? this.brandSecondary,
      brandAccent:       brandAccent       ?? this.brandAccent,
      brandPremiumGold:  brandPremiumGold  ?? this.brandPremiumGold,
      brandChampagne:    brandChampagne    ?? this.brandChampagne,
      scaffold:          scaffold          ?? this.scaffold,
      surface:           surface           ?? this.surface,
      surfaceAlt:        surfaceAlt        ?? this.surfaceAlt,
      card:              card              ?? this.card,
      goldTint:          goldTint          ?? this.goldTint,
      goldSurface:       goldSurface       ?? this.goldSurface,
      textPrimary:       textPrimary       ?? this.textPrimary,
      textSecondary:     textSecondary     ?? this.textSecondary,
      iconPrimary:       iconPrimary       ?? this.iconPrimary,
      border:            border            ?? this.border,
      borderSoft:        borderSoft        ?? this.borderSoft,
      borderGold:        borderGold        ?? this.borderGold,
      shadow:            shadow            ?? this.shadow,
      success:           success           ?? this.success,
      warning:           warning           ?? this.warning,
      error:             error             ?? this.error,
      info:              info              ?? this.info,
      ivory:             ivory             ?? this.ivory,
      warmBeige:         warmBeige         ?? this.warmBeige,
      brown:             brown             ?? this.brown,
      darkBrown:         darkBrown         ?? this.darkBrown,
      purple:            purple            ?? this.purple,
      palePurple:        palePurple        ?? this.palePurple,
      paleBlue:          paleBlue          ?? this.paleBlue,
      paleGreen:         paleGreen         ?? this.paleGreen,
      paleOrange:        paleOrange        ?? this.paleOrange,
      paleRed:           paleRed           ?? this.paleRed,
      paleGold:          paleGold          ?? this.paleGold,
      iconOnGold:        iconOnGold        ?? this.iconOnGold,
      iconOnDark:        iconOnDark        ?? this.iconOnDark,
      textOnGold:        textOnGold        ?? this.textOnGold,
      textOnDark:        textOnDark        ?? this.textOnDark,
      textOnLight:       textOnLight       ?? this.textOnLight,
    );
  }

  @override
  ThemeExtension<AppThemeColors> lerp(
    covariant ThemeExtension<AppThemeColors>? other,
    double t,
  ) {
    if (other is! AppThemeColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;

    return AppThemeColors(
      brandPrimary:      l(brandPrimary,      other.brandPrimary),
      brandPrimaryDark:  l(brandPrimaryDark,  other.brandPrimaryDark),
      brandPrimaryLight: l(brandPrimaryLight, other.brandPrimaryLight),
      brandSecondary:    l(brandSecondary,    other.brandSecondary),
      brandAccent:       l(brandAccent,       other.brandAccent),
      brandPremiumGold:  l(brandPremiumGold,  other.brandPremiumGold),
      brandChampagne:    l(brandChampagne,    other.brandChampagne),
      scaffold:          l(scaffold,          other.scaffold),
      surface:           l(surface,           other.surface),
      surfaceAlt:        l(surfaceAlt,        other.surfaceAlt),
      card:              l(card,              other.card),
      goldTint:          l(goldTint,          other.goldTint),
      goldSurface:       l(goldSurface,       other.goldSurface),
      textPrimary:       l(textPrimary,       other.textPrimary),
      textSecondary:     l(textSecondary,     other.textSecondary),
      iconPrimary:       l(iconPrimary,       other.iconPrimary),
      border:            l(border,            other.border),
      borderSoft:        l(borderSoft,        other.borderSoft),
      borderGold:        l(borderGold,        other.borderGold),
      shadow:            l(shadow,            other.shadow),
      success:           l(success,           other.success),
      warning:           l(warning,           other.warning),
      error:             l(error,             other.error),
      info:              l(info,              other.info),
      ivory:             l(ivory,             other.ivory),
      warmBeige:         l(warmBeige,         other.warmBeige),
      brown:             l(brown,             other.brown),
      darkBrown:         l(darkBrown,         other.darkBrown),
      purple:            l(purple,            other.purple),
      palePurple:        l(palePurple,        other.palePurple),
      paleBlue:          l(paleBlue,          other.paleBlue),
      paleGreen:         l(paleGreen,         other.paleGreen),
      paleOrange:        l(paleOrange,        other.paleOrange),
      paleRed:           l(paleRed,           other.paleRed),
      paleGold:          l(paleGold,          other.paleGold),
      iconOnGold:        l(iconOnGold,        other.iconOnGold),
      iconOnDark:        l(iconOnDark,        other.iconOnDark),
      textOnGold:        l(textOnGold,        other.textOnGold),
      textOnDark:        l(textOnDark,        other.textOnDark),
      textOnLight:       l(textOnLight,       other.textOnLight),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme — ThemeData factories
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static AppThemeColors colorsOf(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeColors>();
    assert(ext != null, 'AppThemeColors extension not found in ThemeData');
    return ext!;
  }

  // ── Shared text theme helper ──────────────────────────────────────
  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(
        color: primary, fontWeight: FontWeight.w800, letterSpacing: -1.0,
      ),
      displayMedium: TextStyle(
        color: primary, fontWeight: FontWeight.w700, letterSpacing: -0.5,
      ),
      headlineLarge: TextStyle(
        color: primary, fontWeight: FontWeight.w700, letterSpacing: -0.3,
      ),
      headlineMedium: TextStyle(
        color: primary, fontWeight: FontWeight.w700,
      ),
      headlineSmall: TextStyle(
        color: primary, fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: primary, fontSize: 18, fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      titleMedium: TextStyle(
        color: primary, fontSize: 16, fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      titleSmall: TextStyle(
        color: primary, fontSize: 14, fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(color: primary, fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(color: primary, fontSize: 14, height: 1.5),
      bodySmall: TextStyle(color: secondary, fontSize: 12, height: 1.4),
      labelLarge: TextStyle(
        color: primary, fontSize: 14, fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      labelMedium: TextStyle(
        color: secondary, fontSize: 12, fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
      ),
      labelSmall: TextStyle(
        color: secondary, fontSize: 10, fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  // ── Light Theme ──────────────────────────────────────────────────

  static ThemeData light() {
    const colors = AppThemeColors(
      brandPrimary:      AppPalette.primary,
      brandPrimaryDark:  AppPalette.primaryDark,
      brandPrimaryLight: AppPalette.primaryLight,
      brandSecondary:    AppPalette.secondary,
      brandAccent:       AppPalette.accent,
      brandPremiumGold:  AppPalette.premiumGold,
      brandChampagne:    AppPalette.champagne,
      scaffold:          AppPalette.lightScaffold,
      surface:           AppPalette.lightSurface,
      surfaceAlt:        AppPalette.lightSurfaceAlt,
      card:              AppPalette.lightCard,
      goldTint:          AppPalette.lightGoldTint,
      goldSurface:       AppPalette.lightGoldSurface,
      textPrimary:       AppPalette.lightText,
      textSecondary:     AppPalette.lightTextSoft,
      iconPrimary:       AppPalette.lightIcon,
      border:            AppPalette.lightBorder,
      borderSoft:        AppPalette.lightBorderSoft,
      borderGold:        AppPalette.primary,
      shadow:            AppPalette.lightShadow,
      success:           AppPalette.success,
      warning:           AppPalette.warning,
      error:             AppPalette.error,
      info:              AppPalette.info,
      ivory:             AppPalette.ivory,
      warmBeige:         AppPalette.warmBeige,
      brown:             AppPalette.brown,
      darkBrown:         AppPalette.darkBrown,
      purple:            AppPalette.purple,
      palePurple:        AppPalette.palePurple,
      paleBlue:          AppPalette.paleBlue,
      paleGreen:         AppPalette.paleGreen,
      paleOrange:        AppPalette.paleOrange,
      paleRed:           AppPalette.paleRed,
      paleGold:          AppPalette.paleGold,
      iconOnGold:        AppPalette.secondary,
      iconOnDark:        Colors.white,
      textOnGold:        AppPalette.secondary,
      textOnDark:        Colors.white,
      textOnLight:       AppPalette.lightText,
    );

    final colorScheme = ColorScheme.light(
      primary:                 colors.brandPrimary,
      primaryContainer:        AppPalette.lightGoldTint,
      onPrimaryContainer:      AppPalette.primaryDark,
      secondary:               colors.brandSecondary,
      secondaryContainer:      AppPalette.lightSurfaceAlt,
      surface:                 colors.surface,
      surfaceContainerHighest: AppPalette.lightSurfaceAlt,
      error:                   colors.error,
      onPrimary:               AppPalette.secondary,   // black on gold
      onSecondary:             Colors.white,
      onSurface:               colors.textPrimary,
      onError:                 Colors.white,
      outline:                 AppPalette.lightBorder,
      outlineVariant:          AppPalette.lightBorderSoft,
      shadow:                  AppPalette.lightShadow,
    );

    return ThemeData(
      useMaterial3:              true,
      brightness:                Brightness.light,
      colorScheme:               colorScheme,
      primaryColor:              colors.brandPrimary,
      scaffoldBackgroundColor:   colors.scaffold,
      canvasColor:               colors.surface,
      dividerColor:              colors.border,
      shadowColor:               colors.shadow,
      splashColor:               colors.brandPrimary.withOpacity(0.10),
      highlightColor:            colors.brandPrimary.withOpacity(0.05),
      extensions:                const [colors],

      textTheme: _buildTextTheme(
        AppPalette.lightText,
        AppPalette.lightTextSoft,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor:        colors.scaffold,
        foregroundColor:        colors.textPrimary,
        elevation:              0,
        scrolledUnderElevation: 0,
        shadowColor:            Colors.transparent,
        iconTheme:              IconThemeData(color: colors.iconPrimary),
        actionsIconTheme:       IconThemeData(color: colors.iconPrimary),
        centerTitle:            false,
        titleTextStyle: const TextStyle(
          color:          AppPalette.lightText,
          fontSize:       18,
          fontWeight:     FontWeight.w700,
          letterSpacing:  0.2,
        ),
      ),

      iconTheme: IconThemeData(color: colors.iconPrimary),

      cardTheme: CardThemeData(
        color:       colors.card,
        elevation:   0,
        shadowColor: colors.shadow,
        margin:      EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderSoft, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.brandPrimary,   // Gold
          foregroundColor: AppPalette.secondary,   // Black on gold = luxury
          elevation:       0,
          shadowColor:     colors.brandPrimary.withOpacity(0.30),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight:    FontWeight.w700,
            fontSize:      15,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.brandPrimary,
          side: BorderSide(color: colors.brandPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight:    FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.brandPrimary,
          textStyle: const TextStyle(
            fontWeight:    FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:          true,
        fillColor:       colors.surface,
        hintStyle:       TextStyle(
          color:       colors.textSecondary,
          fontSize:    14,
          fontWeight:  FontWeight.w400,
        ),
        prefixIconColor: colors.textSecondary,
        suffixIconColor: colors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical:   15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.brandPrimary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.error, width: 1.8),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:      AppPalette.lightSurface,
        selectedItemColor:    AppPalette.primary,       // Gold
        unselectedItemColor:  Color(0xFF8A8A8A),
        selectedLabelStyle:   TextStyle(
          fontWeight: FontWeight.w700,
          fontSize:   11,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize:   11,
        ),
        type:                 BottomNavigationBarType.fixed,
        elevation:            12,
        showSelectedLabels:   true,
        showUnselectedLabels: true,
      ),

      chipTheme: ChipThemeData(
        backgroundColor:     colors.surface,
        selectedColor:       colors.brandPrimary,
        disabledColor:       colors.borderSoft,
        side:                BorderSide(color: colors.border),
        labelStyle:          TextStyle(
          color:       colors.textPrimary,
          fontWeight:  FontWeight.w500,
          fontSize:    13,
        ),
        secondaryLabelStyle: const TextStyle(
          color:      AppPalette.secondary,  // black on gold chip
          fontWeight: FontWeight.w600,
          fontSize:   13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        elevation:       8,
        shadowColor:     colors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:    colors.surface,
        modalBackgroundColor: colors.surface,
        elevation:          8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.secondary,    // brand black
        contentTextStyle: const TextStyle(
          color:         Colors.white,
          fontSize:      13,
          fontWeight:    FontWeight.w500,
          letterSpacing: 0.1,
        ),
        actionTextColor: AppPalette.primaryLight, // gold action
        behavior:        SnackBarBehavior.floating,
        elevation:       6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.secondary; // black thumb on gold track
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.primary; // gold track
          }
          return const Color(0xFFD0D0D0);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((_) {
          return Colors.transparent;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppPalette.secondary),
        side: const BorderSide(color: AppPalette.lightBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.primary;
          }
          return AppPalette.lightTextSoft;
        }),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppPalette.primary,
      ),

      dividerTheme: DividerThemeData(
        color:     colors.borderSoft,
        thickness: 1,
        space:     1,
      ),

      listTileTheme: ListTileThemeData(
        tileColor:      Colors.transparent,
        iconColor:      colors.iconPrimary,
        textColor:      colors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical:   4,
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor:         colors.brandPrimary,
        unselectedLabelColor: colors.textSecondary,
        indicatorColor:     colors.brandPrimary,
        indicatorSize:      TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(
          fontWeight:    FontWeight.w700,
          fontSize:      14,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize:   14,
        ),
        dividerColor: Colors.transparent,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.brandPrimary,
        foregroundColor: AppPalette.secondary,
        elevation:       4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color:        AppPalette.secondary,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),

      badgeTheme: const BadgeThemeData(
        backgroundColor: AppPalette.primary,
        textColor:       AppPalette.secondary,
      ),
    );
  }

  // ── Dark Theme ───────────────────────────────────────────────────

  static ThemeData dark() {
    const colors = AppThemeColors(
      brandPrimary:      AppPalette.primary,
      brandPrimaryDark:  AppPalette.primaryDark,
      brandPrimaryLight: AppPalette.primaryLight,
      brandSecondary:    AppPalette.darkText,
      brandAccent:       AppPalette.primaryLight,
      brandPremiumGold:  AppPalette.premiumGold,
      brandChampagne:    AppPalette.champagne,
      scaffold:          AppPalette.darkScaffold,
      surface:           AppPalette.darkSurface,
      surfaceAlt:        AppPalette.darkSurfaceAlt,
      card:              AppPalette.darkCard,
      goldTint:          AppPalette.darkGoldGlow,
      goldSurface:       AppPalette.darkGoldSurface,
      textPrimary:       AppPalette.darkText,
      textSecondary:     AppPalette.darkTextSoft,
      iconPrimary:       AppPalette.darkIcon,
      border:            AppPalette.darkBorder,
      borderSoft:        AppPalette.darkBorderSoft,
      borderGold:        AppPalette.primary,
      shadow:            AppPalette.darkShadow,
      success:           AppPalette.success,
      warning:           AppPalette.warning,
      error:             AppPalette.error,
      info:              AppPalette.info,
      ivory:             AppPalette.darkGoldGlow,
      warmBeige:         AppPalette.darkPaleOrange,
      brown:             AppPalette.champagne,
      darkBrown:         AppPalette.warmBeige,
      purple:            AppPalette.purple,
      palePurple:        AppPalette.darkPalePurple,
      paleBlue:          AppPalette.darkPaleBlue,
      paleGreen:         AppPalette.darkPaleGreen,
      paleOrange:        AppPalette.darkPaleOrange,
      paleRed:           AppPalette.darkPaleRed,
      paleGold:          AppPalette.darkPaleGold,
      iconOnGold:        AppPalette.secondary,
      iconOnDark:        Colors.white,
      textOnGold:        AppPalette.secondary,
      textOnDark:        Colors.white,
      textOnLight:       AppPalette.darkText,
    );

    final colorScheme = ColorScheme.dark(
      primary:                 colors.brandPrimary,
      primaryContainer:        AppPalette.darkPaleGold,
      onPrimaryContainer:      AppPalette.primaryLight,
      secondary:               colors.brandSecondary,
      secondaryContainer:      AppPalette.darkSurfaceAlt,
      surface:                 colors.surface,
      surfaceContainerHighest: AppPalette.darkSurfaceAlt,
      error:                   colors.error,
      onPrimary:               AppPalette.secondary,   // black on gold
      onSecondary:             Colors.white,
      onSurface:               colors.textPrimary,
      onError:                 Colors.white,
      outline:                 AppPalette.darkBorder,
      outlineVariant:          AppPalette.darkBorderSoft,
      shadow:                  AppPalette.darkShadow,
    );

    return ThemeData(
      useMaterial3:            true,
      brightness:              Brightness.dark,
      colorScheme:             colorScheme,
      primaryColor:            colors.brandPrimary,
      scaffoldBackgroundColor: colors.scaffold,
      canvasColor:             colors.surface,
      dividerColor:            colors.border,
      shadowColor:             colors.shadow,
      splashColor:             colors.brandPrimary.withOpacity(0.12),
      highlightColor:          colors.brandPrimary.withOpacity(0.06),
      extensions:              const [colors],

      textTheme: _buildTextTheme(
        AppPalette.darkText,
        AppPalette.darkTextSoft,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor:        colors.scaffold,
        foregroundColor:        colors.textPrimary,
        elevation:              0,
        scrolledUnderElevation: 0,
        shadowColor:            Colors.transparent,
        iconTheme:              IconThemeData(color: colors.iconPrimary),
        actionsIconTheme:       IconThemeData(color: colors.iconPrimary),
        centerTitle:            false,
        titleTextStyle: const TextStyle(
          color:         AppPalette.darkText,
          fontSize:      18,
          fontWeight:    FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),

      iconTheme: IconThemeData(color: colors.iconPrimary),

      cardTheme: CardThemeData(
        color:       colors.card,
        elevation:   0,
        shadowColor: colors.shadow,
        margin:      EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderSoft, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.brandPrimary,   // Gold on dark
          foregroundColor: AppPalette.secondary,   // Black text = luxury
          elevation:       0,
          shadowColor:     colors.brandPrimary.withOpacity(0.40),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight:    FontWeight.w700,
            fontSize:      15,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.brandPrimary,
          side: BorderSide(color: colors.brandPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight:    FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.brandPrimary,
          textStyle: const TextStyle(
            fontWeight:    FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:          true,
        fillColor:       colors.surfaceAlt,
        hintStyle: TextStyle(
          color:      colors.textSecondary,
          fontSize:   14,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: colors.textSecondary,
        suffixIconColor: colors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical:   15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.brandPrimary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.error, width: 1.8),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:      AppPalette.darkSurface,
        selectedItemColor:    AppPalette.primary,        // Gold
        unselectedItemColor:  Color(0xFF6B6B6B),
        selectedLabelStyle:   TextStyle(
          fontWeight:    FontWeight.w700,
          fontSize:      11,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize:   11,
        ),
        type:                 BottomNavigationBarType.fixed,
        elevation:            12,
        showSelectedLabels:   true,
        showUnselectedLabels: true,
      ),

      chipTheme: ChipThemeData(
        backgroundColor:     colors.surfaceAlt,
        selectedColor:       colors.brandPrimary,
        disabledColor:       colors.borderSoft,
        side:                BorderSide(color: colors.border),
        labelStyle: TextStyle(
          color:      colors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize:   13,
        ),
        secondaryLabelStyle: const TextStyle(
          color:      AppPalette.secondary,
          fontWeight: FontWeight.w600,
          fontSize:   13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        elevation:       12,
        shadowColor:     colors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:      colors.surface,
        modalBackgroundColor: colors.surface,
        elevation:            10,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        /// Deep black with subtle gold border feel
        backgroundColor: AppPalette.darkSurfaceAlt,
        contentTextStyle: const TextStyle(
          color:         Colors.white,
          fontSize:      13,
          fontWeight:    FontWeight.w500,
          letterSpacing: 0.1,
        ),
        actionTextColor: AppPalette.primaryLight,
        behavior:        SnackBarBehavior.floating,
        elevation:       6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.secondary; // black thumb on gold track
          }
          return AppPalette.darkTextSoft;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.primary; // gold track
          }
          return AppPalette.darkBorder;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((_) {
          return Colors.transparent;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppPalette.secondary),
        side: BorderSide(color: AppPalette.darkBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.primary;
          }
          return AppPalette.darkTextSoft;
        }),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppPalette.primary,
      ),

      dividerTheme: DividerThemeData(
        color:     colors.borderSoft,
        thickness: 1,
        space:     1,
      ),

      listTileTheme: ListTileThemeData(
        tileColor:      Colors.transparent,
        iconColor:      colors.iconPrimary,
        textColor:      colors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical:   4,
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor:           colors.brandPrimary,
        unselectedLabelColor: colors.textSecondary,
        indicatorColor:       colors.brandPrimary,
        indicatorSize:        TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(
          fontWeight:    FontWeight.w700,
          fontSize:      14,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize:   14,
        ),
        dividerColor: Colors.transparent,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.brandPrimary,
        foregroundColor: AppPalette.secondary,
        elevation:       6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color:        AppPalette.darkSurfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppPalette.darkBorder),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),

      badgeTheme: const BadgeThemeData(
        backgroundColor: AppPalette.primary,
        textColor:       AppPalette.secondary,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Luxury Gradient Helpers — use throughout the app
// ─────────────────────────────────────────────────────────────────────────────

class AppGradients {
  AppGradients._();

  /// Primary gold gradient — for hero banners, premium buttons
  static const LinearGradient goldHorizontal = LinearGradient(
    colors: [AppPalette.primaryDark, AppPalette.primary, AppPalette.primaryLight],
    begin:  Alignment.centerLeft,
    end:    Alignment.centerRight,
  );

  static const LinearGradient goldVertical = LinearGradient(
    colors: [AppPalette.primaryLight, AppPalette.primary, AppPalette.primaryDark],
    begin:  Alignment.topCenter,
    end:    Alignment.bottomCenter,
  );

  /// Browse Products card — gold gradient
  static const LinearGradient browseFabrics = LinearGradient(
    colors: [AppPalette.primaryDark, AppPalette.primary, AppPalette.primaryLight],
    begin:  Alignment.topLeft,
    end:    Alignment.bottomRight,
  );

  /// Style Consultation card — black gradient
  static const LinearGradient fabricConsultation = LinearGradient(
    colors: [Color(0xFF111111), Color(0xFF2A2A2A)],
    begin:  Alignment.topLeft,
    end:    Alignment.bottomRight,
  );

  /// Premium banner — storefront dark + gold shimmer
  static const LinearGradient premiumBanner = LinearGradient(
    colors: [Color(0xFF0B0B0B), Color(0xFF1A1500), AppPalette.primaryDark],
    stops:  [0.0, 0.6, 1.0],
    begin:  Alignment.centerLeft,
    end:    Alignment.centerRight,
  );

  /// Luxury dark — for hero sections in dark mode
  static const LinearGradient luxuryDark = LinearGradient(
    colors: [Color(0xFF0B0B0B), Color(0xFF161616), Color(0xFF1A1500)],
    begin:  Alignment.topLeft,
    end:    Alignment.bottomRight,
  );

  /// Gold shimmer — for skeleton loaders / premium indicators
  static const LinearGradient goldShimmer = LinearGradient(
    colors: [
      Color(0xFFB8960C),
      Color(0xFFD4AF37),
      Color(0xFFF0C93A),
      Color(0xFFFFD700),
      Color(0xFFF0C93A),
      Color(0xFFD4AF37),
      Color(0xFFB8960C),
    ],
    stops: [0.0, 0.15, 0.35, 0.5, 0.65, 0.85, 1.0],
  );

  /// Marble-inspired light — for premium card backgrounds
  static const LinearGradient marbleLight = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFAF8F0), Color(0xFFF5F0E8)],
    begin:  Alignment.topLeft,
    end:    Alignment.bottomRight,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// GlassPanel — luxury glass morphism
// ─────────────────────────────────────────────────────────────────────────────

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final bool showGoldBorder;

  const GlassPanel({
    super.key,
    required this.child,
    this.blur           = 15.0,
    this.opacity        = 0.6,
    this.width,
    this.height,
    this.padding        = const EdgeInsets.all(16.0),
    this.borderRadius   = const BorderRadius.all(Radius.circular(16)),
    this.showGoldBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final isDark  = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width:   width,
          height:  height,
          padding: padding,
          decoration: BoxDecoration(
            color:        colors.card.withOpacity(opacity),
            borderRadius: borderRadius,
            border: Border.all(
              color: showGoldBorder
                  ? AppPalette.primary.withOpacity(isDark ? 0.6 : 0.4)
                  : colors.borderSoft,
              width: showGoldBorder ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color:      colors.shadow,
                blurRadius: 12,
                offset:     const Offset(0, 4),
              ),
              if (showGoldBorder && isDark)
                BoxShadow(
                  color:      AppPalette.primary.withOpacity(0.08),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset:     Offset.zero,
                ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GoldDivider — luxury branded divider
// ─────────────────────────────────────────────────────────────────────────────

class GoldDivider extends StatelessWidget {
  final double opacity;
  final double thickness;
  final EdgeInsetsGeometry margin;

  const GoldDivider({
    super.key,
    this.opacity   = 0.4,
    this.thickness = 1.0,
    this.margin    = const EdgeInsets.symmetric(horizontal: 0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: thickness,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppPalette.primary.withOpacity(opacity),
            AppPalette.primaryLight.withOpacity(opacity),
            AppPalette.primary.withOpacity(opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}