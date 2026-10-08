import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/routing/app_router.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/services/firebase_auth_service.dart';
import 'package:pfb/services/firebase_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirebaseService _firebaseService = FirebaseService();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _loading = false;
  bool _googleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // ── NEW: same redirect-aware flag as LoginScreen ──────────────────────────
  bool _redirectingToGoogle = false;

  Future<void> _goAfterSignup() async {
    try {
      await _firebaseService.ensureUserProfile();
      await _firebaseService.syncLocalCartToFirestore();
    } catch (_) {}

    if (!mounted) return;

    final isAdmin = await _firebaseService.isAdmin();
    if (!mounted) return;

    if (isAdmin) {
      await AppRouter.clearAndGo(context, RouteNames.admin);
      return;
    }

    await AppRouter.clearAndGo(context, RouteNames.mainShell);
  }

  Future<void> _signup() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
      );

      if (user == null) {
        throw AuthFailure('Account creation failed. Please try again.');
      }

      await FirebaseAuth.instance.currentUser
          ?.updateProfile(displayName: name);

      if (!mounted) return;
      await _goAfterSignup();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor:
              AppTheme.colorsOf(context).error.withOpacity(0.9),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signupWithGoogle() async {
    setState(() => _googleLoading = true);

    try {
      final user = await _authService.signInWithGoogle();

      // ── Web: signInWithGoogle() fires signInWithRedirect() and returns
      // null.  Show "Redirecting…" UI – result is handled by SplashScreen.
      if (kIsWeb && user == null) {
        if (mounted) {
          setState(() {
            _googleLoading = false;
            _redirectingToGoogle = true;
          });
        }
        return;
      }

      if (user == null) {
        throw AuthFailure('Google sign-up did not complete.');
      }

      if (!mounted) return;
      await _goAfterSignup();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor:
              AppTheme.colorsOf(context).error.withOpacity(0.9),
        ),
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _goToLogin() async {
    await AppRouter.clearAndGo(context, RouteNames.login);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── NEW: Redirecting overlay ──────────────────────────────────────────
    if (_redirectingToGoogle) {
      return Scaffold(
        backgroundColor: colors.scaffold,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppPalette.primary),
              const SizedBox(height: 20),
              Text(
                'Redirecting to Google…',
                style: GoogleFonts.poppins(
                  color: colors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [
                    Color(0xFF0B0B0B),
                    Color(0xFF111111),
                    Color(0xFF0B0B0B),
                  ]
                : [
                    colors.scaffold,
                    colors.surfaceAlt,
                    colors.scaffold,
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // ── Gold Glow Circles ─────────────────────────────────
            Positioned(
              top: -90,
              left: -80,
              child: Container(
                width: 290,
                height: 290,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.primary.withOpacity(
                    isDark ? 0.08 : 0.12,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.primary.withOpacity(
                        isDark ? 0.12 : 0.08,
                      ),
                      blurRadius: 90,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 180,
              right: -40,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.primaryLight.withOpacity(
                    isDark ? 0.06 : 0.10,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -70,
              right: -40,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.secondary.withOpacity(
                    isDark ? 0.25 : 0.12,
                  ),
                ),
              ),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 42,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),

                          _buildBrandLogo(colors, isDark),

                          const SizedBox(height: 26),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(
                                18, 20, 18, 22),
                            decoration: BoxDecoration(
                              color: colors.card.withOpacity(
                                isDark ? 0.90 : 0.85,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: AppPalette.primary.withOpacity(
                                  isDark ? 0.25 : 0.15,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.shadow,
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                                if (isDark)
                                  BoxShadow(
                                    color: AppPalette.primary
                                        .withOpacity(0.05),
                                    blurRadius: 40,
                                    offset: Offset.zero,
                                  ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create account',
                                  style: GoogleFonts.poppins(
                                    color: colors.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Join Sakash Collection and discover luxury African textiles.',
                                  style: GoogleFonts.poppins(
                                    color: colors.textSecondary,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                _GlassField(
                                  controller: _nameCtrl,
                                  hint: 'Full name',
                                  icon: Icons.person_outline_rounded,
                                ),
                                const SizedBox(height: 12),
                                _GlassField(
                                  controller: _emailCtrl,
                                  hint: 'Email address',
                                  icon: Icons.email_outlined,
                                  keyboardType:
                                      TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 12),
                                _GlassField(
                                  controller: _passwordCtrl,
                                  hint: 'Password',
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  suffix: IconButton(
                                    onPressed: () => setState(() =>
                                        _obscurePassword =
                                            !_obscurePassword),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons
                                              .visibility_off_outlined,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _GlassField(
                                  controller: _confirmPasswordCtrl,
                                  hint: 'Confirm password',
                                  icon: Icons.lock_person_outlined,
                                  obscureText: _obscureConfirmPassword,
                                  suffix: IconButton(
                                    onPressed: () => setState(() =>
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword),
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons
                                              .visibility_off_outlined,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Create Account Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 58,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: _loading
                                          ? null
                                          : const LinearGradient(
                                              colors: [
                                                AppPalette.primaryDark,
                                                AppPalette.primary,
                                                AppPalette.primaryLight,
                                              ],
                                            ),
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      boxShadow: _loading
                                          ? []
                                          : [
                                              BoxShadow(
                                                color: AppPalette.primary
                                                    .withOpacity(0.40),
                                                blurRadius: 16,
                                                offset:
                                                    const Offset(0, 6),
                                              ),
                                            ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed:
                                          _loading ? null : _signup,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor:
                                            AppPalette.secondary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: _loading
                                          ? SizedBox(
                                              width: 22,
                                              height: 22,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color:
                                                    AppPalette.secondary,
                                              ),
                                            )
                                          : Text(
                                              'Create Account',
                                              style: GoogleFonts.poppins(
                                                fontWeight:
                                                    FontWeight.w800,
                                                fontSize: 16,
                                                letterSpacing: 0.5,
                                                color:
                                                    AppPalette.secondary,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              AppPalette.primary
                                                  .withOpacity(0.30),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets
                                          .symmetric(horizontal: 16),
                                      child: Text(
                                        'or',
                                        style: GoogleFonts.poppins(
                                          color: colors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppPalette.primary
                                                  .withOpacity(0.30),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Google Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 58,
                                  child: OutlinedButton(
                                    onPressed: _googleLoading
                                        ? null
                                        : _signupWithGoogle,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor:
                                          colors.surface.withOpacity(0.5),
                                      side: BorderSide(
                                        color: AppPalette.primary
                                            .withOpacity(
                                          isDark ? 0.35 : 0.20,
                                        ),
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _googleLoading
                                        ? SizedBox(
                                            width: 22,
                                            height: 22,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppPalette.primary,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Image.network(
                                                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                                width: 22,
                                                height: 22,
                                                errorBuilder:
                                                    (_, __, ___) => Text(
                                                  'G',
                                                  style:
                                                      GoogleFonts.poppins(
                                                    color:
                                                        colors.textPrimary,
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Continue with Google',
                                                style: GoogleFonts.poppins(
                                                  color:
                                                      colors.textPrimary,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Sign in link
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        'Already have an account?',
                                        style: GoogleFonts.poppins(
                                          color: colors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: _goToLogin,
                                        child: Text(
                                          'Sign In',
                                          style: GoogleFonts.poppins(
                                            color: AppPalette.primary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          Text(
                            'By continuing, you agree to our Terms & Privacy Policy.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: colors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandLogo(AppThemeColors colors, bool isDark) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppPalette.primaryDark,
                AppPalette.primary,
                AppPalette.primaryLight,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppPalette.primary.withOpacity(
                  isDark ? 0.55 : 0.35,
                ),
                blurRadius: 22,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'PF',
              style: GoogleFonts.cinzel(
                color: AppPalette.secondary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            Text(
              'SAKASH',
              style: GoogleFonts.cinzel(
                color: isDark ? Colors.white : AppPalette.secondary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  AppPalette.primaryDark,
                  AppPalette.primary,
                  AppPalette.primaryLight,
                ],
              ).createShader(bounds),
              child: Text(
                'FABRICS',
                style: GoogleFonts.cinzel(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: 50,
          height: 2,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppPalette.primaryDark,
                AppPalette.primaryLight,
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Luxury African Fabrics & Textiles',
          style: GoogleFonts.poppins(
            color: colors.textSecondary,
            fontSize: 12.5,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ── Glass Field ────────────────────────────────────────────────────────────────

class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;

  const _GlassField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: colors.surface.withOpacity(isDark ? 0.80 : 0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                AppPalette.primary.withOpacity(isDark ? 0.20 : 0.12),
          ),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          cursorColor: AppPalette.primary,
          style: GoogleFonts.poppins(
            color: colors.textPrimary,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            filled: false,
            fillColor: Colors.transparent,
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: colors.textSecondary,
              fontSize: 15,
            ),
            prefixIcon: Icon(
              icon,
              color: AppPalette.primary.withOpacity(0.70),
              size: 22,
            ),
            suffixIcon: suffix,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 20,
            ),
          ),
        ),
      ),
    );
  }
}