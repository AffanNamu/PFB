import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/routing/app_router.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/models/product_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_status_chip.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState
    extends State<ProductDetailScreen> {
  final _firebaseService = FirebaseService();

  int     _selectedImageIndex = 0;
  String? _selectedColor;
  String? _selectedSize;
  bool    _addingToCart  = false;
  bool    _descExpanded  = false;

  List<String> get _allImages {
    final images = <String>[];
    if (_hasValidUrl(widget.product.imageUrl)) {
      images.add(widget.product.imageUrl);
    }
    for (final img in widget.product.additionalImages) {
      if (_hasValidUrl(img) && !images.contains(img)) {
        images.add(img);
      }
    }
    return images;
  }

  bool _hasValidUrl(String url) {
    final v = url.trim();
    return v.isNotEmpty &&
        (v.startsWith('http://') || v.startsWith('https://'));
  }

  bool get _isGuest =>
      FirebaseAuth.instance.currentUser == null;

  ProductModel get _product => widget.product;

  Future<void> _promptLogin(String action) async {
    final go = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final c = ctx.appColors;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: c.surface,
              title: Text(
                'Sign In Required',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color:      c.textPrimary,
                ),
              ),
              content: Text(
                'Please sign in to $action.',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  height:   1.5,
                  color:    c.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Later',
                    style: GoogleFonts.poppins(
                      color: c.textSecondary,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppPalette.primaryDark,
                        AppPalette.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor:     Colors.transparent,
                      foregroundColor: AppPalette.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!go || !mounted) return;
    await AppRouter.clearAndGo(context, RouteNames.login);
  }

  Future<void> _addToCart() async {
    if (!_product.inStock) return;

    setState(() => _addingToCart = true);
    try {
      await _firebaseService.addToCart(
        productId: _product.id,
        name:      _product.name,
        price: _product.hasDiscount
            ? _product.discountedPrice
            : _product.price,
        imageUrl: _product.imageUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppPalette.secondary,
                size:  18,
              ),
              const SizedBox(width: 8),
              Text(
                '${_product.name} added to cart!',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color:      AppPalette.secondary,
                ),
              ),
            ],
          ),
          // Gold snackbar for luxury feel
          backgroundColor: AppPalette.primary,
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark  = context.isDarkMode;
    final images  = _allImages;

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: CustomScrollView(
        slivers: [
          // ── SLIVER APP BAR ───────────────────────────────────────
          SliverAppBar(
            expandedHeight:  360,
            pinned:          true,
            backgroundColor: colors.scaffold,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:  Colors.white.withOpacity(0.92),
                  shape:  BoxShape.circle,
                  border: Border.all(
                    color: AppPalette.primary.withOpacity(0.20),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:      Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size:  18,
                  color: Colors.black87,
                ),
              ),
            ),
            actions: [
              StreamBuilder<List<String>>(
                stream: _firebaseService.watchFavorites(),
                builder: (context, snapshot) {
                  final favs  = snapshot.data ?? [];
                  final isFav = favs.contains(_product.id);

                  return GestureDetector(
                    onTap: () async {
                      if (_isGuest) {
                        await _promptLogin('save to wishlist');
                        return;
                      }
                      await _firebaseService
                          .toggleFavorite(_product.id);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      width:  38,
                      height: 38,
                      decoration: BoxDecoration(
                        color:  Colors.white.withOpacity(0.92),
                        shape:  BoxShape.circle,
                        border: Border.all(
                          color: isFav
                              ? colors.error.withOpacity(0.30)
                              : AppPalette.primary
                                  .withOpacity(0.15),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:      Colors.black
                                .withOpacity(0.12),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFav
                            ? colors.error
                            : Colors.black87,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  if (images.isEmpty)
                    Container(
                      color: context
                          .colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          size:  64,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (i) =>
                          setState(() => _selectedImageIndex = i),
                      itemBuilder: (_, i) => Image.network(
                        images[i],
                        fit:   BoxFit.cover,
                        width: double.infinity,
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
                        errorBuilder: (_, __, ___) => Container(
                          color: context.colorScheme
                              .surfaceContainerHighest,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              size:  48,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Page dots
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      left:   0,
                      right:  0,
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 200),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 3),
                            width: _selectedImageIndex == i
                                ? 20
                                : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              // Gold dots
                              color:
                                  _selectedImageIndex == i
                                      ? AppPalette.primary
                                      : Colors.white
                                          .withOpacity(0.55),
                              borderRadius:
                                  BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Out of stock
                  if (!_product.inStock)
                    Container(
                      color:     Colors.black.withOpacity(0.55),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical:   10,
                        ),
                        decoration: BoxDecoration(
                          color:        colors.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'OUT OF STOCK',
                          style: GoogleFonts.poppins(
                            color:         Colors.white,
                            fontWeight:    FontWeight.w900,
                            fontSize:      16,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── PRODUCT CONTENT ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: colors.scaffold,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Status Chips ─────────────────────────────
                    Wrap(
                      spacing:    8,
                      runSpacing: 8,
                      children: [
                        if (_product.isTrending)
                          const AppStatusChip(
                            label: 'Trending',
                            tone:  AppStatusChipTone.warning,
                            icon:
                                Icons.local_fire_department_rounded,
                          ),
                        if (_product.featured)
                          const AppStatusChip(
                            label: 'Featured',
                            tone:  AppStatusChipTone.primary,
                            icon:  Icons.star_rounded,
                          ),
                        if (_product.isNewArrival)
                          const AppStatusChip(
                            label: 'New Arrival',
                            tone:  AppStatusChipTone.success,
                          ),
                        if (_product.isBestSeller)
                          const AppStatusChip(
                            label: 'Best Seller',
                            tone:  AppStatusChipTone.warning,
                          ),
                        AppStatusChip(
                          label: _product.inStock
                              ? 'In Stock'
                              : 'Out of Stock',
                          tone: _product.inStock
                              ? AppStatusChipTone.success
                              : AppStatusChipTone.error,
                          icon: _product.inStock
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Product Name ─────────────────────────────
                    Text(
                      _product.name,
                      style: GoogleFonts.playfairDisplay(
                        fontSize:   24,
                        fontWeight: FontWeight.w800,
                        color:      colors.textPrimary,
                        height:     1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Fabric Type + Origin ─────────────────────
                    if (_product.fabricType.isNotEmpty ||
                        _product.origin.isNotEmpty)
                      Row(
                        children: [
                          if (_product
                              .fabricType.isNotEmpty) ...[
                            Icon(
                              Icons.style_rounded,
                              size:  14,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _product.fabricType,
                              style: GoogleFonts.poppins(
                                fontSize:   13,
                                color:      colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (_product.fabricType.isNotEmpty &&
                              _product.origin.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8),
                              child: Container(
                                width:  4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppPalette.primary
                                      .withOpacity(0.50),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          if (_product.origin.isNotEmpty) ...[
                            Icon(
                              Icons.public_rounded,
                              size:  14,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _product.origin,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color:    colors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),

                    const SizedBox(height: 10),

                    // ── Rating ───────────────────────────────────
                    if (_product.rating > 0)
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            final filled =
                                i < _product.rating.floor();
                            final half = !filled &&
                                i < _product.rating &&
                                _product.rating - i >= 0.5;
                            return Icon(
                              filled
                                  ? Icons.star_rounded
                                  : (half
                                      ? Icons.star_half_rounded
                                      : Icons.star_outline_rounded),
                              // Gold stars
                              color: AppPalette.primary,
                              size:  18,
                            );
                          }),
                          const SizedBox(width: 6),
                          Text(
                            '${_product.rating.toStringAsFixed(1)} (${_product.reviewCount} reviews)',
                            style: GoogleFonts.poppins(
                              fontSize:   12,
                              color:      colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_product.soldCount > 0) ...[
                            const SizedBox(width: 12),
                            Text(
                              '${_product.soldCount} sold',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color:    colors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),

                    const SizedBox(height: 16),

                    // ── Price ────────────────────────────────────
                    _buildPriceSection(colors),

                    const SizedBox(height: 20),

                    // ── Promo Text ───────────────────────────────
                    if (_product.promoText.isNotEmpty)
                      Container(
                        width:   double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical:   10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppPalette.primary
                                  .withOpacity(0.08),
                              AppPalette.primaryLight
                                  .withOpacity(0.04),
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                            color: AppPalette.primary
                                .withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_offer_rounded,
                              color: AppPalette.primary,
                              size:  16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _product.promoText,
                                style: GoogleFonts.poppins(
                                  color:      AppPalette.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize:   12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_product.promoText.isNotEmpty)
                      const SizedBox(height: 20),

                    // ── Available Colors ─────────────────────────
                    if (_product.availableColors.isNotEmpty) ...[
                      _buildSectionLabel('Available Colors', colors),
                      const SizedBox(height: 10),
                      _buildColorSelector(colors),
                      const SizedBox(height: 20),
                    ],

                    // ── Available Sizes ──────────────────────────
                    if (_product.availableSizes.isNotEmpty) ...[
                      _buildSectionLabel('Sizes / Yards', colors),
                      const SizedBox(height: 10),
                      _buildSizeSelector(colors),
                      const SizedBox(height: 20),
                    ],

                    // ── Variants ─────────────────────────────────
                    if (_product.variants.isNotEmpty) ...[
                      _buildSectionLabel('Variants', colors),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing:    8,
                        runSpacing: 8,
                        children: _product.variants.map((v) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical:   6,
                            ),
                            decoration: BoxDecoration(
                              color:        colors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppPalette.primary
                                    .withOpacity(0.20),
                              ),
                            ),
                            child: Text(
                              v,
                              style: GoogleFonts.poppins(
                                fontSize:   12,
                                color:      colors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Product Details ───────────────────────────
                    _buildFabricDetailsCard(colors),

                    const SizedBox(height: 20),

                    // ── Description ──────────────────────────────
                    _buildSectionLabel('Description', colors),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(
                          () => _descExpanded = !_descExpanded),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            _product.description.isEmpty
                                ? 'No description available.'
                                : _product.description,
                            style: GoogleFonts.poppins(
                              height:   1.7,
                              fontSize: 13,
                              color:    colors.textPrimary,
                            ),
                            maxLines: _descExpanded ? null : 4,
                            overflow: _descExpanded
                                ? null
                                : TextOverflow.ellipsis,
                          ),
                          if (_product.description.length > 200)
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 6),
                              child: Text(
                                _descExpanded
                                    ? 'Show less'
                                    : 'Read more',
                                style: GoogleFonts.poppins(
                                  color:      AppPalette.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize:   13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Categories ───────────────────────────────
                    _buildSectionLabel('Categories', colors),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing:    8,
                      runSpacing: 8,
                      children: _product.normalizedCategories
                          .map((cat) {
                        return Container(
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
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.poppins(
                              fontSize:   12,
                              color:      AppPalette.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // ── Guest Banner ─────────────────────────────
                    if (_isGuest)
                      Container(
                        margin:  const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppPalette.primary
                                  .withOpacity(
                                isDark ? 0.15 : 0.08,
                              ),
                              AppPalette.primaryLight
                                  .withOpacity(0.04),
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(14),
                          border: Border.all(
                            color: AppPalette.primary
                                .withOpacity(
                              isDark ? 0.30 : 0.15,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              color: AppPalette.primary,
                              size:  20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Sign in to save to wishlist, track orders & get personalised picks.',
                                style: GoogleFonts.poppins(
                                  fontSize:   12,
                                  color:      AppPalette.primary,
                                  fontWeight: FontWeight.w600,
                                  height:     1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Tailoring CTA ────────────────────────────
                    _buildTailoringCTA(colors, isDark),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(colors, isDark),
    );
  }

  // ── Price Section ─────────────────────────────────────────────────────────

  Widget _buildPriceSection(AppThemeColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_product.hasDiscount) ...[
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppPalette.primaryDark, AppPalette.primary],
            ).createShader(bounds),
            child: Text(
              '₦${_product.discountedPrice.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize:   28,
                fontWeight: FontWeight.w900,
                color:      Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '₦${_product.price.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize:        16,
                color:           colors.textSecondary,
                decoration:      TextDecoration.lineThrough,
                decorationColor: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical:   4,
            ),
            decoration: BoxDecoration(
              color:        colors.error,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _product.discountLabel,
              style: GoogleFonts.poppins(
                color:      Colors.white,
                fontWeight: FontWeight.w700,
                fontSize:   12,
              ),
            ),
          ),
        ] else
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppPalette.primaryDark, AppPalette.primary],
            ).createShader(bounds),
            child: Text(
              '₦${_product.price.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize:   28,
                fontWeight: FontWeight.w900,
                color:      Colors.white,
              ),
            ),
          ),

        const Spacer(),

        if (_product.inStock && _product.stockQuantity > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical:   6,
            ),
            decoration: BoxDecoration(
              color:        const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_product.stockQuantity} in stock',
              style: GoogleFonts.poppins(
                fontSize:   11,
                fontWeight: FontWeight.w700,
                color:      const Color(0xFF2E7D32),
              ),
            ),
          ),
      ],
    );
  }

  // ── Color Selector ────────────────────────────────────────────────────────

  Widget _buildColorSelector(AppThemeColors colors) {
    return Wrap(
      spacing:    10,
      runSpacing: 10,
      children: _product.availableColors.map((colorName) {
        final isSelected = _selectedColor == colorName;
        return GestureDetector(
          onTap: () =>
              setState(() => _selectedColor = colorName),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical:   8,
            ),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [
                        AppPalette.primaryDark,
                        AppPalette.primary,
                      ],
                    )
                  : null,
              color:        isSelected ? null : colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppPalette.primary
                    : colors.border,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color:      AppPalette.primary
                            .withOpacity(0.30),
                        blurRadius: 8,
                        offset:     const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              colorName,
              style: GoogleFonts.poppins(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppPalette.secondary
                    : colors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Size Selector ─────────────────────────────────────────────────────────

  Widget _buildSizeSelector(AppThemeColors colors) {
    return Wrap(
      spacing:    10,
      runSpacing: 10,
      children: _product.availableSizes.map((size) {
        final isSelected = _selectedSize == size;
        return GestureDetector(
          onTap: () => setState(() => _selectedSize = size),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width:  54,
            height: 44,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [
                        AppPalette.primaryDark,
                        AppPalette.primary,
                      ],
                    )
                  : null,
              color:        isSelected ? null : colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppPalette.primary
                    : colors.border,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color:      AppPalette.primary
                            .withOpacity(0.30),
                        blurRadius: 6,
                        offset:     const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                size,
                style: GoogleFonts.poppins(
                  fontSize:   12,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppPalette.secondary
                      : colors.textPrimary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Product Details Card ───────────────────────────────────────────────────

  Widget _buildFabricDetailsCard(AppThemeColors colors) {
    final details = <Map<String, dynamic>>[];

    if (_product.material.isNotEmpty)
      details.add({
        'icon':  Icons.texture_rounded,
        'label': 'Material',
        'value': _product.material,
      });
    if (_product.fabricType.isNotEmpty)
      details.add({
        'icon':  Icons.style_rounded,
        'label': 'Product Type',
        'value': _product.fabricType,
      });
    if (_product.gsm.isNotEmpty)
      details.add({
        'icon':  Icons.straighten_rounded,
        'label': 'GSM / Weight',
        'value': _product.gsm,
      });
    if (_product.yardage > 0)
      details.add({
        'icon':  Icons.linear_scale_rounded,
        'label': 'Yardage',
        'value': '${_product.yardage} yards',
      });
    if (_product.origin.isNotEmpty)
      details.add({
        'icon':  Icons.public_rounded,
        'label': 'Origin',
        'value': _product.origin,
      });
    if (_product.occasion.isNotEmpty)
      details.add({
        'icon':  Icons.celebration_rounded,
        'label': 'Occasion',
        'value': _product.occasion,
      });
    if (_product.gender.isNotEmpty)
      details.add({
        'icon':  Icons.person_rounded,
        'label': 'Gender',
        'value': _product.gender,
      });
    if (_product.careInstructions.isNotEmpty)
      details.add({
        'icon':  Icons.dry_cleaning_rounded,
        'label': 'Care',
        'value': _product.careInstructions,
      });

    if (details.isEmpty) return const SizedBox.shrink();

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppPalette.primaryDark,
                      AppPalette.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppPalette.secondary,
                  size:  14,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Product Details',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize:   15,
                  color:      colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...details.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(
                      d['icon'] as IconData,
                      size:  16,
                      color: AppPalette.primary.withOpacity(0.70),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 90,
                      child: Text(
                        d['label'] as String,
                        style: GoogleFonts.poppins(
                          fontSize:   12,
                          color:      colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        d['value'] as String,
                        style: GoogleFonts.poppins(
                          fontSize:   12,
                          color:      colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Tailoring CTA ─────────────────────────────────────────────────────────

  Widget _buildTailoringCTA(AppThemeColors colors, bool isDark) {
    return Container(
      margin:  const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Dark luxury gradient for consultation card
        gradient: const LinearGradient(
          colors: [Color(0xFF111111), Color(0xFF2A2A2A)],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPalette.primary.withOpacity(0.30),
        ),
        boxShadow: [
          BoxShadow(
            color:      AppPalette.primary.withOpacity(0.10),
            blurRadius: 16,
            offset:     Offset.zero,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppPalette.primaryDark, AppPalette.primary],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.content_cut_rounded,
              color: AppPalette.secondary,
              size:  22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Custom Tailoring?',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize:   14,
                    color:      Colors.white,
                  ),
                ),
                Text(
                  'Get this item sewn to your measurements',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color:    Colors.white.withOpacity(0.65),
                    height:   1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '✂️ Tailoring Services — Coming Soon!',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color:      AppPalette.secondary,
                    ),
                  ),
                  backgroundColor: AppPalette.primary,
                  behavior:        SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
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
                'Book',
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
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String title, AppThemeColors colors) {
    return Row(
      children: [
        Container(
          width:  3,
          height: 16,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppPalette.primaryDark, AppPalette.primaryLight],
              begin:  Alignment.topCenter,
              end:    Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize:   15,
            color:      colors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ── Bottom Action Bar ─────────────────────────────────────────────────────

  Widget _buildBottomActionBar(
      AppThemeColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: AppPalette.primary.withOpacity(
              isDark ? 0.20 : 0.10,
            ),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:      colors.shadow,
            blurRadius: 20,
            offset:     const Offset(0, -6),
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Wishlist Button
            StreamBuilder<List<String>>(
              stream: _firebaseService.watchFavorites(),
              builder: (context, snapshot) {
                final favs  = snapshot.data ?? [];
                final isFav = favs.contains(_product.id);

                return GestureDetector(
                  onTap: () async {
                    if (_isGuest) {
                      await _promptLogin('save to wishlist');
                      return;
                    }
                    await _firebaseService
                        .toggleFavorite(_product.id);
                  },
                  child: Container(
                    width:  52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isFav
                          ? colors.error.withOpacity(0.10)
                          : colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isFav
                            ? colors.error.withOpacity(0.40)
                            : AppPalette.primary
                                .withOpacity(
                              isDark ? 0.25 : 0.15,
                            ),
                      ),
                    ),
                    child: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFav
                          ? colors.error
                          : AppPalette.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),

            // Add to Cart — Gold Button
            Expanded(
              child: SizedBox(
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: _product.inStock && !_addingToCart
                        ? const LinearGradient(
                            colors: [
                              AppPalette.primaryDark,
                              AppPalette.primary,
                              AppPalette.primaryLight,
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow:
                        _product.inStock && !_addingToCart
                            ? [
                                BoxShadow(
                                  color: AppPalette.primary
                                      .withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                  ),
                  child: ElevatedButton.icon(
                    onPressed:
                        _product.inStock && !_addingToCart
                            ? _addToCart
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _product.inStock
                          ? Colors.transparent
                          : colors.textSecondary,
                      shadowColor:     Colors.transparent,
                      foregroundColor: AppPalette.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: _addingToCart
                        ? SizedBox(
                            width:  18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color:       AppPalette.secondary,
                            ),
                          )
                        : const Icon(
                            Icons.shopping_bag_outlined,
                            size: 20,
                          ),
                    label: Text(
                      _addingToCart
                          ? 'Adding...'
                          : 'Add to Cart',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize:   15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Buy Now — Black Button (luxury contrast)
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _product.inStock
                      ? () async {
                          if (_isGuest) {
                            await _promptLogin(
                                'proceed to checkout');
                            return;
                          }
                          await _addToCart();
                          if (!mounted) return;
                          Navigator.of(context)
                              .pushNamed(RouteNames.cart);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppPalette.primary
                            .withOpacity(0.40),
                        width: 1,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Buy Now',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize:   15,
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
}