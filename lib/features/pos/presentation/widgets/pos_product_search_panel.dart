// lib/features/pos/presentation/widgets/pos_product_search_panel.dart
import 'package:flutter/material.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/models/product_model.dart';

class PosProductSearchPanel extends StatefulWidget {
  final List<ProductModel> products;
  final String searchQuery;
  final void Function(String query) onSearchChanged;
  final void Function(ProductModel product) onProductTapped;

  const PosProductSearchPanel({
    super.key,
    required this.products,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onProductTapped,
  });

  @override
  State<PosProductSearchPanel> createState() =>
      _PosProductSearchPanelState();
}

class _PosProductSearchPanelState
    extends State<PosProductSearchPanel> {
  final TextEditingController _searchCtrl =
      TextEditingController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.searchQuery;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ProductModel> get _displayedProducts {
    if (_selectedCategory == null ||
        _selectedCategory == 'All') {
      return widget.products;
    }
    return widget.products
        .where((p) => p.category == _selectedCategory)
        .toList();
  }

  List<String> get _categories {
    final cats = widget.products
        .map((p) => p.category)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...cats];
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Column(
      children: [
        // ── Search Bar ────────────────────────────
        Padding(
          padding:
              const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: widget.onSearchChanged,
            decoration: InputDecoration(
              hintText:
                  'Search products by name, category...',
              prefixIcon: Icon(Icons.search_rounded,
                  color: colors.textSecondary),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded,
                          color: colors.textSecondary),
                      onPressed: () {
                        _searchCtrl.clear();
                        widget.onSearchChanged('');
                      },
                    )
                  : null,
            ),
          ),
        ),

        // ── Category Filter Chips ─────────────────
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final isSelected =
                  _selectedCategory == cat ||
                      (_selectedCategory == null &&
                          cat == 'All');
              return GestureDetector(
                onTap: () => setState(
                    () => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.brandPrimary
                        : colors.surfaceAlt,
                    borderRadius:
                        BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected
                          ? colors.brandPrimary
                          : colors.border,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : colors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // ── Products Grid ─────────────────────────
        Expanded(
          child: _displayedProducts.isEmpty
              ? _buildEmptyState(colors)
              : _buildProductGrid(),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              color: colors.textSecondary, size: 48),
          const SizedBox(height: 12),
          Text(
            'No products found',
            style: TextStyle(
                color: colors.textSecondary,
                fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return GridView.builder(
      padding:
          const EdgeInsets.fromLTRB(16, 0, 16, 80),
      gridDelegate:
          const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _displayedProducts.length,
      itemBuilder: (_, i) => _PosProductCard(
        product: _displayedProducts[i],
        onTap: () =>
            widget.onProductTapped(_displayedProducts[i]),
      ),
    );
  }
}

// ── Product Card ───────────────────────────────────────────────────────────────

class _PosProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _PosProductCard({
    required this.product,
    required this.onTap,
  });

  bool get _isOutOfStock => product.stockQuantity <= 0;

  bool get _hasValidImage {
    final url = product.imageUrl.trim();
    return url.isNotEmpty &&
        (url.startsWith('http://') ||
            url.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return GestureDetector(
      onTap: _isOutOfStock ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderSoft),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product Image ──────────────────────
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image or placeholder
                    _hasValidImage
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context,
                                child, progress) {
                              if (progress == null) {
                                return child;
                              }
                              return Container(
                                color: colors.surfaceAlt,
                                child: Center(
                                  child:
                                      CircularProgressIndicator(
                                    color:
                                        colors.brandPrimary,
                                    strokeWidth: 2,
                                    value: progress
                                                .expectedTotalBytes !=
                                            null
                                        ? progress
                                                .cumulativeBytesLoaded /
                                            progress
                                                .expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder:
                                (_, __, ___) =>
                                    _buildImageFallback(
                                        colors),
                          )
                        : _buildImageFallback(colors),

                    // Out of stock overlay
                    if (_isOutOfStock)
                      Container(
                        color: Colors.black54,
                        alignment: Alignment.center,
                        child: const Text(
                          'OUT OF\nSTOCK',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),

                    // Add button (available products)
                    if (!_isOutOfStock)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: AppPalette.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.black,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Product Info ───────────────────────
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₦${product.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: colors.brandPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Qty: ${product.stockQuantity}',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 10,
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

  Widget _buildImageFallback(AppThemeColors colors) {
    return Container(
      color: colors.goldTint,
      child: Center(
        child: Icon(
          Icons.texture_rounded,
          color: colors.brandPrimary,
          size: 32,
        ),
      ),
    );
  }
}