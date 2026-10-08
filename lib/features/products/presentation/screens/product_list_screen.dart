import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/routing/app_router.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';
import 'package:pfb/features/cart/presentation/screens/cart_screen.dart';
import 'package:pfb/features/orders/presentation/screens/order_screen.dart';
import 'package:pfb/features/products/data/product_repository.dart';
import 'package:pfb/features/products/presentation/screens/product_detail_screen.dart';
import 'package:pfb/features/profile/presentation/screens/profile_screen.dart';
import 'package:pfb/features/shared/presentation/widgets/app_shimmer_loader.dart';
import 'package:pfb/features/shared/presentation/widgets/empty_state_card.dart';
import 'package:pfb/models/product_model.dart';
import 'package:pfb/services/admin_preview_scope.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_status_chip.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';

// ── Store Categories ─────────────────────────────────────────────────────────

class _StoreCategories {
  static const List<Map<String, dynamic>> items = [
    {'label': 'All',             'emoji': '🏪'},
    {'label': 'Abayas',          'emoji': '🧕'},
    {'label': 'Hijabs',          'emoji': '🧣'},
    {'label': 'Bags',            'emoji': '👜'},
    {'label': 'Jilbabs',         'emoji': '🥻'},
    {'label': 'Khimars',         'emoji': '🌙'},
    {'label': 'Lace',               'emoji': '🤍'},
    {'label': 'Atampa',             'emoji': '🧵'},
    {'label': 'Kaftans',         'emoji': '👗'},
    {'label': 'Dresses',         'emoji': '💃'},
    {'label': 'Two-Piece Sets',  'emoji': '✨'},
    {'label': 'Prayer Wear',     'emoji': '🕌'},
    {'label': 'Scarves',         'emoji': '🎀'},
    {'label': 'Shoes',           'emoji': '👠'},
    {'label': 'Jewelry',         'emoji': '💍'},
    {'label': 'Perfumes',        'emoji': '🌸'},
    {'label': 'Accessories',     'emoji': '🛍️'},
    {'label': 'Kids',            'emoji': '👧'},
    {'label': 'New Arrivals',    'emoji': '🆕'},
    {'label': 'Best Sellers',    'emoji': '⭐'},
    {'label': 'Trending',        'emoji': '🔥'},
    {'label': 'Featured',        'emoji': '💫'},
  ];
}

// ── Quick Actions Data ─────────────────────────────────────────────────────────

class _QuickActionData {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });
}

// ── Occasion Data ──────────────────────────────────────────────────────────────

class _OccasionData {
  final String label;
  final String emoji;
  final Color color;

