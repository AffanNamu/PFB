// lib/features/cart/presentation/screens/cart_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/features/auth/presentation/screens/login_screen.dart';
import 'package:pfb/features/cart/presentation/screens/paystack_verification_screen.dart';
import 'package:pfb/models/payment_session_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/services/payment_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Sakash Collection Cart Screen — Checkout Experience
// ═══════════════════════════════════════════════════════════════════════════════

class CartScreen extends StatefulWidget {
  final bool showScaffold;

  const CartScreen({super.key, this.showScaffold = true});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final PaymentService _paymentService   = PaymentService();

  bool _processingCheckout = false;
  bool _loadingDeliveryFee = false;
  String? _deliveryFeeError;
  double? _deliveryFeeAmount;
  String _lastEstimatedAddress = '';

  // ── Coupon ────────────────────────────────────────────────────────────────
  final _couponCtrl    = TextEditingController();
  bool   _couponApplied  = false;
  double _couponDiscount = 0;
  String? _couponError;
  bool   _checkingCoupon = false;

  // ── Payment method ────────────────────────────────────────────────────────
  String _selectedPayment = 'Paystack';

  // ── Animation ─────────────────────────────────────────────────────────────
  late AnimationController _summaryAnimCtrl;
  late Animation<double>   _summaryAnim;

  bool get _isGuest =>
      FirebaseAuth.instance.currentUser == null;

  bool _hasValidImage(String url) {
    final v = url.trim();
    return v.isNotEmpty &&
        (v.startsWith('http://') || v.startsWith('https://'));
  }

  @override
  void initState() {
    super.initState();
    _summaryAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _summaryAnim = CurvedAnimation(
      parent: _summaryAnimCtrl,
      curve: Curves.easeOut,
    );
    _summaryAnimCtrl.forward();
  }

  @override
  void dispose() {
    _couponCtrl.dispose();
    _summaryAnimCtrl.dispose();
    super.dispose();
  }

  // ── Go to Login ───────────────────────────────────────────────────────────

