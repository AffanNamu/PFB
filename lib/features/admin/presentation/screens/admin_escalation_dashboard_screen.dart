import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/core/constants/app_constants.dart';
import 'package:pfb/features/admin/presentation/screens/admin_reassignment_screen.dart';
import 'package:pfb/models/order_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_section_title.dart';
import 'package:pfb/shared/widgets/app_status_chip.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

// ── Admin Escalation Dashboard ─────────────────────────────────────────────────
// Orders only — no RideModel references.

class AdminEscalationDashboardScreen extends StatelessWidget {
  AdminEscalationDashboardScreen({super.key});

  final FirebaseService _firebaseService = FirebaseService();

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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSuperAdmin = AppConstants.isSuperAdminUid(
      _firebaseService.currentUser?.uid,
    );

    return AppPageScaffold(
      title: 'Escalation Dashboard',
      body: !isSuperAdmin
          ? Center(
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
                    'Super Admin Only',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Only super admins can view escalated orders.',
                    style: GoogleFonts.poppins(
                      color: colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : StreamBuilder<List<OrderModel>>(
              stream: _firebaseService.watchEscalatedOrders(),
              builder: (context, orderSnapshot) {
                final escalatedOrders = orderSnapshot.data ?? [];

                if (escalatedOrders.isEmpty) {
                  return _buildEmptyState(colors);
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Info Banner ──────────────────────────────
                    AppSurfaceCard(
                      margin: const EdgeInsets.only(bottom: 18),
                      color: colors.warning.withOpacity(0.08),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: colors.warning,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Escalated Textile Orders',
                                  style: GoogleFonts.poppins(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'These orders could not be automatically assigned to an admin and require your manual attention.',
                                  style: GoogleFonts.poppins(
                                    color: colors.textSecondary,
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Count badge ──────────────────────────────
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.error.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            color: colors.error,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${escalatedOrders.length} escalated order${escalatedOrders.length == 1 ? '' : 's'} need attention',
                            style: GoogleFonts.poppins(
                              color: colors.error,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Escalated Orders Section ─────────────────
                    const AppSectionTitle(
                      title: 'Escalated Orders',
                      spacingBottom: 12,
                    ),

                    ...escalatedOrders.map(
                      (order) => _EscalatedOrderCard(
                        order: order,
                        colors: colors,
                        statusColor: _statusColor(context, order.status),
                        firebaseService: _firebaseService,
                        context: context,
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(dynamic colors) {
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
                color: colors.success.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 48,
                color: colors.success.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'All Clear! 🎉',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No escalated orders at this time.\nAll PhlakesFabric orders are being handled.',
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

// ── Escalated Order Card ───────────────────────────────────────────────────────

class _EscalatedOrderCard extends StatelessWidget {
  const _EscalatedOrderCard({
    required this.order,
    required this.colors,
    required this.statusColor,
    required this.firebaseService,
    required this.context,
  });

  final OrderModel order;
  final dynamic colors;
  final Color statusColor;
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
          // ── Header ──────────────────────────────────────────
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
              const AppStatusChip(
                label: 'ESCALATED',
                tone: AppStatusChipTone.error,
              ),
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

          // ── Delivery address ─────────────────────────────────
          if (order.deliveryAddress.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // ── Status ───────────────────────────────────────────
          Row(
            children: [
              Text(
                'Status: ',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
              Text(
                order.status.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ── Assignment info ──────────────────────────────────
          Text(
            'Assignment Method: ${order.assignmentMethod.isEmpty ? 'Unknown' : order.assignmentMethod}',
            style: GoogleFonts.poppins(
              color: colors.textSecondary,
              fontSize: 11,
            ),
          ),

          if (order.assignedAdminName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Current Owner: ${order.assignedAdminName}',
              style: GoogleFonts.poppins(
                color: colors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],

          // ── Total ────────────────────────────────────────────
          const SizedBox(height: 8),
          Text(
            'Total: ₦${order.totalAmount.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              color: colors.brandPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── Actions ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
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
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: Text(
                    'Reassign',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await firebaseService.updateOrderStatus(
                      orderId: order.id,
                      status: 'pending',
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Order reset to pending',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: colors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(
                    'Reset',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
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
