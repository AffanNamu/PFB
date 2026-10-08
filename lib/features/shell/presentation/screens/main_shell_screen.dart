import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/routing/app_router.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';
import 'package:pfb/features/cart/presentation/screens/cart_screen.dart';
import 'package:pfb/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:pfb/features/orders/presentation/screens/order_screen.dart';
import 'package:pfb/features/products/presentation/screens/product_list_screen.dart';
import 'package:pfb/features/profile/presentation/screens/profile_screen.dart';
import 'package:pfb/services/admin_preview_scope.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  static const _tabKey = 'main_shell_tab_index';

  final _firebaseService = FirebaseService();
  int _currentIndex = 0;
  bool _isAdmin      = false;
  bool _loadingRole  = true;

  late final List<Widget> _screens = [
    const ProductListScreen(showBottomNav: false),
    const CartScreen(showScaffold: false),
    OrderScreen(showScaffold: false),
    const FavoritesScreen(showScaffold: false),
    const ProfileScreen(showScaffold: false),
  ];

  @override
  void initState() {
    super.initState();
    _loadTab();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final isAdmin = await _firebaseService.isAdmin();
    if (!mounted) return;
    setState(() {
      _isAdmin      = isAdmin;
      _loadingRole  = false;
    });
  }

  Future<void> _loadTab() async {
    final prefs      = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt(_tabKey) ?? 0;
    if (!mounted) return;
    setState(() => _currentIndex = savedIndex);
  }

  Future<void> _saveTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tabKey, index);
  }

  Future<void> _backToAdmin() async {
    AdminPreviewScope.of(context).exitPreviewMode();
    if (!mounted) return;
    await AppRouter.clearAndGo(context, RouteNames.admin);
  }

  void _handleTabTap(int index, bool isPreviewMode) {
    if (_loadingRole) return;

    // Last tab (index 4) = Profile — if admin not in preview, go back to admin
    if (_isAdmin && !isPreviewMode && index == 4) {
      _backToAdmin();
      return;
    }

    setState(() => _currentIndex = index);
    _saveTab(index);
  }

  bool _hasValidImage(String? url) {
    if (url == null) return false;
    final value = url.trim();
    return value.isNotEmpty &&
        (value.startsWith('http://') || value.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    final previewController = AdminPreviewScope.of(context);
    final isPreviewMode     = previewController.isPreviewMode;
    final colors            = context.appColors;
    final isDark            = context.isDarkMode;

    return StreamBuilder<int>(
      stream: _firebaseService.watchCartCount(),
      builder: (context, cartSnapshot) {
        final cartCount = cartSnapshot.data ?? 0;

        return StreamBuilder<List<String>>(
          stream: _firebaseService.watchFavorites(),
          builder: (context, favSnapshot) {
            final favCount = favSnapshot.data?.length ?? 0;

            return StreamBuilder<Map<String, dynamic>?>(
              stream: _firebaseService.watchUserProfile(),
              builder: (context, userSnapshot) {
                final photoUrl =
                    (userSnapshot.data?['photoUrl'] ?? '').toString();

                return Scaffold(
                  backgroundColor: colors.scaffold,
                  body: Column(
                    children: [
                      // ── Admin Preview Banner ─────────────────────
                      if (!_loadingRole && _isAdmin && isPreviewMode)
                        _AdminPreviewBanner(
                          onBack: _backToAdmin,
                          colors: colors,
                        ),

                      // ── Screen Body ──────────────────────────────
                      Expanded(
                        child: IndexedStack(
                          index: _currentIndex,
                          children: _screens,
                        ),
                      ),
                    ],
                  ),

                  // ── Bottom Navigation Bar ──────────────────────────
                  bottomNavigationBar: _SakashBottomNav(
                    currentIndex: _currentIndex,
                    cartCount:    cartCount,
                    favCount:     favCount,
                    isAdmin:      _isAdmin,
                    isPreviewMode: isPreviewMode,
                    photoUrl: _hasValidImage(photoUrl) ? photoUrl : null,
                    onTap:   (i) => _handleTabTap(i, isPreviewMode),
                    colors:  colors,
                    isDark:  isDark,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ── Admin Preview Banner ───────────────────────────────────────────────────────

class _AdminPreviewBanner extends StatelessWidget {
  final VoidCallback onBack;
  final AppThemeColors colors;

  const _AdminPreviewBanner({
    required this.onBack,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppPalette.primaryDark,
            AppPalette.primary,
            AppPalette.primaryLight,
          ],
          begin: Alignment.centerLeft,
          end:   Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color:        AppPalette.secondary.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.visibility_rounded,
                  color: AppPalette.secondary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Preview Mode',
                      style: GoogleFonts.poppins(
                        color:      AppPalette.secondary,
                        fontWeight: FontWeight.w800,
                        fontSize:   12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Viewing as Customer',
                      style: GoogleFonts.poppins(
                        color:    AppPalette.secondary.withOpacity(0.70),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onBack,
                style: TextButton.styleFrom(
                  backgroundColor: AppPalette.secondary.withOpacity(0.15),
                  foregroundColor: AppPalette.secondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Back to Admin',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize:   12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sakash Bottom Navigation Bar ─────────────────────────────────────────────

class _SakashBottomNav extends StatelessWidget {
  final int currentIndex;
  final int cartCount;
  final int favCount;
  final bool isAdmin;
  final bool isPreviewMode;
  final String? photoUrl;
  final ValueChanged<int> onTap;
  final AppThemeColors colors;
  final bool isDark;

  const _SakashBottomNav({
    required this.currentIndex,
    required this.cartCount,
    required this.favCount,
    required this.isAdmin,
    required this.isPreviewMode,
    required this.photoUrl,
    required this.onTap,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        // Subtle gold top border — luxury signature
        border: Border(
          top: BorderSide(
            color: AppPalette.primary.withOpacity(isDark ? 0.35 : 0.20),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:      colors.shadow,
            blurRadius: 24,
            offset:     const Offset(0, -8),
          ),
          // Gold glow in dark mode
          if (isDark)
            BoxShadow(
              color:      AppPalette.primary.withOpacity(0.06),
              blurRadius: 32,
              offset:     const Offset(0, -4),
            ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // ── Home ────────────────────────────────────────────
              _NavItem(
                icon:        Icons.home_rounded,
                outlinedIcon: Icons.home_outlined,
                label:       'Home',
                selected:    currentIndex == 0,
                onTap:       () => onTap(0),
              ),

              // ── Cart ────────────────────────────────────────────
              _NavItem(
                icon:        Icons.shopping_bag_rounded,
                outlinedIcon: Icons.shopping_bag_outlined,
                label:       'Cart',
                selected:    currentIndex == 1,
                badgeCount:  cartCount,
                onTap:       () => onTap(1),
              ),

              // ── Orders ──────────────────────────────────────────
              _NavItem(
                icon:        Icons.receipt_long_rounded,
                outlinedIcon: Icons.receipt_long_outlined,
                label:       'Orders',
                selected:    currentIndex == 2,
                onTap:       () => onTap(2),
              ),

              // ── Wishlist ────────────────────────────────────────
              _NavItem(
                icon:        Icons.favorite_rounded,
                outlinedIcon: Icons.favorite_border_rounded,
                label:       'Wishlist',
                selected:    currentIndex == 3,
                badgeCount:  favCount,
                onTap:       () => onTap(3),
              ),

              // ── Profile / Admin ──────────────────────────────────
              _NavItem(
                icon: isAdmin && !isPreviewMode
                    ? Icons.admin_panel_settings_rounded
                    : Icons.person_rounded,
                outlinedIcon: isAdmin && !isPreviewMode
                    ? Icons.admin_panel_settings_outlined
                    : Icons.person_outline_rounded,
                label:    isAdmin && !isPreviewMode ? 'Admin' : 'Profile',
                selected: currentIndex == 4,
                photoUrl: isAdmin && !isPreviewMode ? null : photoUrl,
                onTap:    () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Individual Nav Item ────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  final bool selected;
  final int badgeCount;
  final String? photoUrl;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.label,
    required this.selected,
    this.badgeCount = 0,
    this.photoUrl,
    required this.onTap,
  });

  bool _hasValidPhoto() {
    if (photoUrl == null) return false;
    final v = photoUrl!.trim();
    return v.isNotEmpty &&
        (v.startsWith('http://') || v.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark  = context.isDarkMode;

    return GestureDetector(
      onTap:     onTap,
      behavior:  HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve:    Curves.easeInOut,
        padding:  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: selected
            ? BoxDecoration(
                // Gold pill background when selected
                gradient: LinearGradient(
                  colors: [
                    AppPalette.primary.withOpacity(isDark ? 0.18 : 0.12),
                    AppPalette.primaryLight.withOpacity(isDark ? 0.10 : 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppPalette.primary.withOpacity(isDark ? 0.30 : 0.18),
                  width: 1,
                ),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment:   Alignment.center,
              children: [
                // ── Icon / Avatar ──────────────────────────────
                if (_hasValidPhoto())
                  Container(
                    width:  28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(photoUrl!),
                        fit:   BoxFit.cover,
                      ),
                      border: Border.all(
                        color: selected
                            ? AppPalette.primary
                            : colors.borderSoft,
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color:      AppPalette.primary.withOpacity(0.30),
                                blurRadius: 8,
                                offset:     Offset.zero,
                              ),
                            ]
                          : null,
                    ),
                  )
                else
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      selected ? icon : outlinedIcon,
                      key:   ValueKey(selected),
                      color: selected
                          ? AppPalette.primary
                          : colors.textSecondary,
                      size: 24,
                      shadows: selected
                          ? [
                              Shadow(
                                color:      AppPalette.primary.withOpacity(0.40),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),

                // ── Badge ─────────────────────────────────────
                if (badgeCount > 0)
                  Positioned(
                    right: -10,
                    top:   -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical:   2,
                      ),
                      decoration: BoxDecoration(
                        // Gold badge — on-brand luxury feel
                        gradient: const LinearGradient(
                          colors: [AppPalette.primaryDark, AppPalette.primary],
                          begin:  Alignment.topLeft,
                          end:    Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colors.surface,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:      AppPalette.primary.withOpacity(0.40),
                            blurRadius: 6,
                            offset:     Offset.zero,
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          // Black on gold badge = luxury
                          color:      AppPalette.secondary,
                          fontSize:   9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.poppins(
                fontSize:   10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppPalette.primary
                    : colors.textSecondary,
                letterSpacing: selected ? 0.2 : 0,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}