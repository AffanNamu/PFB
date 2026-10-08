import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/routing/app_router.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/services/firebase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _navigated = false;
  bool _booting = false;
  String? _errorText;

  late final AnimationController _introController;
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _textSlideAnimation;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(
          parent: _introController, curve: Curves.easeOutBack),
    );
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _introController, curve: Curves.easeOutCubic));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(
          parent: _pulseController, curve: Curves.easeInOut),
    );
    _shimmerAnimation =
        Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
          parent: _shimmerController, curve: Curves.easeInOut),
    );

    _introController.forward();
    _pulseController.repeat(reverse: true);
    _shimmerController.repeat();
    _start();
  }

  Future<void> _start() async {
    if (_booting) return;
    _booting = true;

    try {
      await Future.any([
        _bootstrap(),
        Future.delayed(const Duration(seconds: 20), () {
          throw Exception(
            'App startup timed out. '
            'Please check your internet and try again.',
          );
        }),
      ]);
    } catch (e) {
      if (!mounted) return;
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission-denied') ||
          errorStr.contains('permission denied')) {
        await _safeNavigate(RouteNames.mainShell);
        return;
      }
      setState(() => _errorText = e.toString());
    } finally {
      _booting = false;
    }
  }

  Future<void> _safeNavigate(String routeName) async {
    if (!mounted || _navigated) return;
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await AppRouter.clearAndGo(context, routeName);
    });
  }

  Future<void> _bootstrap() async {
    final firebaseService = FirebaseService();

    unawaited(firebaseService.seedDefaultAppSettingsSafely());
    unawaited(
        firebaseService.seedDefaultCategoriesIfMissingSafely());

    // On web, FirebaseAuth state is already fully resolved by the time
    // we reach here (main() awaited authStateChanges().first before
    // calling runApp). We can safely read currentUser directly.
    //
    // On Android, currentUser is synchronously available from the
    // native SDK on startup.
    //
    // In both cases — no extra delay needed.
    User? user = firebaseService.currentUser;

    if (kDebugMode) {
      debugPrint(
          '🚀 SplashScreen | currentUser='
          '${user?.uid ?? 'null (guest)'}');
    }

    // Extra safety for web: if currentUser is somehow still null but
    // Firebase reports a signed-in user via authStateChanges, wait for it.
    if (user == null && kIsWeb) {
      try {
        user = await FirebaseAuth.instance
            .authStateChanges()
            .first
            .timeout(const Duration(seconds: 3));

        if (kDebugMode) {
          debugPrint(
              '🚀 SplashScreen | authStateChanges fallback → '
              '${user?.uid ?? 'still null'}');
        }
      } catch (_) {}
    }

    if (user != null) {
      unawaited(firebaseService.ensureUserProfileSafely());
      unawaited(firebaseService.syncLocalCartToFirestoreSafely());

      bool isAdmin = false;
      try {
        isAdmin = await firebaseService
            .isAdmin()
            .timeout(const Duration(seconds: 6));
      } catch (_) {
        isAdmin = false;
      }

      if (isAdmin) {
        await _safeNavigate(RouteNames.admin);
        return;
      }
    }

    await _safeNavigate(RouteNames.mainShell);
  }

  Future<void> _retry() async {
    setState(() {
      _errorText = null;
      _navigated = false;
    });
    await _start();
  }

  @override
  void dispose() {
    _introController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [
                    Color(0xFF0B0B0B),
                    Color(0xFF111111),
                    Color(0xFF0B0B0B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [
                    Color(0xFFFAFAFA),
                    Color(0xFFF5F0E8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.primary
                      .withOpacity(isDark ? 0.06 : 0.08),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.primary
                          .withOpacity(isDark ? 0.10 : 0.06),
                      blurRadius: 80,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.primaryDark
                      .withOpacity(isDark ? 0.08 : 0.06),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: _errorText == null
                          ? _buildLoadingContent(
                              colors, isDark)
                          : _buildErrorContent(colors),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingContent(
      AppThemeColors colors, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: _SakashLogo(isDark: isDark),
        ),
        const SizedBox(height: 32),
        SlideTransition(
          position: _textSlideAnimation,
          child: Column(
            children: [
              Text(
                'SAKASH',
                style: GoogleFonts.cinzel(
                  color: isDark
                      ? Colors.white
                      : AppPalette.secondary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return ShaderMask(
                    shaderCallback: (bounds) =>
                        LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: const [
                        AppPalette.primaryDark,
                        AppPalette.primary,
                        AppPalette.primaryLight,
                        AppPalette.premiumGold,
                        AppPalette.primaryLight,
                        AppPalette.primary,
                        AppPalette.primaryDark,
                      ],
                      stops: [
                        0.0,
                        (_shimmerAnimation.value - 0.3)
                            .clamp(0.0, 1.0),
                        (_shimmerAnimation.value)
                            .clamp(0.0, 1.0),
                        (_shimmerAnimation.value + 0.1)
                            .clamp(0.0, 1.0),
                        (_shimmerAnimation.value + 0.2)
                            .clamp(0.0, 1.0),
                        (_shimmerAnimation.value + 0.4)
                            .clamp(0.0, 1.0),
                        1.0,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'FABRICS',
                      style: GoogleFonts.cinzel(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Container(
                width: 80,
                height: 2,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppPalette.primaryDark,
                      AppPalette.primary,
                      AppPalette.primaryLight,
                      AppPalette.primary,
                      AppPalette.primaryDark,
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Luxury African Fabrics & Textiles',
                style: GoogleFonts.poppins(
                  color: isDark
                      ? colors.textSecondary
                      : const Color(0xFF5A5A5A),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (bounds) =>
                    const LinearGradient(
                  colors: [
                    AppPalette.primaryDark,
                    AppPalette.primary,
                  ],
                ).createShader(bounds),
                child: Text(
                  'Quality you can feel.',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.4, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          builder: (context, value, child) =>
              Opacity(opacity: value, child: child),
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: AppPalette.primary,
              strokeWidth: 2.5,
              backgroundColor:
                  AppPalette.primary.withOpacity(0.15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(AppThemeColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: colors.error.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.error.withOpacity(0.25),
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.wifi_off_rounded,
              color: colors.error,
              size: 44,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Unable to load Sakash Collection',
          style: GoogleFonts.poppins(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          _errorText!,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: colors.textSecondary,
            fontSize: 12.5,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppPalette.primaryDark,
                AppPalette.primary,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton.icon(
            onPressed: _retry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: AppPalette.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              'Retry',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sakash Logo ───────────────────────────────────────────────────────────────

class _SakashLogo extends StatelessWidget {
  final bool isDark;
  const _SakashLogo({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppPalette.primary
                .withOpacity(isDark ? 0.06 : 0.08),
            border: Border.all(
              color: AppPalette.primary
                  .withOpacity(isDark ? 0.25 : 0.15),
              width: 1.5,
            ),
          ),
        ),
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppPalette.primary
                .withOpacity(isDark ? 0.04 : 0.06),
            border: Border.all(
              color: AppPalette.primary
                  .withOpacity(isDark ? 0.20 : 0.12),
              width: 1,
            ),
          ),
        ),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppPalette.primary
                    .withOpacity(isDark ? 0.55 : 0.35),
                blurRadius: 24,
                spreadRadius: 3,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/sakash_logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}