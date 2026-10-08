import 'package:flutter/material.dart';
import 'package:pfb/core/theme/app_theme.dart';

extension BuildContextThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;

  AppThemeColors get appColors => AppTheme.colorsOf(this);

  bool get isDarkMode  => Theme.of(this).brightness == Brightness.dark;
  bool get isLightMode => Theme.of(this).brightness == Brightness.light;

  // ── Luxury gradient helpers available anywhere ─────────────────
  /// Gold gradient — primary CTA backgrounds, hero banners
  LinearGradient get goldGradient => AppGradients.goldHorizontal;

  /// Premium dark banner gradient
  LinearGradient get premiumBannerGradient => AppGradients.premiumBanner;

  /// Browse Products card gradient
  LinearGradient get browseFabricsGradient => AppGradients.browseFabrics;

  /// Style Consultation card gradient
  LinearGradient get fabricConsultationGradient =>
      AppGradients.fabricConsultation;
}