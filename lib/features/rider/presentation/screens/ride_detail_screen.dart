// lib/features/rider/presentation/screens/ride_detail_screen.dart
// ── Sakash Collection — Order Detail Tracker Screen ─────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/models/order_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_status_chip.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';
import 'package:pfb/core/theme/app_theme.dart';

class RideDetailScreen extends StatelessWidget {
  final OrderModel order;

  const RideDetailScreen({
    super.key,
    required this.order,
  });

  AppStatusChipTone _statusTone(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppStatusChipTone.success;
      case 'cancelled':
        return AppStatusChipTone.error;
      case 'shipped':
        return AppStatusChipTone.warning;
      case 'processing':
        return AppStatusChipTone.info;
      default:
        return AppStatusChipTone.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final colors          = context.appColors;

    return AppPageScaffold(
      title: 'Order Details',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Order ID Header ────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              // ── Gold gradient header ─────────────────────────
              gradient: const LinearGradient(
                colors: [
                  AppPalette.primaryDark,
                  AppPalette.primary,
                  AppPalette.primaryLight,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  // ── Black icon on gold gradient ──────────────
                  color: AppPalette.secondary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.shortId}',
                        style: GoogleFonts.poppins(
                          // ── Black text on gold ───────────────
                          color: AppPalette.secondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        order.formattedDate,
                        style: GoogleFonts.poppins(
                          // ── Dark text, slightly muted ────────
                          color: AppPalette.secondary
                              .withOpacity(0.65),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                AppStatusChip(
                  label: order.status.toUpperCase(),
                  tone: _statusTone(order.status),
                ),
              ],
            ),
          ),

          // ── Delivery Progress Tracker ──────────────────────────
          AppSurfaceCard(
            margin: const EdgeInsets.only(bottom: 16),
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DELIVERY PROGRESS',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                _ProgressStep(
                  label: 'Order Placed',
                  icon: Icons.check_circle_rounded,
                  isCompleted: true,
                  colors: colors,
                ),
                _ProgressStep(
                  label: 'Processing',
                  icon: Icons.autorenew_rounded,
                  isCompleted: [
                    'processing',
                    'shipped',
                    'delivered',
                  ].contains(order.status.toLowerCase()),
                  colors: colors,
                ),
                _ProgressStep(
                  label: 'Shipped',
                  icon: Icons.local_shipping_outlined,
                  isCompleted: [
                    'shipped',
                    'delivered',
                  ].contains(order.status.toLowerCase()),
                  colors: colors,
                ),
                _ProgressStep(
                  label: 'Delivered',
                  icon: Icons.celebration_rounded,
                  isCompleted:
                      order.status.toLowerCase() == 'delivered',
                  isLast: true,
                  colors: colors,
                ),
              ],
            ),
          ),

          // ── Delivery Address ───────────────────────────────────
          if (order.deliveryAddress.isNotEmpty)
            AppSurfaceCard(
              margin: const EdgeInsets.only(bottom: 16),
              borderRadius: BorderRadius.circular(20),
              child: _DetailRow(
                icon: Icons.location_on_rounded,
                label: 'Deliver To',
                value: order.deliveryAddress,
                colors: colors,
                iconColor: colors.brandPrimary,
              ),
            ),

          // ── Order Items ────────────────────────────────────────
          if (order.items.isNotEmpty)
            AppSurfaceCard(
              margin: const EdgeInsets.only(bottom: 16),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ORDER ITEMS',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...order.items.map((item) {
                    final name =
                        item['name'] ?? 'Item';
                    final qty = item['quantity'] ??
                        item['qty'] ??
                        1;
                    final price =
                        ((item['price'] ?? 0) as num)
                            .toDouble();
                    final fabricType =
                        item['fabricType'] ?? '';
                    final color  = item['color'] ?? '';
                    final size   = item['size'] ?? '';
                    final imageUrl = item['imageUrl'] ?? '';

                    return Container(
                      margin:
                          const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.surfaceAlt,
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(10),
                            child: SizedBox(
                              width: 52,
                              height: 52,
                              child: imageUrl
                                      .startsWith('http')
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) =>
                                              _fabricPlaceholder(
                                                  colors),
                                    )
                                  : _fabricPlaceholder(
                                      colors),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.toString(),
                                  style: GoogleFonts.poppins(
                                    fontWeight:
                                        FontWeight.w600,
                                    color: colors.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                                if (fabricType.isNotEmpty ||
                                    color.isNotEmpty ||
                                    size.isNotEmpty)
                                  Text(
                                    [
                                      if (fabricType
                                          .isNotEmpty)
                                        fabricType,
                                      if (color.isNotEmpty)
                                        color,
                                      if (size.isNotEmpty)
                                        size,
                                    ].join(' · '),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color:
                                          colors.textSecondary,
                                    ),
                                  ),
                                Text(
                                  '₦${price.toStringAsFixed(0)} × $qty',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colors.brandPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₦${(price * qty).toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

          // ── Price Breakdown ────────────────────────────────────
          AppSurfaceCard(
            margin: const EdgeInsets.only(bottom: 16),
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                _PriceLine(
                  label: 'Subtotal',
                  value:
                      '₦${order.itemsSubtotal.toStringAsFixed(0)}',
                  colors: colors,
                ),
                if (order.deliveryFee > 0)
                  _PriceLine(
                    label: 'Delivery Fee',
                    value:
                        '₦${order.deliveryFee.toStringAsFixed(0)}',
                    colors: colors,
                  ),
                if (order.couponDiscount > 0)
                  _PriceLine(
                    label: 'Discount',
                    value:
                        '-₦${order.couponDiscount.toStringAsFixed(0)}',
                    colors: colors,
                    valueColor: colors.success,
                  ),
                const Divider(height: 20),
                _PriceLine(
                  label: 'Total',
                  value:
                      '₦${order.totalAmount.toStringAsFixed(0)}',
                  colors: colors,
                  isBold: true,
                  valueColor: colors.brandPrimary,
                ),
              ],
            ),
          ),

          // ── Assignment Info ────────────────────────────────────
          if (order.assignedAdminName.isNotEmpty)
            AppSurfaceCard(
              margin: const EdgeInsets.only(bottom: 16),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ASSIGNED ADMIN',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon:
                        Icons.admin_panel_settings_outlined,
                    label: 'Admin',
                    value: order.assignedAdminName,
                    colors: colors,
                  ),
                  if (order.assignedAdminState.isNotEmpty)
                    _DetailRow(
                      icon: Icons.map_outlined,
                      label: 'State',
                      value: order.assignedAdminState,
                      colors: colors,
                    ),
                  if (order.assignmentMethod.isNotEmpty)
                    _DetailRow(
                      icon: Icons.settings_rounded,
                      label: 'Assignment',
                      value: order.assignmentMethod,
                      colors: colors,
                    ),
                ],
              ),
            ),

          // ── Cancel Order Button ────────────────────────────────
          if (order.isActive)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(18),
                      ),
                      title: Text(
                        'Cancel Order?',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      content: Text(
                        'Are you sure you want to cancel this order? This cannot be undone.',
                        style: GoogleFonts.poppins(
                          color: colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(ctx, false),
                          child: Text(
                            'Keep Order',
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.error,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            'Cancel Order',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  await firebaseService.updateOrderStatus(
                    orderId: order.id,
                    status: 'cancelled',
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          'Order cancelled',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: colors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.error,
                  side: BorderSide(
                      color: colors.error.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 14),
                ),
                icon: const Icon(Icons.cancel_outlined,
                    size: 18),
                label: Text(
                  'Cancel Order',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _fabricPlaceholder(dynamic colors) {
    return Container(
      color: colors.surfaceAlt,
      child: Icon(
        Icons.texture_rounded,
        color: colors.textSecondary.withOpacity(0.4),
        size: 24,
      ),
    );
  }
}

// ── Progress Step ──────────────────────────────────────────────────────────────

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.label,
    required this.icon,
    required this.isCompleted,
    required this.colors,
    this.isLast = false,
  });

  final String   label;
  final IconData icon;
  final bool     isCompleted;
  final dynamic  colors;
  final bool     isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? colors.success
                    : colors.surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? colors.success
                      : colors.borderSoft,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 16,
                color: isCompleted
                    ? Colors.white
                    : colors.textSecondary,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: isCompleted
                    ? colors.success
                    : colors.borderSoft,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding:
              const EdgeInsets.only(top: 6, bottom: 16),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isCompleted
                  ? FontWeight.w700
                  : FontWeight.w400,
              color: isCompleted
                  ? colors.textPrimary
                  : colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Detail Row ─────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    this.iconColor,
  });

  final IconData icon;
  final String   label;
  final String   value;
  final dynamic  colors;
  final Color?   iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: iconColor ?? colors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Price Line ─────────────────────────────────────────────────────────────────

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.value,
    required this.colors,
    this.isBold = false,
    this.valueColor,
  });

  final String  label;
  final String  value;
  final dynamic colors;
  final bool    isBold;
  final Color?  valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: colors.textSecondary,
              fontWeight: isBold
                  ? FontWeight.w700
                  : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold
                  ? FontWeight.w800
                  : FontWeight.w600,
              color: valueColor ?? colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}