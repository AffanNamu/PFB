// lib/features/favorites/presentation/screens/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/features/products/presentation/screens/product_detail_screen.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({
    super.key,
    this.showScaffold = true,
  });

  final bool showScaffold;

  static final FirebaseService firebaseService = FirebaseService();

  bool _hasValidImage(String url) {
    final value = url.trim();
    return value.isNotEmpty &&
        (value.startsWith('http://') ||
            value.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final body = StreamBuilder(
      stream: firebaseService.watchFavoriteProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingGrid(colors);
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return _buildEmptyState(context, colors);
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin:
                    const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  // ── Gold gradient header ─────────────────────
                  gradient: const LinearGradient(
                    colors: [
                      AppPalette.primaryDark,
                      AppPalette.primary,
                      AppPalette.primaryLight,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      // ── Black icon on gold ───────────────────
                      color: AppPalette.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${items.length} item${items.length == 1 ? '' : 's'} saved to your wishlist',
                        style: GoogleFonts.poppins(
                          // ── Black text on gold ───────────────
                          color: AppPalette.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final product = items[i];
                    return _WishlistProductCard(
                      product: product,
                      colors: colors,
                      hasValidImage: _hasValidImage,
                      onTap: () =>
                          Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                              product: product),
                        ),
                      ),
                      onRemove: () async {
                        await firebaseService
                            .toggleFavorite(product.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                '${product.name} removed from wishlist',
                                style: GoogleFonts.poppins(),
                              ),
                              behavior:
                                  SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              backgroundColor:
                                  colors.brandPrimary,
                              duration:
                                  const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    );
                  },
                  childCount: items.length,
                ),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 240,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
              ),
            ),
            const SliverToBoxAdapter(
                child: SizedBox(height: 24)),
          ],
        );
      },
    );

    if (!showScaffold) {
      return Scaffold(
        backgroundColor: colors.scaffold,
        body: SafeArea(child: body),
      );
    }

    return AppPageScaffold(
      title: 'My Wishlist',
      body: body,
    );
  }

  Widget _buildEmptyState(BuildContext context, dynamic colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colors.brandPrimary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 56,
                color: colors.brandPrimary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Wishlist is Empty',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Save your favourite your favourite items here for easy access.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingGrid(dynamic colors) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate:
          const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colors.surfaceAlt,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        color: colors.surfaceAlt,
                        borderRadius: BorderRadius.circular(6),
                      ),
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
}

class _WishlistProductCard extends StatelessWidget {
  const _WishlistProductCard({
    required this.product,
    required this.colors,
    required this.hasValidImage,
    required this.onTap,
    required this.onRemove,
  });

  final dynamic product;
  final dynamic colors;
  final bool Function(String) hasValidImage;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final discountPercent =
        product.originalPrice != null &&
                product.originalPrice! > product.price
            ? (((product.originalPrice! - product.price) /
                    product.originalPrice!) *
                100)
            .round()
            : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: hasValidImage(product.imageUrl)
                          ? Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _imagePlaceholder(colors),
                            )
                          : _imagePlaceholder(colors),
                    ),
                  ),
                  if (discountPercent > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.brandPrimary,
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-$discountPercent%',
                          style: GoogleFonts.poppins(
                            // ── Black text on gold badge ───────
                            color: AppPalette.secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.12),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 16,
                          color: colors.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    if (product.fabricType != null &&
                        product.fabricType!.isNotEmpty)
                      Container(
                        margin:
                            const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.brandPrimary
                              .withOpacity(0.10),
                          borderRadius:
                              BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.fabricType!,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: colors.brandPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Text(
                      product.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₦${product.price.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            color: colors.brandPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        if (product.originalPrice != null &&
                            product.originalPrice! >
                                product.price) ...[
                          const SizedBox(width: 4),
                          Text(
                            '₦${product.originalPrice!.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w400,
                              fontSize: 10,
                              decoration:
                                  TextDecoration.lineThrough,
                            ),
                          ),
                        ],
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

  Widget _imagePlaceholder(dynamic colors) {
    return Container(
      color: colors.surfaceAlt,
      child: Center(
        child: Icon(
          Icons.texture_rounded,
          color: colors.textSecondary.withOpacity(0.4),
          size: 32,
        ),
      ),
    );
  }
}