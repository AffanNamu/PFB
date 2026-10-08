// lib/features/orders/presentation/screens/order_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:pfb/models/order_model.dart';
import 'package:pfb/services/firebase_service.dart';

class OrderScreen extends StatelessWidget {
  final bool showScaffold;

  OrderScreen({super.key, this.showScaffold = true});

  final firebaseService = FirebaseService();

  Color _statusColor(String status, dynamic colors) {
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
        return Icons.sync_rounded;
      case 'shipped':
        return Icons.local_shipping_outlined;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    final content = StreamBuilder<List<OrderModel>>(
      stream: firebaseService.watchOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator());
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: colors.brandPrimary
                          .withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: colors.brandPrimary
                          .withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No orders yet',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    // ── Brand name updated ───────────────
                    'Your Sakash Collection orders will appear here once you place them.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (_, i) {
            final order = orders[i];

            final statusColor =
                _statusColor(order.status, colors);
            final statusIcon =
                _statusIcon(order.status);

            final shortId = order.id.length > 12
                ? '#${order.id.substring(0, 12).toUpperCase()}'
                : '#${order.id.toUpperCase()}';

            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        OrderDetailScreen(order: order),
                  ),
                );
              },
              child: Container(
                margin:
                    const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                      color: colors.borderSoft),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: statusColor
                                  .withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(
                                      14),
                            ),
                            child: Icon(
                              statusIcon,
                              color: statusColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  shortId,
                                  style:
                                      GoogleFonts.poppins(
                                    fontWeight:
                                        FontWeight.w700,
                                    color:
                                        colors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  // ── Brand updated ──────
                                  '${order.items.length} item${order.items.length == 1 ? '' : 's'} · Sakash Collection',
                                  style:
                                      GoogleFonts.poppins(
                                    color: colors
                                        .textSecondary,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₦${order.totalAmount.toStringAsFixed(2)}',
                                style:
                                    GoogleFonts.poppins(
                                  fontWeight:
                                      FontWeight.w800,
                                  color:
                                      colors.brandPrimary,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor
                                      .withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius
                                          .circular(20),
                                ),
                                child: Text(
                                  order.status
                                      .toUpperCase(),
                                  style:
                                      GoogleFonts.poppins(
                                    color: statusColor,
                                    fontSize: 9.5,
                                    fontWeight:
                                        FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (order.deliveryAddress
                        .isNotEmpty) ...[
                      Divider(
                          height: 1,
                          color: colors.borderSoft),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                order.deliveryAddress,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color:
                                      colors.textSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!showScaffold) {
      return Scaffold(
        backgroundColor: colors.scaffold,
        body: SafeArea(child: content),
      );
    }

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.receipt_long_rounded,
                color: colors.brandPrimary, size: 22),
            const SizedBox(width: 8),
            Text(
              'My Orders',
              style: GoogleFonts.poppins(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: content,
    );
  }
}