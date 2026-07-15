import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/features/shared/presentation/widgets/premium_location_picker_bottom_sheet.dart';
import 'package:pfb/models/place_suggestion_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_bottom_sheets.dart';
import 'package:pfb/shared/widgets/app_form_field.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_section_title.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

class ManageAdminLocationsScreen extends StatefulWidget {
  const ManageAdminLocationsScreen({super.key});

  @override
  State<ManageAdminLocationsScreen> createState() =>
      _ManageAdminLocationsScreenState();
}

class _ManageAdminLocationsScreenState
    extends State<ManageAdminLocationsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _radiusCtrl = TextEditingController(text: '30');
  final _areasCtrl = TextEditingController();
  final _maxLoadCtrl = TextEditingController(text: '20');

  // ── Vendor Pickup Address ────────────────────────────────────────────────────

  Future<void> _changeVendorAddress(String currentAddress) async {
    final result =
        await AppBottomSheets.showSheet<PlaceSuggestionModel>(
      context: context,
      isScrollControlled: true,
      child: PremiumLocationPickerBottomSheet(
        title: 'Set PhlakesFabric Warehouse / Pickup Location',
        hintText:
            'Search fabric warehouse or shop location in Nigeria',
        initialValue: currentAddress,
      ),
    );

    if (result == null || result.displayName.trim().isEmpty) return;

    await _firebaseService
        .updateVendorPickupAddress(result.displayName);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Warehouse/pickup location updated',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: context.appColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ── Admin Base Location ──────────────────────────────────────────────────────

  Future<void> _setMyAdminBase(
    List<String> existingStates,
    bool currentActive,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final result =
        await AppBottomSheets.showSheet<PlaceSuggestionModel>(
      context: context,
      isScrollControlled: true,
      child: const PremiumLocationPickerBottomSheet(
        title: 'Set My Admin Base Location',
        hintText:
            'Search your admin operating location in Nigeria',
      ),
    );

    if (result == null || result.displayName.trim().isEmpty) return;

    final radius =
        double.tryParse(_radiusCtrl.text.trim()) ?? 30;
    final maxLoad =
        int.tryParse(_maxLoadCtrl.text.trim()) ?? 20;
    final areas = _areasCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    await _firebaseService.updateAdminCoverage(
      adminUid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? (user.email ?? 'Admin'),
      baseAddress: result.displayName,
      baseLat: result.latitude,
      baseLng: result.longitude,
      serviceRadiusKm: radius,
      coverageStates: existingStates,
      coverageAreas: areas,
    );

    await _firebaseService.updateAdminWorkloadConfig(
      adminUid: user.uid,
      isActive: currentActive,
      maxActiveAssignments: maxLoad,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Admin coverage location updated successfully',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: context.appColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _toggleAdminActive(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final maxLoad =
        int.tryParse(_maxLoadCtrl.text.trim()) ?? 20;

    await _firebaseService.updateAdminWorkloadConfig(
      adminUid: user.uid,
      isActive: value,
      maxActiveAssignments: maxLoad,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? '✅ You are now active for order assignments'
              : '⏸ You are paused from new assignments',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: value
            ? context.appColors.success
            : context.appColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _saveWorkloadOnly(bool currentActive) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final maxLoad =
        int.tryParse(_maxLoadCtrl.text.trim()) ?? 20;

    await _firebaseService.updateAdminWorkloadConfig(
      adminUid: user.uid,
      isActive: currentActive,
      maxActiveAssignments: maxLoad,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Workload settings saved',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: context.appColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _firebaseService.seedDefaultAppSettings();
  }

  @override
  void dispose() {
    _radiusCtrl.dispose();
    _areasCtrl.dispose();
    _maxLoadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final currentUser = FirebaseAuth.instance.currentUser;

    return AppPageScaffold(
      title: 'Admin Locations',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Vendor Pickup Location ─────────────────────────────
          StreamBuilder<String>(
            stream: _firebaseService.watchVendorPickupAddress(),
            builder: (context, snapshot) {
              final vendorAddress =
                  snapshot.data ?? 'Not set — tap to configure';

              return AppSurfaceCard(
                margin: const EdgeInsets.only(bottom: 16),
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                colors.brandPrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.store_rounded,
                            color: colors.brandPrimary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PhlakesFabric Warehouse / Pickup',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'The origin address for all fabric deliveries',
                                style: GoogleFonts.poppins(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: colors.borderSoft),
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
                            child: Text(
                              vendorAddress,
                              style: GoogleFonts.poppins(
                                color: colors.textPrimary,
                                height: 1.4,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _changeVendorAddress(vendorAddress),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.brandPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                        ),
                        icon: const Icon(
                            Icons.edit_location_alt_rounded,
                            size: 18),
                        label: Text(
                          'Update Pickup Location',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── My Admin Coverage ──────────────────────────────────
          if (currentUser != null)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firebaseService.watchAdmins(),
              builder: (context, snapshot) {
                final admins = snapshot.data ?? [];
                Map<String, dynamic>? me;

                try {
                  me = admins
                      .firstWhere((a) => a['uid'] == currentUser.uid);
                } catch (_) {
                  me = null;
                }

                final myBaseAddress =
                    (me?['baseAddress'] ?? '').toString();
                final myRadius =
                    ((me?['serviceRadiusKm'] ?? 30) as num)
                        .toDouble();
                final myStates = List<String>.from(
                    me?['coverageStates'] ?? []);
                final myAreas =
                    List<String>.from(me?['coverageAreas'] ?? []);
                final myActive =
                    (me?['isActive'] ?? true) == true;
                final myMaxLoad =
                    ((me?['maxActiveAssignments'] ?? 20) as num)
                        .toInt();

                // Sync controllers
                if (_radiusCtrl.text.trim().isEmpty ||
                    _radiusCtrl.text == '30') {
                  _radiusCtrl.text =
                      myRadius.toStringAsFixed(0);
                }
                if (_areasCtrl.text.trim().isEmpty &&
                    myAreas.isNotEmpty) {
                  _areasCtrl.text = myAreas.join(', ');
                }
                if (_maxLoadCtrl.text.trim().isEmpty ||
                    _maxLoadCtrl.text == '20') {
                  _maxLoadCtrl.text = myMaxLoad.toString();
                }

                return AppSurfaceCard(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.brandPrimary
                                  .withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.my_location_rounded,
                              color: colors.brandPrimary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Admin Coverage',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Orders near your base are auto-assigned to you',
                                  style: GoogleFonts.poppins(
                                    color: colors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Current base
                      if (myBaseAddress.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.brandPrimary
                                .withOpacity(0.06),
                            borderRadius:
                                BorderRadius.circular(14),
                            border: Border.all(
                              color: colors.brandPrimary
                                  .withOpacity(0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.home_work_outlined,
                                    size: 14,
                                    color: colors.brandPrimary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'My Base',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: colors.brandPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                myBaseAddress,
                                style: GoogleFonts.poppins(
                                  color: colors.textPrimary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              if (myStates.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: myStates.map((s) {
                                    return Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.brandPrimary
                                            .withOpacity(0.10),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        s,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: colors.brandPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Active toggle
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: myActive
                              ? colors.success.withOpacity(0.06)
                              : colors.warning.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: myActive
                                ? colors.success.withOpacity(0.25)
                                : colors.warning.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              myActive
                                  ? Icons.check_circle_rounded
                                  : Icons.pause_circle_rounded,
                              color: myActive
                                  ? colors.success
                                  : colors.warning,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    myActive
                                        ? 'Active for Assignments'
                                        : 'Paused from Assignments',
                                    style: GoogleFonts.poppins(
                                      color: myActive
                                          ? colors.success
                                          : colors.warning,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    myActive
                                        ? 'New textile orders will be assigned to you'
                                        : 'Turn on to receive order assignments',
                                    style: GoogleFonts.poppins(
                                      color: colors.textSecondary,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: myActive,
                              onChanged: _toggleAdminActive,
                              activeColor: colors.success,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Settings fields
                      AppFormField(
                        controller: _radiusCtrl,
                        hintText: 'Service radius in km (e.g. 30)',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      AppFormField(
                        controller: _areasCtrl,
                        hintText:
                            'Coverage areas (comma separated)\ne.g. Ikeja, Yaba, Lekki',
                      ),
                      const SizedBox(height: 12),
                      AppFormField(
                        controller: _maxLoadCtrl,
                        hintText:
                            'Maximum active order assignments (e.g. 20)',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Action buttons
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _setMyAdminBase(myStates, myActive),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.brandPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                          ),
                          icon: const Icon(
                              Icons.my_location_rounded,
                              size: 18),
                          label: Text(
                            'Set My Base Location',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () =>
                              _saveWorkloadOnly(myActive),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.brandPrimary,
                            side: BorderSide(
                              color: colors.brandPrimary
                                  .withOpacity(0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                          ),
                          child: Text(
                            'Save Workload Settings Only',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
