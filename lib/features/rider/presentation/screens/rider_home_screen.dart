// lib/features/rider/presentation/screens/rider_home_screen.dart
// ── Sakash Collection — Order Tracking Home Screen ──────────────────────────────

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/features/auth/presentation/screens/login_screen.dart';
import 'package:pfb/features/rider/presentation/screens/ride_detail_screen.dart';
import 'package:pfb/features/rider/presentation/screens/ride_map_screen.dart';
import 'package:pfb/models/order_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_status_chip.dart';

class RiderHomeScreen extends StatelessWidget {
  const RiderHomeScreen({super.key});

  bool get _isGuest =>
      FirebaseAuth.instance.currentUser == null;

  @override
  Widget build(BuildContext context) {
    final colors          = AppTheme.colorsOf(context);
    final firebaseService = FirebaseService();

    if (_isGuest) {
      return _GuestOrdersState(colors: colors);
    }

    return StreamBuilder<List<OrderModel>>(
      stream: firebaseService.watchOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: colors.scaffold,
            body: const Center(
                child: CircularProgressIndicator()),
          );
        }

        final orders       = snapshot.data ?? [];
        final activeOrders =
            orders.where((o) => o.isActive).toList();
        final pastOrders   =
            orders.where((o) => !o.isActive).toList();

        if (orders.isEmpty) {
          return Scaffold(
            backgroundColor: colors.scaffold,
            body: _EmptyOrdersState(colors: colors),
          );
        }

        return Scaffold(
          backgroundColor: colors.scaffold,
          body: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(
                      16, 16, 16, 8),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    // ── Gold gradient header ─────────────────
                    gradient: const LinearGradient(
                      colors: [
                        AppPalette.primaryDark,
                        AppPalette.primary,
                        AppPalette.primaryLight,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_shipping_rounded,
                        // ── Black icon on gold ───────────────
                        color: AppPalette.secondary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Orders',
                              style: GoogleFonts
                                  .playfairDisplay(
                                // ── Black text on gold ───────
                                color: AppPalette.secondary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${orders.length} total · ${activeOrders.length} active',
                              style: GoogleFonts.poppins(
                                color: AppPalette.secondary
                                    .withOpacity(0.65),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Active Orders ──────────────────────────────
              if (activeOrders.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        16, 12, 16, 8),
                    child: _SectionHeader(
                      title: 'Active Orders',
                      count: activeOrders.length,
                      colors: colors,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _OrderCard(
                        order: activeOrders[i],
                        colors: colors,
                        onTap: () =>
                            Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                RideDetailScreen(
                              order: activeOrders[i],
                            ),
                          ),
                        ),
                        onOpenMap: () =>
                            Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RideMapScreen(
                              order: activeOrders[i],
                            ),
                          ),
                        ),
                      ),
                      childCount: activeOrders.length,
                    ),
                  ),
                ),
              ],

              // ── Past Orders ────────────────────────────────
              if (pastOrders.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        16, 16, 16, 8),
                    child: _SectionHeader(
                      title: 'Order History',
                      count: pastOrders.length,
                      colors: colors,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _OrderCard(
                        order: pastOrders[i],
                        colors: colors,
                        onTap: () =>
                            Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                RideDetailScreen(
                              order: pastOrders[i],
                            ),
                          ),
                        ),
                      ),
                      childCount: pastOrders.length,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Order Card ─────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.colors,
    required this.onTap,
    this.onOpenMap,
  });

  final OrderModel   order;
  final dynamic      colors;
  final VoidCallback onTap;
  final VoidCallback? onOpenMap;

  AppStatusChipTone _statusTone() {
    switch (order.status.toLowerCase()) {
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.borderSoft),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
                    color: colors.brandPrimary
                        .withOpacity(0.10),
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
                  tone: _statusTone(),
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
            const SizedBox(height: 10),

            if (order.deliveryAddress.isNotEmpty)
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
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
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 8),

            if (order.items.isNotEmpty)
              Text(
                order.items
                    .take(2)
                    .map((item) =>
                        item['name'] ?? 'Item')
                    .join(', '),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 8),

            Row(
              children: [
                Text(
                  '₦${order.totalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.brandPrimary,
                  ),
                ),
                const Spacer(),
                if (onOpenMap != null && order.isActive)
                  GestureDetector(
                    onTap: onOpenMap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.brandPrimary
                            .withOpacity(0.10),
                        borderRadius:
                            BorderRadius.circular(8),
                        border: Border.all(
                          color: colors.brandPrimary
                              .withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 14,
                            color: colors.brandPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Track',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: colors.brandPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.colors,
  });

  final String  title;
  final int     count;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: colors.brandPrimary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color:
                colors.brandPrimary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.brandPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Empty Orders State ─────────────────────────────────────────────────────────

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState({required this.colors});
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color:
                    colors.brandPrimary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 56,
                color:
                    colors.brandPrimary.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Orders Yet',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              // ── Brand name updated ───────────────────────
              'Your Sakash Collection orders will appear here.\nStart shopping for your favourite items!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                '🧕 Abayas',
                '🧣 Hijabs',
                '👜 Bags',
                '💍 Accessories',
              ].map((label) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.brandPrimary
                        .withOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.brandPrimary
                          .withOpacity(0.20),
                    ),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: colors.brandPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Guest Orders State ─────────────────────────────────────────────────────────

class _GuestOrdersState extends StatelessWidget {
  const _GuestOrdersState({required this.colors});
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.scaffold,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color:
                      colors.brandPrimary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 56,
                  color:
                      colors.brandPrimary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sign In to Track Orders',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                // ── Brand name updated ─────────────────────
                'Create an account or sign in to track your\nSakash Collection deliveries in real time.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: colors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(
                          redirectTo:
                              RouteNames.redirectOrders,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.brandPrimary,
                    // ── Black text on gold button ──────────
                    foregroundColor: AppPalette.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.login_rounded),
                  label: Text(
                    'Sign In / Create Account',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}