  const _OccasionData({
    required this.label,
    required this.emoji,
    required this.color,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// ProductListScreen
// ═══════════════════════════════════════════════════════════════════════════════

class ProductListScreen extends StatefulWidget {
  final bool showBottomNav;

  const ProductListScreen({super.key, this.showBottomNav = true});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen>
    with SingleTickerProviderStateMixin {
  final _repo           = ProductRepository();
  final _firebaseService = FirebaseService();
  final _searchCtrl     = TextEditingController();
  final _scrollCtrl     = ScrollController();

  String _selectedCategory  = 'All';
  bool   _showSearchFocused = false;
  late   AnimationController _promoAnimCtrl;
  late   Animation<double>   _promoAnim;

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _matchesSearch(ProductModel p, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return p.name.toLowerCase().contains(q) ||
        p.description.toLowerCase().contains(q) ||
        p.normalizedCategories.any((c) => c.toLowerCase().contains(q)) ||
        p.variants.any((v) => v.toLowerCase().contains(q)) ||
        p.fabricType.toLowerCase().contains(q) ||
        p.material.toLowerCase().contains(q) ||
        p.occasion.toLowerCase().contains(q);
  }

  bool _matchesCategory(ProductModel p, String category) {
    if (category == 'All') return true;
    return p.hasCategory(category);
  }

  bool _hasValidImage(String url) {
    final v = url.trim();
    return v.isNotEmpty &&
        (v.startsWith('http://') || v.startsWith('https://'));
  }

  bool get _isGuest => FirebaseAuth.instance.currentUser == null;

  Future<void> _goToLogin() async {
    await AppRouter.clearAndGo(context, RouteNames.login);
  }

  Future<void> _openNotifications() async {
    if (_isGuest) {
      _openGuestNotificationsPanel();
      return;
    }
    await Navigator.of(context).pushNamed(RouteNames.notifications);
  }

  void _openGuestNotificationsPanel() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final c    = ctx.appColors;
        final dark = ctx.isDarkMode;

        return Container(
          decoration: BoxDecoration(
            color:        c.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            border: Border(
              top: BorderSide(
                color: AppPalette.primary.withOpacity(dark ? 0.30 : 0.15),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width:  42,
                      height: 4,
                      decoration: BoxDecoration(
                        color:        AppPalette.primary.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppPalette.primaryDark,
                              AppPalette.primary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: AppPalette.secondary,
                          size:  22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Sakash Notifications',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize:   18,
                          color:      c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sign in to receive updates on your orders, '
                    'new arrivals, exclusive deals & delivery tracking.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color:    c.textSecondary,
                      height:   1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width:  double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await _goToLogin();
                      },
                      icon:  const Icon(Icons.login_rounded),
                      label: Text(
                        'Sign In to Sakash Collection',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize:   15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _firebaseService.seedDefaultCategoriesIfMissing();
    _firebaseService.seedDefaultAppSettings();

    _promoAnimCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 600),
    );
    _promoAnim = CurvedAnimation(
      parent: _promoAnimCtrl,
      curve:  Curves.easeOut,
    );
    _promoAnimCtrl.forward();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _promoAnimCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final previewController = AdminPreviewScope.of(context);
    final colors            = context.appColors;

    final body = SafeArea(
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: _firebaseService.watchUserProfile(),
        builder: (context, profileSnapshot) {
          final profile        = profileSnapshot.data ?? {};
          final authUser       = FirebaseAuth.instance.currentUser;

          final profileDisplayName =
              (profile['displayName'] ?? '').toString().trim();
          final authDisplayName =
              (authUser?.displayName ?? '').trim();
          final authEmail = (authUser?.email ?? '').trim();

          final displayName = profileDisplayName.isNotEmpty
              ? profileDisplayName
              : (authDisplayName.isNotEmpty
                  ? authDisplayName
                  : (_isGuest
                      ? 'Guest'
                      : (authEmail.isNotEmpty ? authEmail : 'User')));

          final profilePhotoUrl =
              (profile['photoUrl'] ?? '').toString().trim();
          final authPhotoUrl    = (authUser?.photoURL ?? '').trim();
          final headerPhotoUrl  = profilePhotoUrl.isNotEmpty
              ? profilePhotoUrl
              : authPhotoUrl;
          final hasHeaderPhoto  = _hasValidImage(headerPhotoUrl);

          return StreamBuilder<List<String>>(
            stream: _firebaseService.watchCategories(),
            builder: (context, categorySnapshot) {
              final dynamicCategories =
                  categorySnapshot.data ?? const <String>[];

              final staticLabels = _StoreCategories.items
                  .map((e) => e['label'] as String)
                  .toSet();
              final extraFromDB = dynamicCategories
                  .where((c) => !staticLabels.contains(c))
                  .toList();

              final allCategories = [
                ..._StoreCategories.items
                    .map((e) => e['label'] as String),
                ...extraFromDB,
              ];

              final effectiveCategory =
                  allCategories.contains(_selectedCategory)
                      ? _selectedCategory
                      : 'All';

              return StreamBuilder<List<ProductModel>>(
                stream: _repo.watchProducts(),
                builder: (context, productSnapshot) {
                  if (productSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return _buildSkeletonLoader();
                  }

                  final items    = productSnapshot.data ?? [];
                  final query    =
                      _searchCtrl.text.trim().toLowerCase();

                  final filtered = items.where((p) {
                    return _matchesSearch(p, query) &&
                        _matchesCategory(p, effectiveCategory);
                  }).toList();

                  final trendingItems =
                      items.where((p) => p.isTrending).toList();
                  final newArrivals =
                      items.where((p) => p.isNewArrival).toList();
                  final bestSellers =
                      items.where((p) => p.isBestSeller).toList();
                  final featuredItems =
                      items.where((p) => p.featured).toList();

                  return StreamBuilder<List<String>>(
                    stream: _firebaseService.watchFavorites(),
                    builder: (context, favSnapshot) {
                      final favorites = favSnapshot.data ?? [];

                      return CustomScrollView(
                        controller: _scrollCtrl,
                        slivers: [
                          // ── 1. HEADER ──────────────────────────
                          SliverToBoxAdapter(
                            child: _buildHeader(
                              context,
                              colors:         colors,
                              displayName:    displayName,
                              hasHeaderPhoto: hasHeaderPhoto,
                              headerPhotoUrl: headerPhotoUrl,
                            ),
                          ),

                          // ── 2. GUEST BANNER ────────────────────
                          if (_isGuest)
                            SliverToBoxAdapter(
                              child: _buildGuestBanner(colors),
                            ),

                          // ── 3. ADMIN PREVIEW BANNER ────────────
                          if (previewController.isPreviewMode)
                            SliverToBoxAdapter(
                              child: _buildPreviewBanner(colors),
                            ),

                          // ── 4. SEARCH BAR ──────────────────────
                          SliverToBoxAdapter(
                            child: _buildSearchBar(colors),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 14)),

                          // ── 5. DELIVER TO ──────────────────────
                          SliverToBoxAdapter(
                            child: _buildDeliverToCard(colors),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 14)),

                          // ── 6. MAIN ACTION CARDS ───────────────
                          SliverToBoxAdapter(
                            child: _buildMainActionCards(colors),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 14)),

                          // ── 7. QUICK ACTIONS ───────────────────
                          SliverToBoxAdapter(
                            child: _buildQuickActions(colors),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 16)),

                          // ── 8. PROMO BANNER ────────────────────
                          SliverToBoxAdapter(
                            child: _buildPromoBanner(colors),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 16)),

                          // ── 9. SHOP BY OCCASION ────────────────
                          SliverToBoxAdapter(
                            child: _buildSectionHeader(
                              colors,
                              title: 'Shop by Occasion 🎉',
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _buildOccasionRow(colors),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 16)),

                          // ── 10. FABRIC CATEGORY CHIPS ──────────
                          SliverToBoxAdapter(
                            child: _buildSectionHeader(
                              colors,
                              title: 'Browse by Category',
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _buildCategoryChips(
                              allCategories,
                              effectiveCategory,
                              colors,
                            ),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 16)),

                          // ── 11. TRENDING NOW ───────────────────
                          SliverToBoxAdapter(
                            child: _buildSectionHeader(
                              colors,
                              title: 'Trending Now 🔥',
                            ),
                          ),
                          if (trendingItems.isEmpty)
                            _buildEmptySliver(
                              icon:     Icons.local_fire_department_outlined,
                              title:    'No trending products yet',
                              subtitle: 'Mark products as trending from admin panel.',
                            )
                          else
                            SliverToBoxAdapter(
                              child: _buildHorizontalProductList(
                                context,
                                items:     trendingItems,
                                favorites: favorites,
                              ),
                            ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 16)),

                          // ── 12. NEW ARRIVALS ───────────────────
                          if (newArrivals.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: _buildSectionHeader(
                                colors,
                                title:       'New Arrivals 🆕',
                                actionLabel: 'See All',
                                onAction: () => setState(
                                  () => _selectedCategory = 'New Arrivals',
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: _buildHorizontalProductList(
                                context,
                                items:     newArrivals,
                                favorites: favorites,
                              ),
                            ),
                            const SliverToBoxAdapter(
                                child: SizedBox(height: 16)),
                          ],

                          // ── 13. BEST SELLERS ───────────────────
                          if (bestSellers.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: _buildSectionHeader(
                                colors,
                                title:       'Best Sellers ⭐',
                                actionLabel: 'See All',
                                onAction: () => setState(
                                  () => _selectedCategory = 'Best Sellers',
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: _buildHorizontalProductList(
                                context,
                                items:     bestSellers,
                                favorites: favorites,
                              ),
                            ),
                            const SliverToBoxAdapter(
                                child: SizedBox(height: 16)),
                          ],

                          // ── 14. FEATURED COLLECTION ────────────
                          if (featuredItems.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: _buildSectionHeader(
                                colors,
                                title: 'Featured Collection 💫',
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: _buildHorizontalProductList(
                                context,
                                items:      featuredItems,
                                favorites:  favorites,
                                cardWidth:  200,
                                cardHeight: 240,
                              ),
                            ),
                            const SliverToBoxAdapter(
                                child: SizedBox(height: 16)),
                          ],

                          // ── 15. SHOP BY GENDER ─────────────────
                          SliverToBoxAdapter(
                            child: _buildSectionHeader(
                              colors,
                              title: 'Shop by Gender 👗',
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _buildGenderRow(colors),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 16)),

                          // ── 16. ALL PRODUCTS GRID ──────────────
                          SliverToBoxAdapter(
                            child: _buildSectionHeader(
                              colors,
                              title: effectiveCategory == 'All'
                                  ? 'All Products'
                                  : effectiveCategory,
                              subtitle: filtered.isEmpty
                                  ? null
                                  : '${filtered.length} items',
                            ),
                          ),

                          if (filtered.isEmpty)
                            _buildEmptySliver(
                              icon:     Icons.inventory_2_outlined,
                              title:    'No products found',
                              subtitle: 'Try a different category or search term.',
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 0, 16, 8),
                              sliver: SliverGrid(
                                delegate: SliverChildBuilderDelegate(
                                  (_, i) {
                                    final product  = filtered[i];
                                    final isFav    =
                                        favorites.contains(product.id);
                                    return _ProductGridCard(
                                      product:    product,
                                      isFavorite: isFav,
                                      onTap: () =>
                                          _openProduct(context, product),
                                      onFavorite: () =>
                                          _toggleFav(product.id),
                                    );
                                  },
                                  childCount: filtered.length,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 240,
                                  childAspectRatio: 0.68,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing:  12,
                                ),
                              ),
                            ),

                          // ── 17. BOTTOM PROMO STRIP ─────────────
                          SliverToBoxAdapter(
                            child: _buildBottomPromoStrip(colors),
                          ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 32)),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );

    if (!widget.showBottomNav) {
      return Scaffold(
        backgroundColor: context.appColors.scaffold,
        body:            body,
      );
    }

    return StreamBuilder<int>(
      stream: _firebaseService.watchUnreadNotificationCount(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor:   context.appColors.scaffold,
          body:              body,
          bottomNavigationBar: _buildStandaloneBottomNav(context),
        );
      },
    );
  }

  // ── Action Helpers ────────────────────────────────────────────────────────

  void _openProduct(BuildContext context, ProductModel product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }

  Future<void> _toggleFav(String productId) async {
    if (_isGuest) { await _goToLogin(); return; }
    await _firebaseService.toggleFavorite(productId);
  }

  // ── Skeleton Loader ───────────────────────────────────────────────────────

  Widget _buildSkeletonLoader() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing:  12,
      ),
      itemBuilder: (_, __) => AppSurfaceCard(
        padding:      const EdgeInsets.all(10),
        borderRadius: BorderRadius.circular(20),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppShimmerLoader(
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ),
            SizedBox(height: 10),
            AppShimmerLoader(height: 12, width: 100),
            SizedBox(height: 6),
            AppShimmerLoader(height: 10, width: 70),
            SizedBox(height: 6),
            AppShimmerLoader(height: 10, width: 50),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context, {
    required AppThemeColors colors,
    required String displayName,
    required bool hasHeaderPhoto,
    required String headerPhotoUrl,
  }) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          // ── Avatar ────────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const ProfileScreen()),
            ),
            child: Container(
              width:  48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasHeaderPhoto
                    ? null
                    : const LinearGradient(
                        colors: [
                          AppPalette.primaryDark,
                          AppPalette.primary,
                        ],
                        begin: Alignment.topLeft,
                        end:   Alignment.bottomRight,
                      ),
                image: hasHeaderPhoto
                    ? DecorationImage(
                        image: NetworkImage(headerPhotoUrl),
                        fit:   BoxFit.cover,
                      )
                    : null,
                border: Border.all(
                  color: AppPalette.primary.withOpacity(
                    isDark ? 0.60 : 0.40,
                  ),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:      AppPalette.primary.withOpacity(
                      isDark ? 0.30 : 0.15,
                    ),
                    blurRadius: 10,
                    offset:     const Offset(0, 3),
                  ),
                ],
              ),
              child: !hasHeaderPhoto
                  ? Center(
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'P',
                        style: GoogleFonts.poppins(
                          color:      AppPalette.secondary,
                          fontWeight: FontWeight.w800,
                          fontSize:   18,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // ── Brand + Greeting ──────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Gold brand badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical:   5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppPalette.primaryDark,
                            AppPalette.primary,
                            AppPalette.primaryLight,
                          ],
                          begin: Alignment.topLeft,
                          end:   Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color:      AppPalette.primary
                                .withOpacity(isDark ? 0.45 : 0.30),
                            blurRadius: 10,
                            offset:     const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        'S',
                        style: GoogleFonts.cinzel(
                          color:         AppPalette.secondary,
                          fontSize:      12,
                          fontWeight:    FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sakash Collection',
                      style: GoogleFonts.playfairDisplay(
                        fontWeight: FontWeight.w800,
                        fontSize:   17,
                        color:      colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _isGuest
                      ? '👋 Welcome! Discover our collection'
                      : '👋 Welcome back, $displayName',
                  style: GoogleFonts.poppins(
                    color:      colors.textSecondary,
                    fontSize:   12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Notification Bell ─────────────────────────────────
          StreamBuilder<int>(
            stream: _firebaseService.watchUnreadNotificationCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;

              return GestureDetector(
                onTap: _openNotifications,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width:  44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:  colors.surface,
                        shape:  BoxShape.circle,
                        border: Border.all(
                          color: AppPalette.primary.withOpacity(
                            isDark ? 0.30 : 0.15,
                          ),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:      colors.shadow,
                            blurRadius: 12,
                            offset:     const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: colors.iconPrimary,
                        size:  22,
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -4,
                        top:   -4,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth:  18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical:   2,
                          ),
                          decoration: BoxDecoration(
                            // Gold badge
                            gradient: const LinearGradient(
                              colors: [
                                AppPalette.primaryDark,
                                AppPalette.primary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: colors.surface,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 99
                                  ? '99+'
                                  : '$unreadCount',
                              style: GoogleFonts.poppins(
                                color:      AppPalette.secondary,
                                fontSize:   9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── GUEST BANNER ──────────────────────────────────────────────────────────

  Widget _buildGuestBanner(AppThemeColors colors) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppPalette.primary.withOpacity(isDark ? 0.15 : 0.10),
              AppPalette.primaryLight.withOpacity(isDark ? 0.08 : 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppPalette.primary.withOpacity(isDark ? 0.30 : 0.20),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppPalette.primaryDark, AppPalette.primary],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppPalette.secondary,
                size:  18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sign in to save wishlists, track orders & get '
                'personalised recommendations.',
                style: GoogleFonts.poppins(
                  color:      AppPalette.primary,
                  fontWeight: FontWeight.w600,
                  fontSize:   11.5,
                  height:     1.4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _goToLogin,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical:   8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppPalette.primaryDark, AppPalette.primary],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color:      AppPalette.primary.withOpacity(0.30),
                      blurRadius: 8,
                      offset:     const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Sign In',
                  style: GoogleFonts.poppins(
                    color:      AppPalette.secondary,
                    fontWeight: FontWeight.w800,
                    fontSize:   12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── PREVIEW BANNER ────────────────────────────────────────────────────────

  Widget _buildPreviewBanner(AppThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppPalette.primaryDark, AppPalette.primary],
            begin:  Alignment.centerLeft,
            end:    Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.visibility_rounded,
              color: AppPalette.secondary,
              size:  18,
            ),
            const SizedBox(width: 8),
            Text(
              'Admin Preview Mode — Sakash Collection',
              style: GoogleFonts.poppins(
                color:      AppPalette.secondary,
                fontWeight: FontWeight.w700,
                fontSize:   12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SEARCH BAR ────────────────────────────────────────────────────────────

  Widget _buildSearchBar(AppThemeColors colors) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color:        colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _showSearchFocused
                ? AppPalette.primary
                : colors.borderSoft,
            width: _showSearchFocused ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _showSearchFocused
                  ? AppPalette.primary.withOpacity(isDark ? 0.20 : 0.12)
                  : colors.shadow,
              blurRadius: _showSearchFocused ? 16 : 8,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller:  _searchCtrl,
          onChanged:   (_) => setState(() {}),
          onTap:       () => setState(() => _showSearchFocused = true),
          onSubmitted: (_) => setState(() => _showSearchFocused = false),
          decoration: InputDecoration(
            hintText: 'Search abayas, hijabs, bags...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color:    colors.textSecondary,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: _showSearchFocused
                  ? AppPalette.primary
                  : colors.iconPrimary,
            ),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.iconPrimary,
                      size:  20,
                    ),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _showSearchFocused = false);
                    },
                  )
                : null,
            border:         InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical:   14,
              horizontal: 4,
            ),
          ),
        ),
      ),
    );
  }

  // ── DELIVER TO ────────────────────────────────────────────────────────────

  Widget _buildDeliverToCard(AppThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<String>(
        stream: _firebaseService.watchSelectedAddress(),
        builder: (context, addressSnapshot) {
          final selectedAddress = addressSnapshot.data ?? '';

          return AppSurfaceCard(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical:   12,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppPalette.primaryDark, AppPalette.primary],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppPalette.secondary,
                    size:  18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deliver To',
                        style: GoogleFonts.poppins(
                          color:      colors.textSecondary,
                          fontSize:   11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isGuest
                            ? 'Sign in to set delivery address'
                            : (selectedAddress.isEmpty
                                ? 'No address selected'
                                : selectedAddress),
                        style: GoogleFonts.poppins(
                          color: (_isGuest || selectedAddress.isEmpty)
                              ? colors.textSecondary
                              : colors.textPrimary,
                          fontSize:   12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _isGuest
                      ? _goToLogin
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical:   7,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppPalette.primaryDark, AppPalette.primary],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color:      AppPalette.primary.withOpacity(0.25),
                          blurRadius: 8,
                          offset:     const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Change',
                      style: GoogleFonts.poppins(
                        color:      AppPalette.secondary,
                        fontWeight: FontWeight.w700,
                        fontSize:   12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── MAIN ACTION CARDS ─────────────────────────────────────────────────────

  Widget _buildMainActionCards(AppThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Browse Products — gold gradient
          Expanded(
            child: _MainActionCard(
              title:    'Browse\nProducts',
              subtitle: 'Ankara, Lace & more',
              icon:     Icons.style_rounded,
              gradientColors: const [
                AppPalette.primaryDark,
                AppPalette.primary,
                AppPalette.primaryLight,
              ],
              textColor: AppPalette.secondary,
              onTap: () => setState(() => _selectedCategory = 'All'),
            ),
          ),
          const SizedBox(width: 12),
          // Fabric Teloring Service — black gradient
          Expanded(
            child: _MainActionCard(
              title:    'Teloring\nService',
              subtitle: 'Expert styling',
              icon:     Icons.content_cut_rounded,
              gradientColors: const [
                Color(0xFF111111),
                Color(0xFF2A2A2A),
              ],
              textColor: Colors.white,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✂️ Style Consultation — Coming Soon!',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: const Color(0xFF1A1A1A),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── QUICK ACTIONS ─────────────────────────────────────────────────────────

  Widget _buildQuickActions(AppThemeColors colors) {
    final isDark = context.isDarkMode;

    // Gold-tinted quick action backgrounds
    final actions = [
      _QuickActionData(
        icon:      Icons.shopping_bag_rounded,
        label:     'Cart',
        bgColor:   isDark
            ? AppPalette.darkPaleGold
            : AppPalette.paleGold,
        iconColor: AppPalette.primary,
        onTap: () {
          if (_isGuest) { _goToLogin(); return; }
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CartScreen()),
          );
        },
      ),
      _QuickActionData(
        icon:      Icons.receipt_long_rounded,
        label:     'Orders',
        bgColor:   isDark
            ? AppPalette.darkPaleBlue
            : AppPalette.paleBlue,
        iconColor: AppPalette.info,
        onTap: () {
          if (_isGuest) { _goToLogin(); return; }
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OrderScreen()),
          );
        },
      ),
      _QuickActionData(
        icon:      Icons.favorite_rounded,
        label:     'Wishlist',
        bgColor:   isDark
            ? AppPalette.darkPaleRed
            : AppPalette.paleRed,
        iconColor: AppPalette.error,
        onTap: () {
          if (_isGuest) { _goToLogin(); return; }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ProfileScreen(showScaffold: true),
            ),
          );
        },
      ),
      _QuickActionData(
        icon:      Icons.local_shipping_rounded,
        label:     'Track',
        bgColor:   isDark
            ? AppPalette.darkPaleGreen
            : AppPalette.paleGreen,
        iconColor: AppPalette.success,
        onTap: () {
          if (_isGuest) { _goToLogin(); return; }
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OrderScreen()),
          );
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: actions
            .map(
              (a) => Expanded(
                child: _QuickActionItem(
                  icon:      a.icon,
                  label:     a.label,
                  bgColor:   a.bgColor,
                  iconColor: a.iconColor,
                  onTap:     a.onTap,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── PROMO BANNER ──────────────────────────────────────────────────────────

  Widget _buildPromoBanner(AppThemeColors colors) {
    return FadeTransition(
      opacity: _promoAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width:   double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            // Luxury dark + gold shimmer — brand-perfect
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0B0B0B),
                Color(0xFF1A1000),
                AppPalette.primaryDark,
              ],
              stops: [0.0, 0.55, 1.0],
              begin: Alignment.centerLeft,
              end:   Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color:      AppPalette.primary.withOpacity(0.35),
                blurRadius: 20,
                offset:     const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical:   4,
                      ),
                      decoration: BoxDecoration(
                        color:        AppPalette.primary.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppPalette.primary.withOpacity(0.40),
                        ),
                      ),
                      child: Text(
                        _isGuest ? '🎁 New Customer Offer' : '🔥 Flash Sale',
                        style: GoogleFonts.poppins(
                          color:      AppPalette.primaryLight,
                          fontSize:   11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isGuest
                          ? 'Sign in & get 25% off your first order!'
                          : 'Premium Ankara & Lace — Up to 30% OFF this week!',
                      style: GoogleFonts.poppins(
                        color:      Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize:   14,
                        height:     1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _isGuest ? _goToLogin : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical:   8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppPalette.primaryDark,
                              AppPalette.primary,
                              AppPalette.primaryLight,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color:      AppPalette.primary
                                  .withOpacity(0.40),
                              blurRadius: 10,
                              offset:     const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          _isGuest ? 'Sign In Now' : 'Shop Now',
                          style: GoogleFonts.poppins(
                            color:      AppPalette.secondary,
                            fontWeight: FontWeight.w800,
                            fontSize:   12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Decorative gold emblem
              Container(
                width:  68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppPalette.primaryDark, AppPalette.primary],
                    begin:  Alignment.topLeft,
                    end:    Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:      AppPalette.primary.withOpacity(0.40),
                      blurRadius: 14,
                      offset:     Offset.zero,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'S',
                    style: GoogleFonts.cinzel(
                      color:         AppPalette.secondary,
                      fontSize:      20,
                      fontWeight:    FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── OCCASION ROW ──────────────────────────────────────────────────────────

  Widget _buildOccasionRow(AppThemeColors colors) {
    final isDark = context.isDarkMode;

    final occasions = [
      _OccasionData(
        label: 'Wedding',
        emoji: '💍',
        color: isDark ? const Color(0xFF2A1020) : const Color(0xFFFCE4EC),
      ),
      _OccasionData(
        label: 'Sallah',
        emoji: '🌙',
        color: isDark ? const Color(0xFF0A1F14) : const Color(0xFFE8F5E9),
      ),
      _OccasionData(
        label: 'Naming',
        emoji: '👶',
        color: isDark ? const Color(0xFF0A1428) : const Color(0xFFE3F2FD),
      ),
      _OccasionData(
        label: 'Birthday',
        emoji: '🎂',
        color: isDark ? const Color(0xFF1A1000) : const Color(0xFFFFF9C4),
      ),
      _OccasionData(
        label: 'Corporate',
        emoji: '👔',
        color: isDark ? const Color(0xFF160D2E) : const Color(0xFFEDE7F6),
      ),
      _OccasionData(
        label: 'Burial',
        emoji: '🕊️',
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF3E5F5),
      ),
    ];

    return SizedBox(
      height: 88,
      child: ListView.separated(
        padding:         const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount:       occasions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final o        = occasions[i];
          final isSelected = _selectedCategory == o.label;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = o.label),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width:  56,
                  height: 56,
                  decoration: BoxDecoration(
                    color:        o.color,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? AppPalette.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color:      AppPalette.primary
                                  .withOpacity(0.30),
                              blurRadius: 10,
                              offset:     Offset.zero,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      o.emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  o.label,
                  style: GoogleFonts.poppins(
                    fontSize:   10,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: isSelected
                        ? AppPalette.primary
                        : colors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── CATEGORY CHIPS ────────────────────────────────────────────────────────

  Widget _buildCategoryChips(
    List<String> categories,
    String effectiveCategory,
    AppThemeColors colors,
  ) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding:         const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount:       categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final label    = categories[i];
          final selected = label == effectiveCategory;

          final matchItem = _StoreCategories.items.firstWhere(
            (e) => e['label'] == label,
            orElse: () => {'emoji': '🧵'},
          );
          final emoji = matchItem['emoji'] as String;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical:   8,
              ),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [AppPalette.primaryDark, AppPalette.primary],
                      )
                    : null,
                color:        selected ? null : colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? AppPalette.primary
                      : colors.borderSoft,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color:      AppPalette.primary.withOpacity(0.30),
                          blurRadius: 10,
                          offset:     const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: selected
                          ? AppPalette.secondary   // black on gold
                          : colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize:   12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── GENDER ROW ────────────────────────────────────────────────────────────

  Widget _buildGenderRow(AppThemeColors colors) {
    final isDark  = context.isDarkMode;

    final genders = [
      {
        'label': 'Men',
        'emoji': '👔',
        'color': isDark ? const Color(0xFF0A1428) : const Color(0xFFE3F2FD),
      },
      {
        'label': 'Women',
        'emoji': '👗',
        'color': isDark ? const Color(0xFF2A1020) : const Color(0xFFFCE4EC),
      },
      {
        'label': 'Children',
        'emoji': '👧',
        'color': isDark ? const Color(0xFF1A1000) : const Color(0xFFF9FBE7),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: genders.map((g) {
          final label      = g['label'] as String;
          final isSelected = _selectedCategory == label;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: label != 'Children' ? 10 : 0,
              ),
              child: GestureDetector(
                onTap: () =>
                    setState(() => _selectedCategory = label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 64,
                  decoration: BoxDecoration(
                    color:        g['color'] as Color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppPalette.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color:      AppPalette.primary
                                  .withOpacity(0.25),
                              blurRadius: 10,
                              offset:     Offset.zero,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        g['emoji'] as String,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize:   13,
                          color: isSelected
                              ? AppPalette.primary
                              : colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── HORIZONTAL PRODUCT LIST ───────────────────────────────────────────────

  Widget _buildHorizontalProductList(
    BuildContext context, {
    required List<ProductModel> items,
    required List<String> favorites,
    double cardWidth  = 180,
    double cardHeight = 220,
  }) {
    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        padding:         const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount:       items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final product = items[i];
          final isFav   = favorites.contains(product.id);
          return _HorizontalProductCard(
            product:    product,
            isFavorite: isFav,
            width:      cardWidth,
            onTap:      () => _openProduct(context, product),
            onFavorite: () => _toggleFav(product.id),
          );
        },
      ),
    );
  }

  // ── SECTION HEADER ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(
    AppThemeColors colors, {
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          // Gold gradient accent bar
          Container(
            width:  4,
            height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppPalette.primaryDark, AppPalette.primaryLight],
                begin:  Alignment.topCenter,
                end:    Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize:   16,
                    color:      colors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color:    colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical:   6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppPalette.primaryDark, AppPalette.primary],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.poppins(
                    color:      AppPalette.secondary,
                    fontWeight: FontWeight.w700,
                    fontSize:   12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── EMPTY SLIVER ──────────────────────────────────────────────────────────

  SliverToBoxAdapter _buildEmptySliver({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: EmptyStateCard(
          icon:     icon,
          title:    title,
          subtitle: subtitle,
        ),
      ),
    );
  }

  // ── BOTTOM PROMO STRIP ────────────────────────────────────────────────────

  Widget _buildBottomPromoStrip(AppThemeColors colors) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppPalette.darkGoldGlow : AppPalette.paleGold,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppPalette.primary.withOpacity(isDark ? 0.30 : 0.20),
          ),
        ),
        child: Row(
          children: [
            const Text('🧵', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Free Delivery',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize:   14,
                      color:      colors.textPrimary,
                    ),
                  ),
                  Text(
                    'On all orders above ₦25,000 within Ilorin',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color:    colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.local_shipping_outlined,
              color: AppPalette.primary,
              size:  26,
            ),
          ],
        ),
      ),
    );
  }

  // ── STANDALONE BOTTOM NAV ─────────────────────────────────────────────────

  Widget _buildStandaloneBottomNav(BuildContext context) {
    final colors = context.appColors;
    final isDark  = context.isDarkMode;

    return StreamBuilder<int>(
      stream: _firebaseService.watchCartCount(),
      builder: (context, cartSnap) {
        final count = cartSnap.data ?? 0;

        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              top: BorderSide(
                color: AppPalette.primary.withOpacity(
                  isDark ? 0.30 : 0.15,
                ),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color:      colors.shadow,
                blurRadius: 16,
                offset:     const Offset(0, -4),
              ),
            ],
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: BottomNavigationBar(
              currentIndex:        0,
              backgroundColor:     Colors.transparent,
              selectedItemColor:   AppPalette.primary,
              unselectedItemColor: colors.textSecondary,
              elevation:           0,
              selectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize:   11,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize:   11,
              ),
              onTap: (index) {
                switch (index) {
                  case 1:
                    if (_isGuest) { _goToLogin(); return; }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const CartScreen()),
                    );
                    break;
                  case 2:
                    if (_isGuest) { _goToLogin(); return; }
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => OrderScreen()),
                    );
                    break;
                  case 3:
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen()),
                    );
                    break;
                }
              },
              items: [
                const BottomNavigationBarItem(
                  icon:  Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_bag_rounded),
                      if (count > 0)
                        Positioned(
                          right: -8,
                          top:   -6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppPalette.primaryDark,
                                  AppPalette.primary,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color:    AppPalette.secondary,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: 'Cart',
                ),
                const BottomNavigationBarItem(
                  icon:  Icon(Icons.receipt_long_rounded),
                  label: 'Orders',
                ),
                const BottomNavigationBarItem(
                  icon:  Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _MainActionCard
// ═══════════════════════════════════════════════════════════════════════════════

class _MainActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Color textColor;
  final VoidCallback onTap;

  const _MainActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height:  130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color:      gradientColors.last.withOpacity(0.35),
              blurRadius: 14,
              offset:     const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width:  44,
              height: 44,
              decoration: BoxDecoration(
                color:        Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: textColor, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.poppins(
                color:      textColor,
                fontWeight: FontWeight.w800,
                fontSize:   15,
                height:     1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                color:      textColor.withOpacity(0.75),
                fontSize:   10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _QuickActionItem
// ═══════════════════════════════════════════════════════════════════════════════

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    bgColor;
  final Color    iconColor;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap:        onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          children: [
            Container(
              width:  52,
              height: 52,
              decoration: BoxDecoration(
                color:        bgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:      colors.shadow,
                    blurRadius: 8,
                    offset:     const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize:   11,
                color:      colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _HorizontalProductCard
// ═══════════════════════════════════════════════════════════════════════════════

class _HorizontalProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isFavorite;
  final double width;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const _HorizontalProductCard({
    required this.product,
    required this.isFavorite,
    required this.width,
    required this.onTap,
    required this.onFavorite,
  });

  bool get _hasValidImage =>
      product.imageUrl.trim().isNotEmpty &&
      (product.imageUrl.startsWith('http://') ||
          product.imageUrl.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: AppSurfaceCard(
        padding:      EdgeInsets.zero,
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image ────────────────────────────────────────
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      child: _hasValidImage
                          ? Image.network(
                              product.imageUrl,
                              width: double.infinity,
                              fit:   BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _placeholder(context),
                            )
                          : _placeholder(context),
                    ),

                    // Discount badge
                    if (product.hasDiscount)
                      Positioned(
                        top:  8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical:   4,
                          ),
                          decoration: BoxDecoration(
                            color:        colors.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.discountLabel,
                            style: GoogleFonts.poppins(
                              color:      Colors.white,
                              fontSize:   10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                    // Status chips
                    if (!product.hasDiscount)
                      Positioned(
                        top:  8,
                        left: 8,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            if (product.isNewArrival)
                              const AppStatusChip(
                                label: 'New',
                                tone:  AppStatusChipTone.success,
                              ),
                            if (product.isTrending)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: AppStatusChip(
                                  label: 'Hot',
                                  tone:  AppStatusChipTone.warning,
                                ),
                              ),
                          ],
                        ),
                      ),

                    // Wishlist
                    Positioned(
                      top:   8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onFavorite,
                        child: Container(
                          width:  30,
                          height: 30,
                          decoration: BoxDecoration(
                            color:  Colors.white.withOpacity(0.92),
                            shape:  BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:      Colors.black
                                    .withOpacity(0.12),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite
                                ? colors.error
                                : colors.iconPrimary,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Info ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize:   12,
                        color:      colors.textPrimary,
                      ),
                    ),
                    if (product.fabricType.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.fabricType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color:    colors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (product.hasDiscount) ...[
                          Text(
                            '₦${product.discountedPrice.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize:   13,
                              color:      AppPalette.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '₦${product.price.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize:   10,
                              color:      colors.textSecondary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ] else
                          Text(
                            '₦${product.price.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize:   13,
                              color:      AppPalette.primary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: context.colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: Colors.grey,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _ProductGridCard
// ═══════════════════════════════════════════════════════════════════════════════

class _ProductGridCard extends StatelessWidget {
  final ProductModel product;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const _ProductGridCard({
    required this.product,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
  });

  bool get _hasValidImage =>
      product.imageUrl.trim().isNotEmpty &&
      (product.imageUrl.startsWith('http://') ||
          product.imageUrl.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: AppSurfaceCard(
        padding:      EdgeInsets.zero,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ───────────────────────────────────────────
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: _hasValidImage
                        ? Image.network(
                            product.imageUrl,
                            width: double.infinity,
                            fit:   BoxFit.cover,
                            loadingBuilder:
                                (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: context.colorScheme
                                    .surfaceContainerHighest,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:       AppPalette.primary,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) =>
                                _placeholder(context),
                          )
                        : _placeholder(context),
                  ),

                  // Discount badge
                  if (product.hasDiscount)
                    Positioned(
                      top:  8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical:   4,
                        ),
                        decoration: BoxDecoration(
                          color:        colors.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.discountLabel,
                          style: GoogleFonts.poppins(
                            color:      Colors.white,
                            fontSize:   9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  else
                    Positioned(
                      top:  8,
                      left: 8,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          if (product.isTrending)
                            const AppStatusChip(
                              label: 'Trending',
                              tone:  AppStatusChipTone.warning,
                            ),
                          if (product.featured)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: AppStatusChip(
                                label: 'Featured',
                                tone:  AppStatusChipTone.primary,
                              ),
                            ),
                          if (product.isNewArrival)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: AppStatusChip(
                                label: 'New',
                                tone:  AppStatusChipTone.success,
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Wishlist
                  Positioned(
                    top:   8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onFavorite,
                      child: Container(
                        width:  30,
                        height: 30,
                        decoration: BoxDecoration(
                          color:  Colors.white.withOpacity(0.92),
                          shape:  BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:      Colors.black
                                  .withOpacity(0.10),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite
                              ? colors.error
                              : colors.iconPrimary,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info ────────────────────────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize:   12,
                        color:      colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.fabricType.isNotEmpty
                          ? product.fabricType
                          : product.primaryCategory,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color:    colors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: product.hasDiscount
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '₦${product.discountedPrice.toStringAsFixed(0)}',
                                      style: GoogleFonts.poppins(
                                        color:      AppPalette.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize:   13,
                                      ),
                                    ),
                                    Text(
                                      '₦${product.price.toStringAsFixed(0)}',
                                      style: GoogleFonts.poppins(
                                        fontSize:   9,
                                        color:      colors.textSecondary,
                                        decoration:
                                            TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  '₦${product.price.toStringAsFixed(0)}',
                                  style: GoogleFonts.poppins(
                                    color:      colors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize:   13,
                                  ),
                                ),
                        ),
                        // Gold "Buy" button
                        GestureDetector(
                          onTap: onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical:   6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppPalette.primaryDark,
                                  AppPalette.primary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color:      AppPalette.primary
                                      .withOpacity(0.30),
                                  blurRadius: 8,
                                  offset:     const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Buy',
                              style: GoogleFonts.poppins(
                                color:      AppPalette.secondary,
                                fontWeight: FontWeight.w800,
                                fontSize:   10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: context.colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: Colors.grey,
        ),
      ),
    );
  }
}