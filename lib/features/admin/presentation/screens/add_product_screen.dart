// lib/features/admin/presentation/screens/add_product_screen.dart
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pfb/features/products/data/product_repository.dart';
import 'package:pfb/models/product_model.dart';
import 'package:pfb/services/cloudinary_service.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/services/image_pick_service.dart';
import 'package:pfb/shared/widgets/app_form_field.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_section_title.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';
import 'package:pfb/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Textile-specific constants
// ─────────────────────────────────────────────────────────────────────────────

class _TextileData {
  static const fabricTypes = [
    'Ankara', 'Lace', 'Aso Oke', 'Chiffon', 'Cotton',
    'Silk', 'Linen', 'Adire', 'George', 'Velvet',
    'Atiku', 'Organza', 'Satin', 'Wool', 'Denim',
    'Net', 'Sequence', 'Swiss Voile', 'Broderie',
  ];

  static const occasions = [
    'Wedding', 'Sallah', 'Christmas', 'Birthday',
    'Naming Ceremony', 'Burial', 'Corporate', 'Casual',
    'Party', 'Traditional', 'Graduation',
  ];

  static const genders = ['Men', 'Women', 'Children', 'Unisex'];

  static const standardSizes = [
    'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL',
    '1 yard', '2 yards', '3 yards', '4 yards',
    '5 yards', '6 yards', '8 yards', '10 yards',
  ];

  static const commonColors = [
    'Red', 'Blue', 'Green', 'Yellow', 'Black', 'White',
    'Navy', 'Maroon', 'Gold', 'Silver', 'Purple',
    'Orange', 'Pink', 'Brown', 'Cream', 'Grey',
    'Multi-color', 'Royal Blue', 'Wine', 'Olive',
  ];

  static const origins = [
    'Nigeria', 'Ghana', 'Senegal', 'India', 'China',
    'Holland', 'UAE', 'UK', 'Italy', 'France',
  ];

