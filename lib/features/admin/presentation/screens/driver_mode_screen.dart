// lib/features/admin/presentation/screens/driver_mode_screen.dart
// ── Sakash Collection — Delivery Dispatch Mode Screen ───────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/models/order_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_section_title.dart';
import 'package:pfb/shared/widgets/app_status_chip.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class DriverModeScreen extends StatefulWidget {
  final OrderModel order;
  final String dispatcherName;

  const DriverModeScreen({
    super.key,
    required this.order,
    required this.dispatcherName,
  });

  @override
  State<DriverModeScreen> createState() => _DriverModeScreenState();
}

class _DriverModeScreenState extends State<DriverModeScreen> {
  final _firebaseService = FirebaseService();
  bool _busy = false;

  Future<void> _updateStatus(String status) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      await _firebaseService.updateOrderStatus(
        orderId: widget.order.id,
        status: status,
      );

      if (!mounted) return;

      final label = _statusLabel(status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order marked as $label',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: _statusSnackColor(status),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      if (status == 'delivered' || status == 'cancelled') {
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered ✅';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color _statusSnackColor(String status) {
    final colors = context.appColors;
    switch (status) {
      case 'delivered':
        return colors.success;
      case 'cancelled':
        return colors.error;
      case 'shipped':
        return Colors.orange.shade600;
      default:
        return colors.info;
    }
  }

  AppStatusChipTone _currentTone() {
    switch (widget.order.status.toLowerCase()) {
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
    final colors = context.appColors;
    final order = widget.order;

    return AppPageScaffold(
      title: 'Dispatch Mode',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Dispatcher Info Banner ─────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              // ── Gold gradient banner ──────────────────────────
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    // ── Subtle white tint on gold ───────────────
                    color: AppPalette.secondary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    // ── Black icon on gold ──────────────────────
                    color: AppPalette.secondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // ── Brand name updated ──────────────────
                        'Sakash Collection Dispatch',
                        style: GoogleFonts.cinzel(
                          // ── Black text on gold ────────────────
                          color: AppPalette.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Dispatcher: ${widget.dispatcherName}',
                        style: GoogleFonts.poppins(
                          // ── Dark text on gold ─────────────────
                          color: AppPalette.secondary
                              .withOpacity(0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Order Details Card ─────────────────────────────────
          AppSurfaceCard(
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSectionTitle(
                  title: 'Order #${order.shortId}',
                  spacingBottom: 4,
                ),
                Text(
                  order.formattedDate,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Text(
                      'Current Status: ',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    AppStatusChip(
                      label: order.status.toUpperCase(),
                      tone: _currentTone(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (order.deliveryAddress.isNotEmpty) ...[
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    label: 'Deliver To',
                    value: order.deliveryAddress,
                    colors: colors,
                  ),
                  const SizedBox(height: 10),
                ],

                _InfoRow(
                  icon: Icons.payments_rounded,
                  label: 'Order Total',
                  value: '₦${order.totalAmount.toStringAsFixed(0)}',
                  colors: colors,
                  valueStyle: GoogleFonts.poppins(
                    color: colors.brandPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),

                if (order.items.isNotEmpty) ...[
                  Text(
                    'ITEMS (${order.items.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: order.items.map((item) {
                        final name = item['name'] ?? 'Fabric Item';
                        final qty =
                            item['quantity'] ?? item['qty'] ?? 1;
                        final fabricType =
                            item['fabricType'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: colors.brandPrimary
                                      .withOpacity(0.10),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.texture_rounded,
                                  size: 16,
                                  color: colors.brandPrimary
                                      .withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.toString(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (fabricType.isNotEmpty)
                                      Text(
                                        fabricType.toString(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                'x$qty',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Dispatch Actions Card ──────────────────────────────
          AppSurfaceCard(
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DISPATCH ACTIONS',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),

                _DispatchButton(
                  icon: Icons.autorenew_rounded,
                  label: 'Mark as Processing',
                  subtitle: 'Fabric is being prepared',
                  color: colors.info,
                  isActive: order.status == 'processing',
                  isBusy: _busy,
                  onTap: () => _updateStatus('processing'),
                ),
                const SizedBox(height: 10),

                _DispatchButton(
                  icon: Icons.local_shipping_outlined,
                  label: 'Mark as Shipped',
                  subtitle: 'Order is on its way',
                  color: Colors.orange.shade600,
                  isActive: order.status == 'shipped',
                  isBusy: _busy,
                  onTap: () => _updateStatus('shipped'),
                ),
                const SizedBox(height: 10),

                _DispatchButton(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Mark as Delivered',
                  subtitle: 'Customer received the order',
                  color: colors.success,
                  isActive: order.status == 'delivered',
                  isBusy: _busy,
                  onTap: () => _updateStatus('delivered'),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                _DispatchButton(
                  icon: Icons.cancel_outlined,
                  label: 'Cancel Order',
                  subtitle: 'Use only if necessary',
                  color: colors.error,
                  isActive: order.status == 'cancelled',
                  isBusy: _busy,
                  onTap: () => _updateStatus('cancelled'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textSecondary,
                side: BorderSide(color: colors.borderSoft),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(
                'Back to Dashboard',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Info Row ───────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    this.valueStyle,
  });

  final IconData icon;
  final String label;
  final String value;
  final dynamic colors;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colors.textSecondary),
        const SizedBox(width: 8),
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
                style: valueStyle ??
                    GoogleFonts.poppins(
                      fontSize: 13,
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Dispatch Button ────────────────────────────────────────────────────────────

class _DispatchButton extends StatelessWidget {
  const _DispatchButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isActive,
    required this.isBusy,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isActive;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isBusy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive
              ? color.withOpacity(0.12)
              : context.appColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? color : context.appColors.borderSoft,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isActive
                          ? color
                          : context.appColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Icon(
                Icons.check_circle_rounded,
                color: color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}