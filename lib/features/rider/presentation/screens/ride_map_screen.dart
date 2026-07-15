// ── PhlakesFabric — Order Delivery Map Screen ─────────────────────────────────────
// Replaces the old ride_map_screen.dart
// Now shows a live-updating order delivery address map.
// No longer listens to the rides collection.
// Listens to the orders collection for delivery address changes.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:pfb/core/constants/app_constants.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/models/order_model.dart';
import 'package:pfb/shared/widgets/app_status_chip.dart';

class RideMapScreen extends StatefulWidget {
  // ── Class name kept as RideMapScreen for backward compatibility ───────────────
  final OrderModel order;

  const RideMapScreen({
    super.key,
    required this.order,
  });

  @override
  State<RideMapScreen> createState() => _RideMapScreenState();
}

class _RideMapScreenState extends State<RideMapScreen> {
  // Nigeria center as fallback
  static const _nigeriaCenter = LatLng(9.0820, 8.6753);

  LatLngBounds? _boundsFor(List<LatLng> points) {
    if (points.isEmpty) return null;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

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
    final colors = AppTheme.colorsOf(context);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.ordersCollection)
          .doc(widget.order.id)
          .snapshots(),
      builder: (context, snapshot) {
        // Use live data if available, fall back to initial order
        final data = snapshot.data?.data();
        final order = data != null
            ? OrderModel.fromMap(widget.order.id, data)
            : widget.order;

        // For now we show warehouse (Nigeria center) → delivery address
        // A future enhancement can geocode the delivery address to get coords
        const warehousePoint = _nigeriaCenter;

        final allPoints = <LatLng>[warehousePoint];
        final bounds = _boundsFor(allPoints);

        return Scaffold(
          backgroundColor: colors.scaffold,
          appBar: AppBar(
            title: Text(
              'Order #${order.shortId} — Delivery Map',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          body: Column(
            children: [
              // ── Map ──────────────────────────────────────────────
              Expanded(
                flex: 3,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: warehousePoint,
                    initialZoom: 6,
                    initialCameraFit: bounds != null
                        ? CameraFit.bounds(
                            bounds: bounds,
                            padding: const EdgeInsets.all(40),
                          )
                        : null,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.maamahsmix.app',
                    ),
                    MarkerLayer(
                      markers: [
                        // Warehouse/origin
                        Marker(
                          point: warehousePoint,
                          width: 52,
                          height: 52,
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.brandPrimary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.brandPrimary
                                      .withOpacity(0.4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.store_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Order Info Panel ─────────────────────────────────
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    border: Border(
                      top: BorderSide(color: colors.borderSoft),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Order #${order.shortId}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            AppStatusChip(
                              label: order.status.toUpperCase(),
                              tone: _statusTone(order.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Delivery address
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: colors.success,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delivering To',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: colors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    order.deliveryAddress.isNotEmpty
                                        ? order.deliveryAddress
                                        : 'Address not specified',
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
                        const SizedBox(height: 10),

                        // Items summary
                        Row(
                          children: [
                            Icon(
                              Icons.texture_rounded,
                              size: 16,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${order.items.length} fabric item${order.items.length == 1 ? '' : 's'}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: colors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '₦${order.totalAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: colors.brandPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Date
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              order.formattedDate,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),

                        // Assigned admin
                        if (order.assignedAdminName.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 14,
                                color: colors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Handled by: ${order.assignedAdminName}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