  static const careInstructions = [
    'Hand wash only',
    'Dry clean only',
    'Machine washable',
    'Do not bleach',
    'Iron on low heat',
    'Store in cool dry place',
    'Wash separately first time',
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// AddProductScreen
// ─────────────────────────────────────────────────────────────────────────────

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen>
    with SingleTickerProviderStateMixin {
  final _repo = ProductRepository();
  final _cloudinaryService = CloudinaryService();
  final _imageService = ImagePickService();
  final _firebaseService = FirebaseService();

  final _formKey = GlobalKey<FormState>();

  // ── Core Fields ────────────────────────────────────────────────
  final _nameCtrl        = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _priceCtrl       = TextEditingController();
  final _stockQtyCtrl    = TextEditingController(text: '0');
  final _variantsCtrl    = TextEditingController();
  final _promoTextCtrl   = TextEditingController();
  final _promoDiscountCtrl = TextEditingController(text: '0');

  // ── Textile Fields ─────────────────────────────────────────────
  final _materialCtrl = TextEditingController();
  final _gsmCtrl      = TextEditingController();
  final _yardageCtrl  = TextEditingController(text: '0');
  final _careCtrl     = TextEditingController();

  String _selectedFabricType = '';
  String _selectedOccasion   = '';
  String _selectedGender     = 'Unisex';
  String _selectedOrigin     = 'Nigeria';

  List<String> _selectedColors = [];
  List<String> _selectedSizes  = [];

  // ── Images ─────────────────────────────────────────────────────
  File? _primaryImage;
  final List<File> _additionalImages = [];

  // ── Toggles ────────────────────────────────────────────────────
  bool _featured      = false;
  bool _isTrending    = false;
  bool _inStock       = true;
  bool _isNewArrival  = false;
  bool _isBestSeller  = false;

  // ── State ──────────────────────────────────────────────────────
  bool _loading      = false;
  int  _currentStep  = 0;

  List<String> _selectedCategories = ['General'];

  final List<String> _steps = [
    'Basic Info',
    'Product Details',
    'Colors & Sizes',
    'Images',
    'Flags & Pricing',
  ];

  // ── Image Picker ──────────────────────────────────────────────

  Future<void> _pickPrimaryImage() async {
    final file = await _imageService.pickImageWithFallback();
    if (file == null) return;
    if (await _exceedsMaxSize(file)) return;
    setState(() => _primaryImage = file);
  }

  Future<void> _pickAdditionalImage() async {
    if (_additionalImages.length >= 4) {
      _showSnack('Maximum 4 additional images allowed.');
      return;
    }
    final file = await _imageService.pickImageWithFallback();
    if (file == null) return;
    if (await _exceedsMaxSize(file)) return;
    setState(() => _additionalImages.add(file));
  }

  Future<bool> _exceedsMaxSize(File file) async {
    final bytes = await file.length();
    if (bytes > 3 * 1024 * 1024) {
      _showSnack('Image too large. Max 3MB per image.');
      return true;
    }
    return false;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ── Category Toggle ───────────────────────────────────────────

  void _toggleCategory(String category, bool selected) {
    setState(() {
      if (selected) {
        if (!_selectedCategories.contains(category)) {
          _selectedCategories.add(category);
        }
      } else {
        _selectedCategories.remove(category);
      }
      if (_selectedCategories.isEmpty) {
        _selectedCategories = ['General'];
      }
    });
  }

  // ── Submit ────────────────────────────────────────────────────

  Future<void> _submit() async {
    final name        = _nameCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final price       = double.tryParse(_priceCtrl.text.trim());
    final stockQty    = int.tryParse(_stockQtyCtrl.text.trim()) ?? 0;
    final promoDiscount =
        double.tryParse(_promoDiscountCtrl.text.trim()) ?? 0;
    final yardage = double.tryParse(_yardageCtrl.text.trim()) ?? 0;
    final variants = _variantsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (name.isEmpty ||
        description.isEmpty ||
        price == null ||
        _primaryImage == null) {
      _showSnack(
          'Please complete all required fields and add a primary image.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final categories = _selectedCategories.toSet().toList();

    if (_featured      && !categories.contains('Featured'))     categories.add('Featured');
    if (_isTrending    && !categories.contains('Trending'))     categories.add('Trending');
    if (_isNewArrival  && !categories.contains('New Arrivals')) categories.add('New Arrivals');
    if (_isBestSeller  && !categories.contains('Best Sellers')) categories.add('Best Sellers');
    if (_selectedFabricType.isNotEmpty &&
        !categories.contains(_selectedFabricType))              categories.add(_selectedFabricType);
    if (_selectedOccasion.isNotEmpty &&
        !categories.contains(_selectedOccasion))                categories.add(_selectedOccasion);

    setState(() => _loading = true);

    try {
      final imageUrl = await _cloudinaryService.uploadImage(_primaryImage!);

      final additionalUrls = <String>[];
      for (final img in _additionalImages) {
        additionalUrls.add(await _cloudinaryService.uploadImage(img));
      }

      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final product = ProductModel(
        id:                   id,
        name:                 name,
        description:          description,
        price:                price,
        imageUrl:             imageUrl,
        additionalImages:     additionalUrls,
        createdBy:            user.uid,
        createdAt:            DateTime.now(),
        category:             categories.isEmpty ? 'General' : categories.first,
        categories:           categories,
        featured:             _featured,
        isTrending:           _isTrending,
        inStock:              _inStock,
        stockQuantity:        stockQty,
        variants:             variants,
        promoText:            _promoTextCtrl.text.trim(),
        promoDiscountPercent: promoDiscount,
        fabricType:           _selectedFabricType,
        material:             _materialCtrl.text.trim(),
        availableColors:      _selectedColors,
        availableSizes:       _selectedSizes,
        yardage:              yardage,
        gsm:                  _gsmCtrl.text.trim(),
        careInstructions:     _careCtrl.text.trim(),
        occasion:             _selectedOccasion,
        gender:               _selectedGender,
        origin:               _selectedOrigin,
        isNewArrival:         _isNewArrival,
        isBestSeller:         _isBestSeller,
      );

      await _repo.addProduct(product);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                '${product.name} created successfully!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: context.appColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to add product: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockQtyCtrl.dispose();
    _variantsCtrl.dispose();
    _promoTextCtrl.dispose();
    _promoDiscountCtrl.dispose();
    _materialCtrl.dispose();
    _gsmCtrl.dispose();
    _yardageCtrl.dispose();
    _careCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppPageScaffold(
      title: 'Add Product',
      body: Column(
        children: [
          _buildStepIndicator(colors),
          Expanded(
            child: Form(
              key: _formKey,
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _buildStep0BasicInfo(colors),
                  _buildStep1FabricDetails(colors),
                  _buildStep2ColorsSizes(colors),
                  _buildStep3Images(colors),
                  _buildStep4Flags(colors),
                ],
              ),
            ),
          ),
          _buildStepNavigation(colors),
        ],
      ),
    );
  }

  // ── STEP INDICATOR ────────────────────────────────────────────

  Widget _buildStepIndicator(dynamic colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: List.generate(_steps.length, (i) {
              final isActive = i <= _currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: i < _steps.length - 1 ? 4 : 0,
                  ),
                  decoration: BoxDecoration(
                    // ── Gold progress bar ──────────────────────────
                    color: isActive
                        ? colors.brandPrimary
                        : colors.borderSoft,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of ${_steps.length}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _steps[_currentStep],
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: colors.brandPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── STEP 0 — Basic Info ───────────────────────────────────────

  Widget _buildStep0BasicInfo(dynamic colors) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StepCard(
          title: 'Product Information',
          icon: Icons.inventory_2_rounded,
          colors: colors,
          children: [
            AppFormField(controller: _nameCtrl, hintText: 'Product name *'),
            const SizedBox(height: 12),
            AppFormField(
                controller: _descCtrl,
                hintText: 'Description *',
                maxLines: 4),
            const SizedBox(height: 12),
            AppFormField(
              controller: _priceCtrl,
              hintText: 'Price (₦) *',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            AppFormField(
              controller: _stockQtyCtrl,
              hintText: 'Stock quantity',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _StepCard(
          title: 'Categories',
          icon: Icons.category_rounded,
          colors: colors,
          children: [
            Text(
              'Select all applicable categories',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<String>>(
              stream: _firebaseService.watchCategories(),
              builder: (context, snapshot) {
                final dbCategories =
                    snapshot.data ?? const ['General'];
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: dbCategories.map((cat) {
                    final selected =
                        _selectedCategories.contains(cat);
                    return FilterChip(
                      label: Text(cat),
                      selected: selected,
                      onSelected: (v) => _toggleCategory(cat, v),
                      // ── Gold selected, black text on gold ────────
                      selectedColor: colors.brandPrimary,
                      backgroundColor: colors.surfaceAlt,
                      checkmarkColor: AppPalette.secondary,
                      labelStyle: GoogleFonts.poppins(
                        color: selected
                            ? AppPalette.secondary
                            : colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: selected
                            ? colors.brandPrimary
                            : colors.borderSoft,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // ── STEP 1 — Product Details ───────────────────────────────────

  Widget _buildStep1FabricDetails(dynamic colors) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StepCard(
          title: 'Product Type',
          icon: Icons.style_rounded,
          colors: colors,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _TextileData.fabricTypes.map((f) {
                final selected = _selectedFabricType == f;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedFabricType = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? colors.brandPrimary
                          : colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? colors.brandPrimary
                            : colors.borderSoft,
                      ),
                    ),
                    child: Text(
                      f,
                      style: GoogleFonts.poppins(
                        // ── Black text on gold chip ──────────────
                        color: selected
                            ? AppPalette.secondary
                            : colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _StepCard(
          title: 'Material & Specs',
          icon: Icons.texture_rounded,
          colors: colors,
          children: [
            AppFormField(
              controller: _materialCtrl,
              hintText: '100% Cotton, Polyester blend...',
            ),
            const SizedBox(height: 12),
            AppFormField(
              controller: _gsmCtrl,
              hintText: 'GSM / Weight (e.g. 180gsm)',
            ),
            const SizedBox(height: 12),
            AppFormField(
              controller: _yardageCtrl,
              hintText: 'Yardage (e.g. 6)',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            AppFormField(
              controller: _careCtrl,
              hintText: 'Care instructions',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _StepCard(
          title: 'Classification',
          icon: Icons.tune_rounded,
          colors: colors,
          children: [
            _DropdownField(
              label: 'Occasion',
              value: _selectedOccasion.isEmpty ? null : _selectedOccasion,
              items: _TextileData.occasions,
              hint: 'Select occasion',
              colors: colors,
              onChanged: (v) =>
                  setState(() => _selectedOccasion = v ?? ''),
            ),
            const SizedBox(height: 12),
            _DropdownField(
              label: 'Gender',
              value: _selectedGender,
              items: _TextileData.genders,
              hint: 'Select gender',
              colors: colors,
              onChanged: (v) =>
                  setState(() => _selectedGender = v ?? 'Unisex'),
            ),
            const SizedBox(height: 12),
            _DropdownField(
              label: 'Origin / Country',
              value: _selectedOrigin,
              items: _TextileData.origins,
              hint: 'Select origin',
              colors: colors,
              onChanged: (v) =>
                  setState(() => _selectedOrigin = v ?? 'Nigeria'),
            ),
          ],
        ),
      ],
    );
  }

  // ── STEP 2 — Colors & Sizes ───────────────────────────────────

  Widget _buildStep2ColorsSizes(dynamic colors) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StepCard(
          title: 'Available Colors',
          icon: Icons.palette_rounded,
          colors: colors,
          children: [
            Text(
              'Select all available colors for this item',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _TextileData.commonColors.map((color) {
                final selected = _selectedColors.contains(color);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedColors.remove(color);
                      } else {
                        _selectedColors.add(color);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? colors.brandPrimary
                          : colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? colors.brandPrimary
                            : colors.borderSoft,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.check_rounded,
                              size: 12,
                              // ── Black checkmark on gold ──────────
                              color: AppPalette.secondary,
                            ),
                          ),
                        Text(
                          color,
                          style: GoogleFonts.poppins(
                            // ── Black text on gold chip ──────────
                            color: selected
                                ? AppPalette.secondary
                                : colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_selectedColors.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Selected: ${_selectedColors.join(', ')}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: colors.brandPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 14),

        _StepCard(
          title: 'Available Sizes / Yardage',
          icon: Icons.straighten_rounded,
          colors: colors,
          children: [
            Text(
              'Select all available sizes for this product',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _TextileData.standardSizes.map((size) {
                final selected = _selectedSizes.contains(size);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedSizes.remove(size);
                      } else {
                        _selectedSizes.add(size);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 72,
                    height: 42,
                    decoration: BoxDecoration(
                      color: selected
                          ? colors.brandPrimary
                          : colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? colors.brandPrimary
                            : colors.borderSoft,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        size,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          // ── Black text on gold size box ──────────
                          color: selected
                              ? AppPalette.secondary
                              : colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            AppFormField(
              controller: _variantsCtrl,
              hintText: 'Other variants (comma separated)',
            ),
          ],
        ),
      ],
    );
  }

  // ── STEP 3 — Images ───────────────────────────────────────────

  Widget _buildStep3Images(dynamic colors) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StepCard(
          title: 'Primary Image *',
          icon: Icons.image_rounded,
          colors: colors,
          children: [
            GestureDetector(
              onTap: _pickPrimaryImage,
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _primaryImage != null
                        ? colors.success
                        : colors.borderSoft,
                    width: _primaryImage != null ? 2 : 1,
                  ),
                ),
                child: _primaryImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: colors.textSecondary,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to add primary image',
                            style: GoogleFonts.poppins(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Max 3MB · JPG or PNG',
                            style: GoogleFonts.poppins(
                              color: colors.textSecondary
                                  .withOpacity(0.65),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_primaryImage!, fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _primaryImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: colors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.success,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Primary Image Set',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        _StepCard(
          title:
              'Additional Images (${_additionalImages.length}/4)',
          icon: Icons.photo_library_rounded,
          colors: colors,
          children: [
            Text(
              'Add up to 4 more photos showing different angles, patterns, or uses',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ..._additionalImages.asMap().entries.map((e) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          e.value,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(
                              () => _additionalImages.removeAt(e.key)),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colors.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                if (_additionalImages.length < 4)
                  GestureDetector(
                    onTap: _pickAdditionalImage,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: colors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.borderSoft,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: colors.textSecondary,
                        size: 32,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ── STEP 4 — Flags & Pricing ──────────────────────────────────

  Widget _buildStep4Flags(dynamic colors) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StepCard(
          title: 'Product Flags',
          icon: Icons.flag_rounded,
          colors: colors,
          children: [
            _ToggleTile(
              label: 'Featured Product',
              subtitle: 'Show in Featured Collection',
              icon: Icons.star_rounded,
              value: _featured,
              onChanged: (v) => setState(() => _featured = v),
              colors: colors,
            ),
            _ToggleTile(
              label: 'Trending',
              subtitle: 'Show in Trending Now section',
              icon: Icons.local_fire_department_rounded,
              value: _isTrending,
              onChanged: (v) => setState(() => _isTrending = v),
              colors: colors,
            ),
            _ToggleTile(
              label: 'New Arrival',
              subtitle: 'Show in New Arrivals section',
              icon: Icons.fiber_new_rounded,
              value: _isNewArrival,
              onChanged: (v) => setState(() => _isNewArrival = v),
              colors: colors,
            ),
            _ToggleTile(
              label: 'Best Seller',
              subtitle: 'Show in Best Sellers section',
              icon: Icons.workspace_premium_rounded,
              value: _isBestSeller,
              onChanged: (v) => setState(() => _isBestSeller = v),
              colors: colors,
            ),
            _ToggleTile(
              label: 'In Stock',
              subtitle: 'Product is available to buy',
              icon: Icons.inventory_rounded,
              value: _inStock,
              onChanged: (v) => setState(() => _inStock = v),
              colors: colors,
            ),
          ],
        ),

        const SizedBox(height: 14),

        _StepCard(
          title: 'Promo & Discount',
          icon: Icons.local_offer_rounded,
          colors: colors,
          children: [
            AppFormField(
              controller: _promoTextCtrl,
              hintText: 'Promo text (e.g. 20% off this week)',
            ),
            const SizedBox(height: 12),
            AppFormField(
              controller: _promoDiscountCtrl,
              hintText:
                  'Discount percentage (0 = no discount)',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            if (double.tryParse(_promoDiscountCtrl.text.trim()) !=
                    null &&
                double.tryParse(_promoDiscountCtrl.text.trim())! > 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.paleGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_rounded,
                        size: 16,
                        color: Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Product will show '
                        '${_promoDiscountCtrl.text.trim()}% OFF badge',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ── STEP NAVIGATION ───────────────────────────────────────────

  Widget _buildStepNavigation(dynamic colors) {
    final isLastStep = _currentStep == _steps.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _currentStep--),
                  icon: const Icon(
                      Icons.arrow_back_rounded, size: 18),
                  label: Text(
                    'Back',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: _loading
                    ? null
                    : () {
                        if (isLastStep) {
                          _submit();
                        } else {
                          setState(() => _currentStep++);
                        }
                      },
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          // ── Keep white on dark spinner ───────────
                          color: AppPalette.secondary,
                        ),
                      )
                    : Icon(
                        isLastStep
                            ? Icons.cloud_upload_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                label: Text(
                  _loading
                      ? 'Uploading...'
                      : (isLastStep
                          ? 'Publish Product'
                          : 'Next Step'),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
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

// ═══════════════════════════════════════════════════════════════════════════════
// Helper widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _StepCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final dynamic colors;
  final List<Widget> children;

  const _StepCard({
    required this.title,
    required this.icon,
    required this.colors,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.brandPrimary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: colors.brandPrimary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final String hint;
  final dynamic colors;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.hint,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                hint,
                style: GoogleFonts.poppins(
                  color: colors.textSecondary,
                  fontSize: 13,
                ),
              ),
              isExpanded: true,
              dropdownColor: colors.surface,
              style: GoogleFonts.poppins(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final dynamic colors;

  const _ToggleTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: value
            ? colors.brandPrimary.withOpacity(0.08)
            : colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? colors.brandPrimary.withOpacity(0.30)
              : colors.borderSoft,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value
                ? colors.brandPrimary
                : colors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            // ── Switch uses theme (gold track, black thumb) ──
            activeColor: AppPalette.secondary,
            activeTrackColor: colors.brandPrimary,
          ),
        ],
      ),
    );
  }
}