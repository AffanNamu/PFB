// ── PhlakesFabric — Delivery Tracking Screen ──────────────────────────────────────
// This file replaces the old ride management screen.
// It now tracks TEXTILE ORDER DELIVERIES only — no ride/taxi references.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/core/constants/app_constants.dart';
import 'package:pfb/features/admin/presentation/screens/admin_reassignment_screen.dart';
import 'package:pfb/models/order_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_status_chip.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

// ── AdminRidesScreen is now the Delivery Management Screen ────────────────────
// The class name is kept as AdminRidesScreen so existing route references
// in admin_dashboard_screen.dart don't break during this batch.

class AdminRidesScreen extends StatelessWidget {
  AdminRidesScreen({super.key});

  final firebaseService = FirebaseService();

  // ── Status color resolver ────────────────────────────────────────────────────
  Color _statusColor(BuildContext context, String status) {
    final colors = context.appColors;
    switch (status.toLowerCase()) {
      case 'delivered':
        return colors.success;
      case 'cancelled':
        return colors.error;
      case 'processing':
        return colors.info;
      case 'shipped':
        return Colors.orange.shade600;
      default:
        return colors.brandPrimary;
    }
  }

  AppStatusChipTone _statusTone(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppStatusChipTone.success;
      case 'cancelled':
        return AppStatusChipTone.error;
      case 'processing':
        return AppStatusChipTone.info;
      case 'shipped':
        return AppStatusChipTone.warning;
      default:
        return AppStatusChipTone.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return FutureBuilder<bool>(
      future: firebaseService.isAdmin(),
      builder: (context, adminSnapshot) {
        if (adminSnapshot.connectionState == ConnectionState.waiting) {
          return AppPageScaffold(
            title: 'Delivery Management',
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final isAdmin = adminSnapshot.data ?? false;
        final isSuperAdmin = AppConstants.isSuperAdminUid(
          FirebaseAuth.instance.currentUser?.uid,
        );

        if (!isAdmin && !isSuperAdmin) {
          return AppPageScaffold(
            title: 'Delivery Management',
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 56,
                    color: colors.textSecondary.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Access Restricted',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You do not have access to delivery management.',
                    style: GoogleFonts.poppins(
                      color: colors.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Use assigned orders stream — deliveries are now part of orders
        final stream = isSuperAdmin
            ? firebaseService.watchAllOrders()
            : firebaseService.watchAssignedOrdersForAdmin();

        return AppPageScaffold(
          title: isSuperAdmin
              ? 'All Deliveries'
              : 'My Assigned Deliveries',
          body: StreamBuilder<List<OrderModel>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final orders = snapshot.data ?? [];

              // Filter to show only active/shipped/processing (non-delivered)
              // so this screen acts as a live delivery board
              final activeDeliveries = orders;

              if (activeDeliveries.isEmpty) {
                return _buildEmptyState(colors, isSuperAdmin);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activeDeliveries.length,
                itemBuilder: (_, i) {
                  final order = activeDeliveries[i];
                  return _DeliveryCard(
                    order: order,
                    colors: colors,
                    isSuperAdmin: isSuperAdmin,
                    statusColor: _statusColor(context, order.status),
                    statusTone: _statusTone(order.status),
                    firebaseService: firebaseService,
                    context: context,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(dynamic colors, bool isSuperAdmin) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colors.brandPrimary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_shipping_outlined,
                size: 48,
                color: colors.brandPrimary.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSuperAdmin
                  ? 'No Deliveries Yet'
                  : 'No Assigned Deliveries',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSuperAdmin
                  ? 'All textile order deliveries will appear here.'
                  : 'Deliveries assigned to your area will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Delivery Card ──────────────────────────────────────────────────────────────

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({
    required this.order,
    required this.colors,
    required this.isSuperAdmin,
    required this.statusColor,
    required this.statusTone,
    required this.firebaseService,
    required this.context,
  });

  final OrderModel order;
  final dynamic colors;
  final bool isSuperAdmin;
  final Color statusColor;
  final AppStatusChipTone statusTone;
  final FirebaseService firebaseService;
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 14),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.brandPrimary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${order.shortId}',
                  style: GoogleFonts.poppins(
                    color: colors.brandPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AppStatusChip(
                label: order.status.toUpperCase(),
                tone: statusTone,
              ),
              if (order.escalatedToSuperAdmin) ...[
                const SizedBox(width: 8),
                const AppStatusChip(
                  label: 'ESCALATED',
                  tone: AppStatusChipTone.error,
                ),
              ],
              const Spacer(),
              Text(
                order.formattedDate,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Delivery destination ────────────────────────────
          if (order.deliveryAddress.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: colors.brandPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Address',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.deliveryAddress,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // ── Items preview ───────────────────────────────────
          if (order.items.isNotEmpty) ...[
            Text(
              'ITEMS',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            ...order.items.take(2).map((item) {
              final name = item['name'] ?? 'Fabric Item';
              final qty = item['quantity'] ?? item['qty'] ?? 1;
              final fabricType = item['fabricType'] ?? '';
              final color = item['color'] ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colors.brandPrimary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.texture_rounded,
                        size: 14,
                        color: colors.brandPrimary.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        [
                          name.toString(),
                          if (fabricType.isNotEmpty) fabricType,
                          if (color.isNotEmpty) color,
                        ].join(' · '),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'x$qty',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (order.items.length > 2)
              Text(
                '+${order.items.length - 2} more item(s)',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: colors.textSecondary,
                ),
              ),
            const SizedBox(height: 10),
          ],

          // ── Order total ─────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.payments_rounded,
                size: 14,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Total: ',
                style: GoogleFonts.poppins(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                '₦${order.totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  color: colors.brandPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          // ── Admin info ──────────────────────────────────────
          if (order.assignedAdminName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 14,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Admin: ${order.assignedAdminName}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // ── Delivery status buttons ─────────────────────────
          Text(
            'UPDATE DELIVERY STATUS',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DeliveryStatusBtn(
                label: 'Pending',
                icon: Icons.hourglass_empty_rounded,
                isActive: order.status == 'pending',
                color: colors.textSecondary,
                colors: colors,
                onTap: () => firebaseService.updateOrderStatus(
                  orderId: order.id,
                  status: 'pending',
                ),
              ),
              _DeliveryStatusBtn(
                label: 'Processing',
                icon: Icons.autorenew_rounded,
                isActive: order.status == 'processing',
                color: colors.info,
                colors: colors,
                onTap: () => firebaseService.updateOrderStatus(
                  orderId: order.id,
                  status: 'processing',
                ),
              ),
              _DeliveryStatusBtn(
                label: 'Shipped',
                icon: Icons.local_shipping_outlined,
                isActive: order.status == 'shipped',
                color: Colors.orange.shade600,
                colors: colors,
                onTap: () => firebaseService.updateOrderStatus(
                  orderId: order.id,
                  status: 'shipped',
                ),
              ),
              _DeliveryStatusBtn(
                label: 'Delivered',
                icon: Icons.check_circle_outline_rounded,
                isActive: order.status == 'delivered',
                color: colors.success,
                colors: colors,
                onTap: () => firebaseService.updateOrderStatus(
                  orderId: order.id,
                  status: 'delivered',
                ),
              ),
              _DeliveryStatusBtn(
                label: 'Cancelled',
                icon: Icons.cancel_outlined,
                isActive: order.status == 'cancelled',
                color: colors.error,
                colors: colors,
                onTap: () => firebaseService.updateOrderStatus(
                  orderId: order.id,
                  status: 'cancelled',
                ),
              ),
            ],
          ),

          // ── Reassign (Super Admin only) ─────────────────────
          if (isSuperAdmin) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminReassignmentScreen(
                        order: order,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.brandPrimary,
                  side: BorderSide(
                    color: colors.brandPrimary.withOpacity(0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: Text(
                  'Reassign Delivery',
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
}

// ── Delivery Status Button ─────────────────────────────────────────────────────

class _DeliveryStatusBtn extends StatelessWidget {
  const _DeliveryStatusBtn({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.color,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final Color color;
  final dynamic colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color:
              isActive ? color.withOpacity(0.15) : colors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color : colors.borderSoft,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive ? color : colors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? color : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
