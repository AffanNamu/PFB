// lib/features/orders/presentation/screens/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/models/order_model.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Sakash Collection Order Detail Screen
// ═══════════════════════════════════════════════════════════════════════════════

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen(
      {super.key, required this.order});

  Color _statusColor(String status, dynamic colors) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return colors.success;
      case 'cancelled':
        return colors.error;
      case 'processing':
        return colors.info;
      case 'confirmed':
        return const Color(0xFF0288D1);
      case 'shipped':
      case 'out for delivery':
        return colors.brandPrimary;
      default:
        return colors.warning;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'processing':
        return Icons.hourglass_top_rounded;
      case 'confirmed':
        return Icons.verified_rounded;
      case 'shipped':
        return Icons.local_shipping_rounded;
      case 'out for delivery':
        return Icons.delivery_dining_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'N/A';
    try {
      final date   = DateTime.parse(rawDate);
      final months = [
        'January', 'February', 'March', 'April',
        'May', 'June', 'July', 'August',
        'September', 'October', 'November', 'December',
      ];
      final hour   = date.hour;
      final minute =
          date.minute.toString().padLeft(2, '0');
      final ampm   = hour >= 12 ? 'PM' : 'AM';
      final hour12 =
          hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '${date.day} ${months[date.month - 1]} ${date.year} · $hour12:$minute $ampm';
    } catch (_) {
      return rawDate;
    }
  }

  bool _hasValidImage(String url) {
    final v = url.trim();
    return v.isNotEmpty &&
        (v.startsWith('http://') ||
            v.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    final colors      = AppTheme.colorsOf(context);
    final statusColor = _statusColor(order.status, colors);
    final statusIcon  = _statusIcon(order.status);

    final shortId = order.id.length > 12
        ? order.id.substring(0, 12).toUpperCase()
        : order.id.toUpperCase();

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: CustomScrollView(
        slivers: [
          // ── SLIVER APP BAR ─────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: colors.scaffold,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: colors.textPrimary,
                ),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: order.id),
                  );
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        'Order ID copied!',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600),
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      duration:
                          const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withOpacity(0.15),
                      colors.scaffold,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 80, 20, 16),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.end,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding:
                                const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: statusColor
                                  .withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(
                                      16),
                            ),
                            child: Icon(
                              statusIcon,
                              color: statusColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order #$shortId',
                                  style:
                                      GoogleFonts.poppins(
                                    fontWeight:
                                        FontWeight.w900,
                                    fontSize: 18,
                                    color:
                                        colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor
                                        .withOpacity(0.15),
                                    borderRadius:
                                        BorderRadius
                                            .circular(20),
                                    border: Border.all(
                                      color: statusColor
                                          .withOpacity(
                                              0.35),
                                    ),
                                  ),
                                  child: Text(
                                    order.status
                                        .toUpperCase(),
                                    style:
                                        GoogleFonts.poppins(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₦${order.totalAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: colors.brandPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── CONTENT ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  if (order.status.toLowerCase() !=
                          'cancelled' &&
                      order.status.toLowerCase() !=
                          'delivered')
                    _buildDeliveryProgress(colors),

                  if (order.status.toLowerCase() !=
                          'cancelled' &&
                      order.status.toLowerCase() !=
                          'delivered')
                    const SizedBox(height: 16),

                  _buildDetailCard(colors, shortId),
                  const SizedBox(height: 14),

                  if (order.deliveryAddress.isNotEmpty)
                    _buildDeliveryCard(colors),
                  if (order.deliveryAddress.isNotEmpty)
                    const SizedBox(height: 14),

                  _buildItemsCard(colors),
                  const SizedBox(height: 14),

                  _buildPriceCard(colors),
                  const SizedBox(height: 14),

                  if ((order.paymentReference ?? '')
                      .isNotEmpty)
                    _buildPaymentCard(colors),
                  if ((order.paymentReference ?? '')
                      .isNotEmpty)
                    const SizedBox(height: 14),

                  _buildHelpSection(colors, context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── DELIVERY PROGRESS ─────────────────────────────────────────────────────

  Widget _buildDeliveryProgress(dynamic colors) {
    final stages = [
      _ProgressStage(
          label: 'Order Placed',
          icon: Icons.shopping_bag_rounded),
      _ProgressStage(
          label: 'Confirmed',
          icon: Icons.verified_rounded),
      _ProgressStage(
          label: 'Shipped',
          icon: Icons.local_shipping_rounded),
      _ProgressStage(
          label: 'Delivery',
          icon: Icons.delivery_dining_rounded),
      _ProgressStage(
          label: 'Delivered',
          icon: Icons.check_circle_rounded),
    ];

    int currentStage = 0;
    switch (order.status.toLowerCase()) {
      case 'processing':
        currentStage = 0;
        break;
      case 'confirmed':
        currentStage = 1;
        break;
      case 'shipped':
        currentStage = 2;
        break;
      case 'out for delivery':
        currentStage = 3;
        break;
      case 'delivered':
        currentStage = 4;
        break;
    }

    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping_rounded,
                color: colors.brandPrimary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Order Progress',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children:
                List.generate(stages.length, (i) {
              final done   = i <= currentStage;
              final active = i == currentStage;

              return Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(
                          milliseconds: 300),
                      width:  active ? 44 : 36,
                      height: active ? 44 : 36,
                      decoration: BoxDecoration(
                        // ── Gold when done ───────────────
                        color: done
                            ? colors.brandPrimary
                            : colors.borderSoft,
                        shape: BoxShape.circle,
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: colors.brandPrimary
                                      .withOpacity(0.35),
                                  blurRadius: 10,
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        stages[i].icon,
                        // ── Black icon on gold ───────────
                        color: done
                            ? AppPalette.secondary
                            : colors.textSecondary,
                        size: active ? 20 : 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stages[i].label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: done
                            ? colors.brandPrimary
                            : colors.textSecondary,
                        fontWeight: done
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 24),
            child: Row(
              children: List.generate(
                stages.length - 1,
                (i) => Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 4),
                    decoration: BoxDecoration(
                      color: i < currentStage
                          ? colors.brandPrimary
                          : colors.borderSoft,
                      borderRadius:
                          BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ORDER DETAIL CARD ─────────────────────────────────────────────────────

  Widget _buildDetailCard(
      dynamic colors, String shortId) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.receipt_rounded,
            title: 'Order Details',
            colors: colors,
          ),
          const SizedBox(height: 14),
          _DetailRow(
            label: 'Order ID',
            value: '#$shortId',
            colors: colors,
            isBold: true,
          ),
          _DetailRow(
            label: 'Placed',
            value: _formatDate(order.createdAt),
            colors: colors,
          ),
          // ── Brand name updated ─────────────────────────────
          _DetailRow(
            label: 'Platform',
            value: 'Sakash Collection',
            colors: colors,
          ),
          _DetailRow(
            label: 'Items',
            value:
                '${order.items.length} product${order.items.length == 1 ? '' : 's'}',
            colors: colors,
          ),
        ],
      ),
    );
  }

  // ── DELIVERY CARD ─────────────────────────────────────────────────────────

  Widget _buildDeliveryCard(dynamic colors) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.local_shipping_rounded,
            title: 'Delivery Information',
            colors: colors,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.brandPrimary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: colors.brandPrimary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if ((order.deliveryFee ?? 0) > 0) ...[
            const SizedBox(height: 10),
            _DetailRow(
              label: 'Delivery Fee',
              value:
                  '₦${(order.deliveryFee ?? 0).toStringAsFixed(0)}',
              colors: colors,
            ),
          ],
        ],
      ),
    );
  }

  // ── ITEMS CARD ────────────────────────────────────────────────────────────

  Widget _buildItemsCard(dynamic colors) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.style_rounded,
            title:
                'Items Ordered (${order.items.length})',
            colors: colors,
          ),
          const SizedBox(height: 14),
          ...order.items.map((item) {
            final name     = (item['name'] ?? '').toString();
            final price    =
                ((item['price'] ?? 0) as num).toDouble();
            final qty      = (item['qty'] ?? 1) as int;
            final imageUrl =
                (item['imageUrl'] ?? '').toString();
            final fabricType =
                (item['fabricType'] ?? '').toString();
            final subtotal = price * qty;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: colors.borderSoft),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(10),
                    child: SizedBox(
                      width: 58,
                      height: 58,
                      child: _hasValidImage(imageUrl)
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) =>
                                      _imgPlaceholder(
                                          colors),
                            )
                          : _imgPlaceholder(colors),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: colors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (fabricType.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            fabricType,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          '₦${price.toStringAsFixed(0)} × $qty',
                          style: GoogleFonts.poppins(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₦${subtotal.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      color: colors.brandPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _imgPlaceholder(dynamic colors) {
    return Container(
      color: colors.brandPrimary.withOpacity(0.10),
      child: Icon(
        Icons.style_rounded,
        color: colors.brandPrimary.withOpacity(0.50),
        size: 24,
      ),
    );
  }

  // ── PRICE CARD ────────────────────────────────────────────────────────────

  Widget _buildPriceCard(dynamic colors) {
    final itemsTotal = order.items.fold<double>(
      0,
      (sum, item) =>
          sum +
          (((item['price'] ?? 0) as num).toDouble() *
              ((item['qty'] ?? 1) as int)),
    );
    final deliveryFee    = order.deliveryFee    ?? 0;
    final couponDiscount = order.couponDiscount ?? 0;

    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.receipt_long_rounded,
            title: 'Price Breakdown',
            colors: colors,
          ),
          const SizedBox(height: 14),
          _PriceRow(
            label: 'Items Subtotal',
            value: '₦${itemsTotal.toStringAsFixed(0)}',
            colors: colors,
          ),
          if (deliveryFee > 0)
            _PriceRow(
              label: 'Delivery Fee',
              value:
                  '₦${deliveryFee.toStringAsFixed(0)}',
              colors: colors,
            ),
          if (couponDiscount > 0)
            _PriceRow(
              label: 'Coupon Discount',
              value:
                  '- ₦${couponDiscount.toStringAsFixed(0)}',
              colors: colors,
              valueColor: colors.success,
            ),
          const Divider(height: 20),
          Row(
            children: [
              Text(
                'Grand Total',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '₦${order.totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: colors.brandPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── PAYMENT CARD ──────────────────────────────────────────────────────────

  Widget _buildPaymentCard(dynamic colors) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.credit_card_rounded,
            title: 'Payment',
            colors: colors,
          ),
          const SizedBox(height: 14),
          _DetailRow(
            label: 'Method',
            value: 'Paystack',
            colors: colors,
          ),
          _DetailRow(
            label: 'Reference',
            value: order.paymentReference ?? 'N/A',
            colors: colors,
          ),
          _DetailRow(
            label: 'Status',
            value: order.paymentStatus ?? 'Paid',
            colors: colors,
            valueColor: colors.success,
          ),
        ],
      ),
    );
  }

  // ── HELP SECTION ──────────────────────────────────────────────────────────

  Widget _buildHelpSection(
      dynamic colors, BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🧵',
                  style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Need Help?',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            // ── Brand name updated ─────────────────────────
            'Contact Sakash Collection support for order issues, returns, or tailoring inquiries.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content:
                            Text('Opening WhatsApp...'),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.chat_rounded,
                    size: 16,
                  ),
                  label: Text(
                    'WhatsApp',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content:
                            Text('Opening email...'),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.email_rounded,
                    size: 16,
                  ),
                  label: Text(
                    'Email Us',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProgressStage {
  final String   label;
  final IconData icon;
  const _ProgressStage(
      {required this.label, required this.icon});
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String   title;
  final dynamic  colors;

  const _CardHeader({
    required this.icon,
    required this.title,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                colors.brandPrimary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: colors.brandPrimary,
            size: 16,
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
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String  label;
  final String  value;
  final dynamic colors;
  final bool    isBold;
  final Color?  valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.colors,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: valueColor ?? colors.textPrimary,
                fontWeight: isBold
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String  label;
  final String  value;
  final dynamic colors;
  final Color?  valueColor;

  const _PriceRow({
    required this.label,
    required this.value,
    required this.colors,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: valueColor ?? colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}