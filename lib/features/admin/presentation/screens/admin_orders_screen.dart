// lib/features/admin/presentation/screens/admin_orders_screen.dart
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

class AdminOrdersScreen extends StatelessWidget {
  AdminOrdersScreen({super.key});

  final firebaseService = FirebaseService();

  Color _statusColor(String status, dynamic colors) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green.shade600;
      case 'processing':
        return colors.info;
      case 'shipped':
        return Colors.orange.shade600;
      case 'cancelled':
        return colors.error;
      default:
        return colors.textSecondary;
    }
  }

  AppStatusChipTone _statusTone(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppStatusChipTone.success;
      case 'processing':
        return AppStatusChipTone.info;
      case 'shipped':
        return AppStatusChipTone.warning;
      case 'cancelled':
        return AppStatusChipTone.error;
      default:
        return AppStatusChipTone.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSuperAdmin = AppConstants.isSuperAdminUid(
      FirebaseAuth.instance.currentUser?.uid,
    );

    return AppPageScaffold(
      title: isSuperAdmin ? 'All Orders' : 'Assigned Orders',
      body: FutureBuilder<bool>(
        future: firebaseService.isAdmin(),
        builder: (context, adminSnapshot) {
          if (adminSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final isAdmin = adminSnapshot.data ?? false;

          if (!isAdmin && !isSuperAdmin) {
            return Center(
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
                    'You do not have permission to view orders.',
                    style: GoogleFonts.poppins(
                      color: colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          final ordersStream = isSuperAdmin
              ? firebaseService.watchAllOrders()
              : firebaseService.watchAssignedOrdersForAdmin();

          return StreamBuilder<List<OrderModel>>(
            stream: ordersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final orders = snapshot.data ?? [];

              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 64,
                        color: colors.textSecondary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isSuperAdmin
                            ? 'No orders placed yet'
                            : 'No assigned orders yet',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        // ── Brand name updated ───────────────────
                        'Orders will appear here once customers\nplace fabric orders on Sakash Collection.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: colors.textSecondary,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (_, i) {
                  final order = orders[i];
                  return _AdminOrderCard(
                    order: order,
                    colors: colors,
                    isSuperAdmin: isSuperAdmin,
                    statusColor: _statusColor(order.status, colors),
                    statusTone: _statusTone(order.status),
                    firebaseService: firebaseService,
                    context: context,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ── Admin Order Card ───────────────────────────────────────────────────────────

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({
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
          const SizedBox(height: 12),

          if (order.items.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: order.items.take(2).map((item) {
                  final name = item['name'] ?? 'Fabric Item';
                  final qty = item['quantity'] ?? 1;
                  final price = (item['price'] ?? 0.0) as num;
                  final fabricType = item['fabricType'] ?? '';
                  final color = item['color'] ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colors.brandPrimary
                                .withOpacity(0.08),
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.texture_rounded,
                            size: 18,
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
                              if (fabricType.isNotEmpty ||
                                  color.isNotEmpty)
                                Text(
                                  [
                                    if (fabricType.isNotEmpty)
                                      fabricType,
                                    if (color.isNotEmpty) color,
                                  ].join(' · '),
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
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₦${price.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            if (order.items.length > 2) ...[
              const SizedBox(height: 6),
              Text(
                '+${order.items.length - 2} more item${order.items.length - 2 == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 10),
          ],

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

          if (order.deliveryAddress.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: colors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

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
                if (order.assignmentMethod.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.assignmentMethod,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Text(
            'UPDATE STATUS',
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
              _StatusBtn(
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
              _StatusBtn(
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
              _StatusBtn(
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
              _StatusBtn(
                label: 'Delivered',
                icon: Icons.check_circle_outline_rounded,
                isActive: order.status == 'delivered',
                color: Colors.green.shade600,
                colors: colors,
                onTap: () => firebaseService.updateOrderStatus(
                  orderId: order.id,
                  status: 'delivered',
                ),
              ),
              _StatusBtn(
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

          if (isSuperAdmin) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          AdminReassignmentScreen(order: order),
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
                icon:
                    const Icon(Icons.swap_horiz_rounded, size: 18),
                label: Text(
                  'Reassign Order',
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

// ── Status Button ──────────────────────────────────────────────────────────────

class _StatusBtn extends StatelessWidget {
  const _StatusBtn({
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
          color: isActive
              ? color.withOpacity(0.15)
              : colors.surfaceAlt,
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