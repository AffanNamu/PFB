// lib/features/rider/presentation/screens/ride_estimate_map_preview_screen.dart
// ── Sakash Collection — Delivery Address Map Preview ────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:pfb/core/theme/app_theme.dart';

class DeliveryAddressPreview {
  final String warehouseLabel;
  final String deliveryLabel;
  final double warehouseLat;
  final double warehouseLng;
  final double deliveryLat;
  final double deliveryLng;

  const DeliveryAddressPreview({
    required this.warehouseLabel,
    required this.deliveryLabel,
    required this.warehouseLat,
    required this.warehouseLng,
    required this.deliveryLat,
    required this.deliveryLng,
  });
}

class RideEstimateMapPreviewScreen extends StatelessWidget {
  final DeliveryAddressPreview preview;
  final String title;

  const RideEstimateMapPreviewScreen({
    super.key,
    required this.preview,
    this.title = 'Delivery Route Preview',
  });

  LatLngBounds? _boundsFor(List<LatLng> points) {
    if (points.isEmpty) return null;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    final warehouse = LatLng(
      preview.warehouseLat,
      preview.warehouseLng,
    );
    final delivery = LatLng(
      preview.deliveryLat,
      preview.deliveryLng,
    );

    final points = [warehouse, delivery];
    final bounds = _boundsFor(points);

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Map ──────────────────────────────────────────
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: warehouse,
                initialZoom: 7,
                initialCameraFit: bounds != null
                    ? CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(48),
                      )
                    : null,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.maamahsmix.app',
                ),
                MarkerLayer(
                  markers: [
                    // ── Warehouse/Origin marker ────────────
                    Marker(
                      point: warehouse,
                      width: 48,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          // ── Gold gradient marker ─────────
                          gradient: const LinearGradient(
                            colors: [
                              AppPalette.primaryDark,
                              AppPalette.primary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppPalette.primary
                                  .withOpacity(0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.store_rounded,
                          // ── Black icon on gold ───────────
                          color: AppPalette.secondary,
                          size: 22,
                        ),
                      ),
                    ),
                    // ── Delivery destination marker ────────
                    Marker(
                      point: delivery,
                      width: 48,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.success
                                  .withOpacity(0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.home_rounded,
                          // ── White ok on success green ─────
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Info Panel ────────────────────────────────────
          Container(
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _LegendDot(
                        color: colors.brandPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            // ── Brand name updated ─────────
                            'Sakash Collection Warehouse',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            preview.warehouseLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _LegendDot(color: colors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Delivery Address',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            preview.deliveryLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.brandPrimary
                        .withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.brandPrimary
                          .withOpacity(0.20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 18,
                        color: colors.brandPrimary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your fabric order will be dispatched from our warehouse to your address.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: colors.brandPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}