  Future<void> _goToLogin() async {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(
          redirectTo: RouteNames.redirectCart,
        ),
      ),
    );
  }

  // ── Guest Prompt ──────────────────────────────────────────────────────────

  Future<void> _showGuestPrompt(String action) async {
    final go = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final c = AppTheme.colorsOf(ctx);
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: c.brandPrimary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: c.brandPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sign In Required',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                // ── Brand name updated ───────────────────────────
                'Please sign in or create a Sakash Collection account to $action.',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Later',
                    style: GoogleFonts.poppins(
                        color: c.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    'Sign In',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!go) return;
    await _goToLogin();
  }

  // ── Estimate Delivery Fee ─────────────────────────────────────────────────

  Future<void> _estimateDeliveryFee(
    String selectedAddress,
    double itemsTotal,
  ) async {
    if (_isGuest) {
      await _showGuestPrompt('estimate delivery');
      return;
    }

    if (selectedAddress.trim().isEmpty) {
      setState(() {
        _deliveryFeeAmount = null;
        _deliveryFeeError =
            'Please select a delivery address in your Profile first';
      });
      return;
    }

    setState(() {
      _loadingDeliveryFee = true;
      _deliveryFeeError   = null;
    });

    try {
      const freeThreshold = 25000.0;
      const baseFee       = 1500.0;
      final fee = itemsTotal >= freeThreshold ? 0.0 : baseFee;

      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;
      setState(() {
        _deliveryFeeAmount    = fee;
        _lastEstimatedAddress = selectedAddress;
      });

      _summaryAnimCtrl
        ..reset()
        ..forward();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deliveryFeeAmount = null;
        _deliveryFeeError =
            'Could not estimate delivery. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _loadingDeliveryFee = false);
    }
  }

  // ── Apply Coupon ──────────────────────────────────────────────────────────

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _checkingCoupon = true;
      _couponError    = null;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    // ── Updated coupon codes to Sakash Collection brand ────────────
    if (code == 'PF10') {
      setState(() {
        _couponApplied  = true;
        _couponDiscount = 0.10;
        _couponError    = null;
      });
    } else if (code == 'ANKARA20') {
      setState(() {
        _couponApplied  = true;
        _couponDiscount = 0.20;
        _couponError    = null;
      });
    } else {
      setState(() {
        _couponApplied  = false;
        _couponDiscount = 0;
        // ── Hint updated to PF10 ─────────────────────────────────
        _couponError =
            'Invalid coupon code. Try PF10 or ANKARA20.';
      });
    }

    if (mounted) setState(() => _checkingCoupon = false);
  }

  void _removeCoupon() {
    setState(() {
      _couponApplied  = false;
      _couponDiscount = 0;
      _couponError    = null;
      _couponCtrl.clear();
    });
  }

  // ── Checkout ──────────────────────────────────────────────────────────────

  Future<void> _checkout(
    List<Map<String, dynamic>> cartItems,
    double grandTotal,
    double itemsTotal,
    double deliveryFee,
    double couponSaving,
  ) async {
    if (_isGuest) {
      await _showGuestPrompt(
          'complete checkout and track your delivery');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || (user.email ?? '').trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'A valid signed-in email is required for payment.',
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    if (_deliveryFeeAmount == null) {
      if (!mounted) return;
      final colors = AppTheme.colorsOf(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Please estimate delivery fee first.',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: colors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _processingCheckout = true);

    try {
      final result = await _paymentService.initializeCheckout(
        userUid: user.uid,
        email:   user.email!,
        amountNaira: grandTotal,
        items:       cartItems,
        metadata: {
          'type':           'cart_checkout',
          // ── Brand name updated ───────────────────────────────
          'platform':       'Sakash Collection',
          'userId':         user.uid,
          'itemsCount':     cartItems.length,
          'itemsTotal':     itemsTotal,
          'deliveryFee':    deliveryFee,
          'couponDiscount': couponSaving,
          'grandTotal':     grandTotal,
          'couponCode':
              _couponApplied ? _couponCtrl.text.trim() : '',
        },
      );

      if (!result.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
        return;
      }

      final opened = await _paymentService
          .openCheckoutUrl(result.authorizationUrl);

      if (!opened) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Unable to open Paystack checkout')),
        );
        return;
      }

      if (!mounted) return;

      final session = PaymentSessionModel(
        reference:   result.reference,
        userUid:     user.uid,
        email:       user.email!,
        amountNaira: grandTotal,
        currency:    'NGN',
        items:       cartItems,
        metadata: {
          'type':           'cart_checkout',
          // ── Brand name updated ───────────────────────────────
          'platform':       'Sakash Collection',
          'userId':         user.uid,
          'itemsCount':     cartItems.length,
          'itemsTotal':     itemsTotal,
          'deliveryFee':    deliveryFee,
          'couponDiscount': couponSaving,
          'grandTotal':     grandTotal,
        },
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              PaystackVerificationScreen(session: session),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _processingCheckout = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    final content =
        StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseService.watchCart(),
      builder: (context, snapshot) {
        final cartItems = snapshot.data ?? [];

        final itemsTotal = cartItems.fold<double>(
          0,
          (sum, item) =>
              sum +
              (((item['price'] ?? 0) as num).toDouble() *
                  ((item['qty'] ?? 1) as int)),
        );

        if (cartItems.isEmpty) {
          return _buildEmptyCart(colors);
        }

        return StreamBuilder<String>(
          stream: _firebaseService.watchSelectedAddress(),
          builder: (context, addressSnapshot) {
            final selectedAddress =
                addressSnapshot.data ?? '';

            if (_lastEstimatedAddress != selectedAddress &&
                _deliveryFeeAmount != null) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _deliveryFeeAmount = null;
                  _deliveryFeeError  = null;
                });
              });
            }

            final deliveryFee   = _deliveryFeeAmount ?? 0;
            final couponSaving  = _couponApplied
                ? (itemsTotal * _couponDiscount)
                : 0.0;
            final grandTotal =
                itemsTotal + deliveryFee - couponSaving;

            return CustomScrollView(
              slivers: [
                if (_isGuest)
                  SliverToBoxAdapter(
                      child: _buildGuestBanner(colors)),

                SliverToBoxAdapter(
                  child: _buildCartHeader(
                      colors, cartItems.length),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      16, 0, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) =>
                          _buildCartItem(colors, cartItems[i]),
                      childCount: cartItems.length,
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: _buildDeliverToCard(
                    colors,
                    selectedAddress,
                    itemsTotal,
                  ),
                ),

                SliverToBoxAdapter(
                    child: _buildCouponSection(colors)),

                SliverToBoxAdapter(
                    child:
                        _buildPaymentMethodSection(colors)),

                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _summaryAnim,
                    child: _buildOrderSummary(
                      colors:          colors,
                      cartItems:       cartItems,
                      selectedAddress: selectedAddress,
                      itemsTotal:      itemsTotal,
                      deliveryFee:     deliveryFee,
                      couponSaving:    couponSaving,
                      grandTotal:      grandTotal,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                    child: SizedBox(height: 32)),
              ],
            );
          },
        );
      },
    );

    if (!widget.showScaffold) {
      return Scaffold(
        backgroundColor: colors.scaffold,
        body: SafeArea(child: content),
      );
    }

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: _buildAppBar(colors),
      body: content,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════

  // ── App Bar ───────────────────────────────────────────────────────────────

  AppBar _buildAppBar(dynamic colors) {
    return AppBar(
      backgroundColor: colors.scaffold,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.brandPrimary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.shopping_bag_rounded,
              color: colors.brandPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'My Cart',
            style: GoogleFonts.poppins(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firebaseService.watchCart(),
          builder: (context, snap) {
            final count = snap.data?.length ?? 0;
            if (count == 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        colors.brandPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count item${count == 1 ? '' : 's'}',
                    style: GoogleFonts.poppins(
                      color: colors.brandPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Empty Cart ────────────────────────────────────────────────────────────

  Widget _buildEmptyCart(dynamic colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colors.brandPrimary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 56,
                color: colors.brandPrimary.withOpacity(0.45),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              // ── Brand name updated ───────────────────────────
              'Discover premium Ankara, Lace, Aso Oke\nand more from Sakash Collection.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.style_rounded),
                label: Text(
                  'Browse Products',
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

  // ── Guest Banner ──────────────────────────────────────────────────────────

  Widget _buildGuestBanner(dynamic colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.brandPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colors.brandPrimary.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.brandPrimary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: colors.brown,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Shopping as guest. Sign in to checkout, save addresses & track your delivery.',
              style: GoogleFonts.poppins(
                color: colors.brown,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _goToLogin,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              backgroundColor:
                  colors.brandPrimary.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Sign In',
              style: GoogleFonts.poppins(
                color: colors.brandPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cart Header ───────────────────────────────────────────────────────────

  Widget _buildCartHeader(dynamic colors, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: colors.brandPrimary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$count item${count == 1 ? '' : 's'} in cart',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) {
                  final c = AppTheme.colorsOf(ctx);
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      'Clear Cart?',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    content: Text(
                      'Remove all items from your cart?',
                      style: GoogleFonts.poppins(
                          color: c.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(ctx, false),
                        child: Text('Cancel',
                            style: GoogleFonts.poppins()),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: c.error),
                        child: Text(
                          'Clear All',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  );
                },
              );
              if (confirm == true) {
                await _firebaseService.clearCart();
              }
            },
            icon: Icon(Icons.delete_sweep_rounded,
                size: 16, color: colors.error),
            label: Text(
              'Clear All',
              style: GoogleFonts.poppins(
                color: colors.error,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cart Item ─────────────────────────────────────────────────────────────

  Widget _buildCartItem(
      dynamic colors, Map<String, dynamic> item) {
    final qty      = (item['qty'] ?? 1) as int;
    final imageUrl = (item['imageUrl'] ?? '').toString();
    final itemTotal =
        ((item['price'] ?? 0) as num).toDouble() * qty;
    final fabricType =
        (item['fabricType'] ?? '').toString().trim();
    final selectedColor =
        (item['selectedColor'] ?? item['color'] ?? '')
            .toString()
            .trim();
    final selectedSize =
        (item['selectedSize'] ?? item['size'] ?? '')
            .toString()
            .trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Product image ────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 72,
              height: 72,
              child: _hasValidImage(imageUrl)
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _imagePlaceholder(colors),
                    )
                  : _imagePlaceholder(colors),
            ),
          ),
          const SizedBox(width: 12),

          // ── Product info ─────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (item['name'] ?? '').toString(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontSize: 13.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (fabricType.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.style_rounded,
                          size: 12,
                          color: colors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        fabricType,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                if (selectedColor.isNotEmpty ||
                    selectedSize.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 6,
                      children: [
                        if (selectedColor.isNotEmpty)
                          _MiniTag(
                              label: selectedColor,
                              colors: colors),
                        if (selectedSize.isNotEmpty)
                          _MiniTag(
                              label: selectedSize,
                              colors: colors),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  '₦${((item['price'] ?? 0) as num).toDouble().toStringAsFixed(0)} each',
                  style: GoogleFonts.poppins(
                    color: colors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Subtotal: ₦${itemTotal.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    color: colors.brandPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Qty controls + remove ────────────────────────────
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderSoft),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QtyButton(
                      icon: Icons.remove_rounded,
                      color: qty <= 1
                          ? colors.textSecondary
                          : colors.brandPrimary,
                      onTap: () async {
                        await _firebaseService.updateCartQty(
                          productId:
                              item['productId'].toString(),
                          qty: qty - 1,
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10),
                      child: Text(
                        '$qty',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _QtyButton(
                      icon: Icons.add_rounded,
                      color: colors.brandPrimary,
                      onTap: () async {
                        await _firebaseService.updateCartQty(
                          productId:
                              item['productId'].toString(),
                          qty: qty + 1,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  await _firebaseService.updateCartQty(
                    productId: item['productId'].toString(),
                    qty: 0,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.error.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: colors.error,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(dynamic colors) {
    return Container(
      color: colors.brandPrimary.withOpacity(0.10),
      child: Center(
        child: Icon(
          Icons.style_rounded,
          color: colors.brandPrimary.withOpacity(0.50),
          size: 28,
        ),
      ),
    );
  }

  // ── Deliver To Card ───────────────────────────────────────────────────────

  Widget _buildDeliverToCard(
    dynamic colors,
    String selectedAddress,
    double itemsTotal,
  ) {
    final hasAddress =
        !_isGuest && selectedAddress.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasAddress
              ? colors.brandPrimary.withOpacity(0.25)
              : colors.error.withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (hasAddress
                          ? colors.brandPrimary
                          : colors.error)
                      .withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: hasAddress
                      ? colors.brandPrimary
                      : colors.error,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Deliver To',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  if (_isGuest) {
                    _goToLogin();
                  } else {
                    Navigator.of(context)
                        .pushNamed(RouteNames.profile);
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  backgroundColor:
                      colors.brandPrimary.withOpacity(0.10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Change',
                  style: GoogleFonts.poppins(
                    color: colors.brandPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasAddress
                  ? colors.brandPrimary.withOpacity(0.06)
                  : colors.error.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  hasAddress
                      ? Icons.location_on_rounded
                      : Icons.location_off_rounded,
                  color: hasAddress
                      ? colors.brandPrimary
                      : colors.error,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isGuest
                        ? 'Sign in to set your delivery address'
                        : (selectedAddress.isEmpty
                            ? 'No address selected — tap Change to add one'
                            : selectedAddress),
                    style: GoogleFonts.poppins(
                      color: hasAddress
                          ? colors.textPrimary
                          : colors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: hasAddress
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (!_isGuest) ...[
            const SizedBox(height: 12),
            if (_deliveryFeeError != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: colors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: colors.error.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: colors.error, size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _deliveryFeeError!,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: colors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_deliveryFeeAmount != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: colors.paleGreen,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color:
                          colors.success.withOpacity(0.30)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: colors.success, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            _deliveryFeeAmount == 0
                                ? 'Free delivery! 🎉'
                                : 'Delivery fee estimated',
                            style: GoogleFonts.poppins(
                              color: colors.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'To: ${selectedAddress.length > 40 ? '${selectedAddress.substring(0, 40)}...' : selectedAddress}',
                            style: GoogleFonts.poppins(
                              color: colors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _deliveryFeeAmount == 0
                          ? 'FREE'
                          : '₦${_deliveryFeeAmount!.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        color: colors.success,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _loadingDeliveryFee
                    ? null
                    : () => _estimateDeliveryFee(
                          selectedAddress,
                          itemsTotal,
                        ),
                icon: _loadingDeliveryFee
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.brandPrimary,
                        ),
                      )
                    : const Icon(
                        Icons.calculate_rounded, size: 18),
                label: Text(
                  _loadingDeliveryFee
                      ? 'Calculating...'
                      : (_deliveryFeeAmount != null
                          ? 'Re-estimate Delivery'
                          : 'Calculate Delivery Fee'),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Coupon Section ────────────────────────────────────────────────────────

  Widget _buildCouponSection(dynamic colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSoft),
        boxShadow: [
          BoxShadow(
              color: colors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer_rounded,
                  color: colors.brandPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Coupon Code',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: colors.textPrimary,
                ),
              ),
              if (_couponApplied) ...[
                const Spacer(),
                GestureDetector(
                  onTap: _removeCoupon,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.error.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Remove',
                      style: GoogleFonts.poppins(
                        color: colors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (_couponApplied)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.paleGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: colors.success.withOpacity(0.30)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: colors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coupon "${_couponCtrl.text.trim().toUpperCase()}" applied — ${(_couponDiscount * 100).toStringAsFixed(0)}% off items!',
                      style: GoogleFonts.poppins(
                        color: colors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponCtrl,
                    textCapitalization:
                        TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: colors.textSecondary),
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: colors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: colors.brandPrimary,
                            width: 1.5),
                      ),
                      filled: true,
                      fillColor: colors.surfaceAlt,
                    ),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _checkingCoupon
                        ? null
                        : _applyCoupon,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12)),
                    ),
                    child: _checkingCoupon
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              // ── Black spinner on gold button ─
                              color: AppPalette.secondary,
                            ),
                          )
                        : Text(
                            'Apply',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          if (_couponError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _couponError!,
                style: GoogleFonts.poppins(
                  color: colors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Payment Method Section ────────────────────────────────────────────────

  Widget _buildPaymentMethodSection(dynamic colors) {
    final methods = ['Paystack', 'Bank Transfer', 'USSD'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSoft),
        boxShadow: [
          BoxShadow(
              color: colors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment_rounded,
                  color: colors.brandPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Payment Method',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...methods.map((method) {
            final isSelected   = _selectedPayment == method;
            final isComingSoon = method != 'Paystack';

            return GestureDetector(
              onTap: isComingSoon
                  ? null
                  : () => setState(
                      () => _selectedPayment = method),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.brandPrimary.withOpacity(0.08)
                      : colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? colors.brandPrimary
                        : colors.borderSoft,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      method == 'Paystack'
                          ? Icons.credit_card_rounded
                          : method == 'Bank Transfer'
                              ? Icons.account_balance_rounded
                              : Icons.phone_android_rounded,
                      color: isSelected
                          ? colors.brandPrimary
                          : colors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        method,
                        style: GoogleFonts.poppins(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? colors.brandPrimary
                              : colors.textPrimary,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    if (isComingSoon)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.warning
                              .withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Soon',
                          style: GoogleFonts.poppins(
                            color: colors.warning,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else if (isSelected)
                      Icon(Icons.check_circle_rounded,
                          color: colors.brandPrimary,
                          size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Order Summary ─────────────────────────────────────────────────────────

  Widget _buildOrderSummary({
    required dynamic colors,
    required List<Map<String, dynamic>> cartItems,
    required String selectedAddress,
    required double itemsTotal,
    required double deliveryFee,
    required double couponSaving,
    required double grandTotal,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderSoft),
        boxShadow: [
          BoxShadow(
              color: colors.shadow,
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      colors.brandPrimary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long_rounded,
                    color: colors.brandPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Order Summary',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          _SummaryRow(
            label: 'Items Subtotal',
            value: '₦${itemsTotal.toStringAsFixed(0)}',
            colors: colors,
          ),
          const SizedBox(height: 8),

          _SummaryRow(
            label: 'Delivery Fee',
            value: _deliveryFeeAmount == null
                ? 'Not estimated'
                : (deliveryFee == 0
                    ? 'FREE'
                    : '₦${deliveryFee.toStringAsFixed(0)}'),
            colors: colors,
            valueColor: _deliveryFeeAmount == null
                ? colors.warning
                : (deliveryFee == 0 ? colors.success : null),
            icon: _deliveryFeeAmount == null
                ? Icons.warning_rounded
                : null,
          ),

          if (couponSaving > 0) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Coupon Discount',
              value: '- ₦${couponSaving.toStringAsFixed(0)}',
              colors: colors,
              valueColor: colors.success,
              icon: Icons.local_offer_rounded,
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Grand total
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.brandPrimary.withOpacity(0.08),
                  colors.brandPrimary.withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color:
                      colors.brandPrimary.withOpacity(0.20)),
            ),
            child: Row(
              children: [
                Text(
                  'Grand Total',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '₦${grandTotal.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: colors.brandPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (itemsTotal >= 25000 &&
              _deliveryFeeAmount != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('🎉',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'You qualify for free delivery on this order!',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // ── Checkout button ────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _processingCheckout
                  ? null
                  : () => _checkout(
                        cartItems,
                        grandTotal,
                        itemsTotal,
                        deliveryFee,
                        couponSaving,
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.brandPrimary,
                // ── Black text on gold checkout button ────────
                foregroundColor: AppPalette.secondary,
                elevation: 3,
                shadowColor:
                    colors.brandPrimary.withOpacity(0.40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: _processingCheckout
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppPalette.secondary,
                      ),
                    )
                  : const Icon(Icons.lock_rounded, size: 20),
              label: Text(
                _processingCheckout
                    ? 'Processing...'
                    : (_isGuest
                        ? 'Sign In to Checkout'
                        : 'Proceed to Checkout'),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TrustBadge(
                icon: Icons.verified_user_rounded,
                label: 'Paystack Secured',
                colors: colors,
              ),
              const SizedBox(width: 16),
              _TrustBadge(
                icon: Icons.lock_rounded,
                label: 'SSL Encrypted',
                colors: colors,
              ),
              const SizedBox(width: 16),
              _TrustBadge(
                icon: Icons.replay_rounded,
                label: 'Easy Returns',
                colors: colors,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QtyButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final dynamic colors;

  const _MiniTag({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.brandPrimary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: colors.brandPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final dynamic colors;
  final Color? valueColor;
  final IconData? icon;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.colors,
    this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon,
              size: 14,
              color: valueColor ?? colors.textSecondary),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: valueColor ?? colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic colors;

  const _TrustBadge({
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 12,
            color: colors.textSecondary.withOpacity(0.60)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: colors.textSecondary.withOpacity(0.60),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}