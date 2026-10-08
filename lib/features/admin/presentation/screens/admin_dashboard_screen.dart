// lib/features/admin/presentation/screens/admin_dashboard_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pfb/config/routes/route_names.dart';
import 'package:pfb/core/constants/app_constants.dart';
import 'package:pfb/core/routing/app_router.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/core/theme/theme_scope.dart';
import 'package:pfb/features/admin/presentation/screens/add_product_screen.dart';
import 'package:pfb/features/admin/presentation/screens/admin_escalation_dashboard_screen.dart';
import 'package:pfb/features/admin/presentation/screens/admin_orders_screen.dart';
import 'package:pfb/features/admin/presentation/screens/admin_rides_screen.dart';
import 'package:pfb/features/admin/presentation/screens/edit_product_screen.dart';
import 'package:pfb/features/admin/presentation/screens/manage_admin_locations_screen.dart';
import 'package:pfb/features/admin/presentation/screens/manage_categories_screen.dart';
import 'package:pfb/features/admin/presentation/screens/manage_products_screen.dart';
import 'package:pfb/features/admin/presentation/screens/payment_settings_screen.dart';
import 'package:pfb/features/admin/presentation/screens/super_admin_analytics_screen.dart';
import 'package:pfb/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:pfb/features/pos/presentation/screens/pos_dashboard_screen.dart';
import 'package:pfb/features/products/presentation/screens/product_detail_screen.dart';
import 'package:pfb/models/app_notification_model.dart';
import 'package:pfb/models/product_model.dart';
import 'package:pfb/services/admin_preview_scope.dart';
import 'package:pfb/services/firebase_auth_service.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/services/notification_navigation_service.dart';

// ── Admin Role Enum ────────────────────────────────────────────────────────────

enum AdminRole {
  cashier,
  storeManager,
  admin,
  superAdmin;

  String get label {
    switch (this) {
      case AdminRole.cashier:
        return 'Cashier';
      case AdminRole.storeManager:
        return 'Store Manager';
      case AdminRole.admin:
        return 'Admin';
      case AdminRole.superAdmin:
        return 'Super Admin';
    }
  }

  String get firestoreValue {
    switch (this) {
      case AdminRole.cashier:
        return 'cashier';
      case AdminRole.storeManager:
        return 'store_manager';
      case AdminRole.admin:
        return 'admin';
      case AdminRole.superAdmin:
        return 'super_admin';
    }
  }

  static AdminRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'cashier':
        return AdminRole.cashier;
      case 'store_manager':
        return AdminRole.storeManager;
      case 'super_admin':
        return AdminRole.superAdmin;
      default:
        return AdminRole.admin;
    }
  }

  /// Whether this role can access POS terminal
  bool get canAccessPos =>
      this == AdminRole.cashier ||
      this == AdminRole.storeManager ||
      this == AdminRole.admin ||
      this == AdminRole.superAdmin;

  /// Whether this role can manage products
  bool get canManageProducts =>
      this == AdminRole.storeManager ||
      this == AdminRole.admin ||
      this == AdminRole.superAdmin;

  /// Whether this role can view analytics
  bool get canViewAnalytics =>
      this == AdminRole.storeManager ||
      this == AdminRole.admin ||
      this == AdminRole.superAdmin;

  /// Whether this role can manage admins
  bool get canManageAdmins => this == AdminRole.superAdmin;
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  final _authService = FirebaseAuthService();
  final _firebaseService = FirebaseService();
  final _adminNameCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();

  // ── Role assignment state ──────────────────────────────────────
  AdminRole _selectedRoleForNewAdmin = AdminRole.admin;

  bool _addingAdmin = false;
  bool _loggingOut = false;

  bool get _isSuperAdmin => AppConstants.isSuperAdminUid(
        FirebaseAuth.instance.currentUser?.uid,
      );

  bool _hasValidImage(String url) {
    final value = url.trim();
    return value.isNotEmpty &&
        (value.startsWith('http://') ||
            value.startsWith('https://'));
  }

  // ── Add Admin with Role ──────────────────────────────────────────

  Future<void> _addAdmin() async {
    final name = _adminNameCtrl.text.trim();
    final email = _adminEmailCtrl.text.trim().toLowerCase();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin name and email are required'),
        ),
      );
      return;
    }

    setState(() => _addingAdmin = true);

    try {
      final userQuery = await _firebaseService.firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'User not found. The person must create an account in the app first.',
            ),
          ),
        );
        return;
      }

      final realUid = userQuery.docs.first.id;

      // ── Write admin doc with full role assignment ──────────────
      await _firebaseService.addAdmin(
        uid: realUid,
        email: email,
      );

      await _firebaseService.firestore
          .collection(AppConstants.adminsCollection)
          .doc(realUid)
          .set(
        {
          'displayName': name,
          'role': _selectedRoleForNewAdmin.firestoreValue,
          'roleName': _selectedRoleForNewAdmin.label,
          'canAccessPos': _selectedRoleForNewAdmin.canAccessPos,
          'canManageProducts':
              _selectedRoleForNewAdmin.canManageProducts,
          'canViewAnalytics':
              _selectedRoleForNewAdmin.canViewAnalytics,
          'assignedBy':
              _firebaseService.currentUser?.uid ?? '',
          'assignedByEmail':
              _firebaseService.currentUser?.email ?? '',
          'roleAssignedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );

      _adminNameCtrl.clear();
      _adminEmailCtrl.clear();
      setState(() =>
          _selectedRoleForNewAdmin = AdminRole.admin);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Success! $name is now a ${_selectedRoleForNewAdmin.label}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _addingAdmin = false);
    }
  }

  // ── Update existing admin role ──────────────────────────────────

  Future<void> _updateAdminRole(
    String adminUid,
    String adminName,
    AdminRole newRole,
  ) async {
    try {
      await _firebaseService.firestore
          .collection(AppConstants.adminsCollection)
          .doc(adminUid)
          .set(
        {
          'role': newRole.firestoreValue,
          'roleName': newRole.label,
          'canAccessPos': newRole.canAccessPos,
          'canManageProducts': newRole.canManageProducts,
          'canViewAnalytics': newRole.canViewAnalytics,
          'roleUpdatedBy':
              _firebaseService.currentUser?.uid ?? '',
          'roleUpdatedAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$adminName role updated to ${newRole.label}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role update failed: $e')),
      );
    }
  }

  Future<void> _switchToUserView() async {
    AdminPreviewScope.of(context).enterPreviewMode();
    if (!mounted) return;
    await AppRouter.clearAndGo(context, RouteNames.mainShell);
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            final colors = AppTheme.colorsOf(dialogContext);
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Log out?',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              content: Text(
                'You are about to sign out of the Sakash Collection admin account.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.5,
                  color: colors.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(true),
                  child: Text(
                    'Log out',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldLogout || !mounted) return;

    setState(() => _loggingOut = true);

    try {
      AdminPreviewScope.of(context).reset();
      await _authService.signOut();
      if (!mounted) return;
      await AppRouter.clearAndGo(context, RouteNames.login);
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _firebaseService.seedDefaultCategoriesIfMissingSafely();
    _firebaseService.seedDefaultAppSettingsSafely();
  }

  @override
  void dispose() {
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    super.dispose();
  }

  // ── Stats Section ─────────────────────────────────────────────────

  Widget _buildStatsSection() {
    final colors = AppTheme.colorsOf(context);

    if (_isSuperAdmin) {
      return Column(
        children: [
          StreamBuilder<int>(
            stream: _firebaseService.watchProductsCount(),
            builder: (context, pSnap) {
              return StreamBuilder<int>(
                stream: _firebaseService.watchOrdersCount(),
                builder: (context, oSnap) {
                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Products',
                          value: '${pSnap.data ?? 0}',
                          icon: Icons.texture_rounded,
                          color: colors.brandPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Total Orders',
                          value: '${oSnap.data ?? 0}',
                          icon: Icons.receipt_long_rounded,
                          color: colors.warning,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          StreamBuilder<int>(
            stream: _firebaseService.watchAdminsCount(),
            builder: (context, aSnap) {
              return StreamBuilder<int>(
                stream: _firebaseService
                    .watchAssignedActiveWorkloadCount(),
                builder: (context, wSnap) {
                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Admins',
                          value: '${aSnap.data ?? 1}',
                          icon:
                              Icons.admin_panel_settings_rounded,
                          color: colors.info,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Escalated',
                          value: '${wSnap.data ?? 0}',
                          icon: Icons.warning_amber_rounded,
                          color: colors.error,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      );
    }

    return Column(
      children: [
        StreamBuilder<List<ProductModel>>(
          stream: _firebaseService.watchMyUploadedProducts(),
          builder: (context, productsSnap) {
            return StreamBuilder<int>(
              stream: _firebaseService.watchAssignedOrdersCount(),
              builder: (context, ordersSnap) {
                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'My Products',
                        value:
                            '${productsSnap.data?.length ?? 0}',
                        icon: Icons.texture_rounded,
                        color: colors.brandPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Assigned Orders',
                        value: '${ordersSnap.data ?? 0}',
                        icon: Icons.receipt_long_rounded,
                        color: colors.warning,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 12),
        StreamBuilder<int>(
          stream:
              _firebaseService.watchAssignedActiveWorkloadCount(),
          builder: (context, workloadSnap) {
            return Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Active Workload',
                    value: '${workloadSnap.data ?? 0}',
                    icon: Icons.bolt_rounded,
                    color: colors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Platform',
                    value: 'S',
                    icon: Icons.storefront_rounded,
                    color: colors.brandPrimary,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ── Role Selector Widget ──────────────────────────────────────────

  Widget _buildRoleSelector(AppThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign Role',
          style: GoogleFonts.poppins(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // Role options — exclude superAdmin from assignment UI
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AdminRole.cashier,
            AdminRole.storeManager,
            AdminRole.admin,
          ].map((role) {
            final isSelected = _selectedRoleForNewAdmin == role;
            return GestureDetector(
              onTap: () =>
                  setState(() => _selectedRoleForNewAdmin = role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.brandPrimary
                      : colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? colors.brandPrimary
                        : colors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _roleIcon(role),
                      size: 14,
                      color: isSelected
                          ? Colors.black
                          : colors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      role.label,
                      style: GoogleFonts.poppins(
                        color: isSelected
                            ? Colors.black
                            : colors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Role description
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.goldTint,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: colors.brandPrimary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedRoleForNewAdmin.label,
                style: GoogleFonts.poppins(
                  color: colors.brandPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _roleDescription(_selectedRoleForNewAdmin),
                style: GoogleFonts.poppins(
                  color: colors.textSecondary,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _roleIcon(AdminRole role) {
    switch (role) {
      case AdminRole.cashier:
        return Icons.point_of_sale_rounded;
      case AdminRole.storeManager:
        return Icons.store_rounded;
      case AdminRole.admin:
        return Icons.admin_panel_settings_rounded;
      case AdminRole.superAdmin:
        return Icons.security_rounded;
    }
  }

  String _roleDescription(AdminRole role) {
    switch (role) {
      case AdminRole.cashier:
        return 'Can access POS terminal to process walk-in sales. Cannot manage products or view analytics.';
      case AdminRole.storeManager:
        return 'Can access POS terminal, manage products, categories, and view store analytics.';
      case AdminRole.admin:
        return 'Full admin access — POS, products, orders, deliveries, categories and analytics.';
      case AdminRole.superAdmin:
        return 'Complete platform control including admin management and all analytics.';
    }
  }

  // ── Admin List with Role Badges ───────────────────────────────────

  Widget _buildAdminList(AppThemeColors colors) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseService.watchAdmins(),
      builder: (context, snapshot) {
        final admins = snapshot.data ?? [];
        if (admins.isEmpty) {
          return Text(
            'No extra admins yet',
            style: GoogleFonts.poppins(
              color: colors.textSecondary,
            ),
          );
        }

        return Column(
          children: admins.map((admin) {
            final uid = (admin['uid'] ?? '').toString();
            final name = (admin['displayName'] ??
                    admin['email'] ??
                    '')
                .toString();
            final email =
                (admin['email'] ?? '').toString();
            final role = AdminRole.fromString(
              admin['role']?.toString(),
            );
            final initial = name.isNotEmpty
                ? name[0].toUpperCase()
                : 'A';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: colors.borderSoft),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: colors.brandPrimary
                            .withOpacity(0.15),
                        child: Text(
                          initial,
                          style: GoogleFonts.poppins(
                            color: colors.brandPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Name + email
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              email,
                              style: GoogleFonts.poppins(
                                color: colors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _roleBadgeColor(role)
                              .withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color: _roleBadgeColor(role)
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          role.label,
                          style: GoogleFonts.poppins(
                            color: _roleBadgeColor(role),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Permission chips
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (role.canAccessPos)
                        _permissionChip(
                          'POS',
                          Icons.point_of_sale_rounded,
                          colors.info,
                          colors,
                        ),
                      if (role.canManageProducts)
                        _permissionChip(
                          'Products',
                          Icons.texture_rounded,
                          colors.success,
                          colors,
                        ),
                      if (role.canViewAnalytics)
                        _permissionChip(
                          'Analytics',
                          Icons.analytics_rounded,
                          colors.brandPrimary,
                          colors,
                        ),
                      if (role.canManageAdmins)
                        _permissionChip(
                          'Admins',
                          Icons.security_rounded,
                          colors.error,
                          colors,
                        ),
                    ],
                  ),

                  // Role update dropdown (super admin only)
                  if (_isSuperAdmin && uid.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Change role:',
                          style: GoogleFonts.poppins(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 36,
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius:
                                  BorderRadius.circular(8),
                              border: Border.all(
                                  color: colors.border),
                            ),
                            child:
                                DropdownButtonHideUnderline(
                              child:
                                  DropdownButton<AdminRole>(
                                value: role,
                                isExpanded: true,
                                dropdownColor:
                                    colors.surfaceAlt,
                                style: GoogleFonts.poppins(
                                  color: colors.textPrimary,
                                  fontSize: 12,
                                ),
                                iconEnabledColor:
                                    colors.iconPrimary,
                                items: [
                                  AdminRole.cashier,
                                  AdminRole.storeManager,
                                  AdminRole.admin,
                                ].map((r) {
                                  return DropdownMenuItem(
                                    value: r,
                                    child: Text(r.label),
                                  );
                                }).toList(),
                                onChanged: (newRole) {
                                  if (newRole == null ||
                                      newRole == role) {
                                    return;
                                  }
                                  _updateAdminRole(
                                    uid,
                                    name,
                                    newRole,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Color _roleBadgeColor(AdminRole role) {
    switch (role) {
      case AdminRole.cashier:
        return AppPalette.info;
      case AdminRole.storeManager:
        return AppPalette.success;
      case AdminRole.admin:
        return AppPalette.primary;
      case AdminRole.superAdmin:
        return AppPalette.error;
    }
  }

  Widget _permissionChip(
    String label,
    IconData icon,
    Color color,
    AppThemeColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.of(context);
    final colors = AppTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.brandPrimaryDark,
                    colors.brandPrimary,
                    colors.brandPrimaryLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color:
                        colors.brandPrimary.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'S',
                style: GoogleFonts.cinzel(
                  color: AppPalette.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSuperAdmin
                        ? 'Super Admin Dashboard'
                        : 'Admin Dashboard',
                    style: GoogleFonts.poppins(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _isSuperAdmin
                        ? 'Full platform control — Sakash Collection'
                        : 'Manage your products & assigned orders',
                    style: GoogleFonts.poppins(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // ── Notifications ──────────────────────────────
          StreamBuilder<int>(
            stream:
                _firebaseService.watchUnreadNotificationCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return IconButton(
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const NotificationsScreen(),
                    ),
                  );
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      color: colors.iconPrimary,
                    ),
                    if (count > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          constraints:
                              const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppPalette.primaryDark,
                                AppPalette.primary,
                                AppPalette.primaryLight,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius:
                                BorderRadius.circular(999),
                            border: Border.all(
                              color: colors.scaffold,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              count > 99
                                  ? '99+'
                                  : '$count',
                              style: GoogleFonts.poppins(
                                color: AppPalette.secondary,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          // ── Theme Toggle ─────────────────────────────
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () => themeController.toggleDarkMode(
                !themeController.isDarkMode),
            icon: Icon(
              themeController.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: colors.iconPrimary,
            ),
          ),
          // ── User View ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton.icon(
              onPressed: _switchToUserView,
              icon: Icon(
                Icons.visibility_outlined,
                color: colors.brandPrimary,
                size: 18,
              ),
              label: Text(
                'User View',
                style: GoogleFonts.poppins(
                  color: colors.brandPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          // ── Logout ───────────────────────────────────
          IconButton(
            onPressed: _loggingOut ? null : _logout,
            icon: _loggingOut
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.iconPrimary,
                    ),
                  )
                : Icon(
                    Icons.logout_rounded,
                    color: colors.iconPrimary,
                  ),
          ),
        ],
      ),

      // ── FAB — POS Terminal ─────────────────────────────────────
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // POS FAB
          FloatingActionButton(
            heroTag: 'pos_fab',
            backgroundColor: colors.surface,
            foregroundColor: colors.brandPrimary,
            elevation: 4,
            tooltip: 'Open POS Terminal',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PosDashboardScreen(),
                ),
              );
            },
            child: const Icon(Icons.point_of_sale_rounded),
          ),
          const SizedBox(height: 12),
          // Add Product FAB
          FloatingActionButton.extended(
            heroTag: 'add_fabric_fab',
            backgroundColor: colors.brandPrimary,
            foregroundColor: AppPalette.secondary,
            elevation: 4,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AddProductScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Add Product',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),

      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Admin Mode Banner ──────────────────────
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.brandPrimary.withOpacity(0.12),
                        colors.brandPrimary.withOpacity(0.04),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colors.brandPrimary
                          .withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.brandPrimary
                              .withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons
                              .admin_panel_settings_rounded,
                          color: colors.brandPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isSuperAdmin
                                  ? 'Super Admin Mode — Sakash Collection'
                                  : 'Admin Mode — Sakash Collection',
                              style: GoogleFonts.poppins(
                                color: colors.brandPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isSuperAdmin
                                  ? 'Full control over products, orders, admins & analytics.'
                                  : 'Manage your uploaded products, categories & assigned orders.',
                              style: GoogleFonts.poppins(
                                color: colors.textSecondary,
                                fontSize: 11.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── POS Quick Access Banner ─────────────────
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const PosDashboardScreen(),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppGradients.goldHorizontal,
                      borderRadius:
                          BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: colors.brandPrimary
                              .withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black
                                .withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.point_of_sale_rounded,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'POS Terminal',
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontWeight:
                                      FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Process walk-in customer purchases',
                                style: GoogleFonts.poppins(
                                  color: Colors.black
                                      .withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.black,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Stats ─────────────────────────────────
                _buildStatsSection(),
                const SizedBox(height: 18),

                // ── Notifications Panel ──────────────────
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: colors.borderSoft),
                    boxShadow: [
                      BoxShadow(
                        color: colors.brandPrimary
                            .withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding:
                                const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: colors.brandPrimary
                                  .withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons
                                  .notifications_active_rounded,
                              color: colors.brandPrimary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Sakash Collection Notifications',
                            style: GoogleFonts.poppins(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const NotificationsScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'View All',
                              style: GoogleFonts.poppins(
                                color: colors.brandPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<
                          List<AppNotificationModel>>(
                        stream: _firebaseService
                            .watchAdminNotifications(),
                        builder: (context, snapshot) {
                          final notifications =
                              snapshot.data ?? [];
                          if (notifications.isEmpty) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.inbox_rounded,
                                    color:
                                        colors.textSecondary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'No Sakash Collection notifications yet',
                                    style:
                                        GoogleFonts.poppins(
                                      color:
                                          colors.textSecondary,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final recent = notifications
                              .take(5)
                              .toList();
                          return Column(
                            children: recent.map((n) {
                              return InkWell(
                                onTap: () async {
                                  await _firebaseService
                                      .markNotificationAsRead(
                                    n.id,
                                    recipientCollection:
                                        n.recipientCollection,
                                  );
                                  await NotificationNavigationService
                                      .instance
                                      .handlePayload({
                                    'type': n.type,
                                    'targetScreen':
                                        n.targetScreen,
                                    'targetId': n.targetId,
                                    'notificationId': n.id,
                                    'notificationCollection':
                                        n.recipientCollection,
                                  });
                                },
                                borderRadius:
                                    BorderRadius.circular(12),
                                child: Container(
                                  margin:
                                      const EdgeInsets.only(
                                          bottom: 8),
                                  padding:
                                      const EdgeInsets.all(
                                          10),
                                  decoration: BoxDecoration(
                                    color: n.isRead
                                        ? colors.surfaceAlt
                                        : colors.brandPrimary
                                            .withOpacity(0.08),
                                    borderRadius:
                                        BorderRadius.circular(
                                            12),
                                    border: Border.all(
                                      color: n.isRead
                                          ? colors.borderSoft
                                          : colors.brandPrimary
                                              .withOpacity(
                                                  0.25),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      if (!n.isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin:
                                              const EdgeInsets
                                                  .only(
                                                  right: 8),
                                          decoration:
                                              BoxDecoration(
                                            color: colors
                                                .brandPrimary,
                                            shape:
                                                BoxShape.circle,
                                          ),
                                        ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            Text(
                                              n.title,
                                              style: GoogleFonts
                                                  .poppins(
                                                color: colors
                                                    .textPrimary,
                                                fontWeight: n
                                                        .isRead
                                                    ? FontWeight
                                                        .w500
                                                    : FontWeight
                                                        .w700,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                            const SizedBox(
                                                height: 2),
                                            Text(
                                              n.body,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow
                                                      .ellipsis,
                                              style: GoogleFonts
                                                  .poppins(
                                                color: colors
                                                    .textSecondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons
                                            .chevron_right_rounded,
                                        color:
                                            colors.textSecondary,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ── Quick Actions Grid ───────────────────
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.point_of_sale_rounded,
                        title: 'POS Terminal',
                        subtitle: 'Walk-in sales',
                        isHighlighted: true,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const PosDashboardScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.add_box_outlined,
                        title: 'Add Product',
                        subtitle: 'Upload new product',
                        onTap: () =>
                            Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const AddProductScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.inventory_2_outlined,
                        title: 'Manage Products',
                        subtitle: 'Edit & delete',
                        onTap: () =>
                            Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ManageProductsScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.receipt_long_rounded,
                        title: _isSuperAdmin
                            ? 'All Orders'
                            : 'My Orders',
                        subtitle: 'Order management',
                        onTap: () =>
                            Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminOrdersScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.local_shipping_outlined,
                        title: _isSuperAdmin
                            ? 'All Deliveries'
                            : 'My Deliveries',
                        subtitle: 'Delivery tracking',
                        onTap: () =>
                            Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminRidesScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.category_outlined,
                        title: 'Categories',
                        subtitle: 'Product categories',
                        onTap: () =>
                            Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const ManageCategoriesScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: _isSuperAdmin
                            ? Icons.location_city_rounded
                            : Icons.visibility_outlined,
                        title: _isSuperAdmin
                            ? 'Locations'
                            : 'User Preview',
                        subtitle: _isSuperAdmin
                            ? 'Admin coverage'
                            : 'View as customer',
                        onTap: _isSuperAdmin
                            ? () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ManageAdminLocationsScreen(),
                                  ),
                                )
                            : _switchToUserView,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Placeholder to keep grid balanced
                    const Expanded(child: SizedBox()),
                  ],
                ),

                // ── Super Admin only ─────────────────────
                if (_isSuperAdmin) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.payments_rounded,
                          title: 'Payment',
                          subtitle: 'Payment settings',
                          onTap: () =>
                              Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const PaymentSettingsScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.visibility_outlined,
                          title: 'User Preview',
                          subtitle: 'View as customer',
                          onTap: _switchToUserView,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.warning_amber_rounded,
                          title: 'Escalations',
                          subtitle: 'Unassigned orders',
                          onTap: () =>
                              Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminEscalationDashboardScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.analytics_rounded,
                          title: 'Analytics',
                          subtitle: 'Sales & performance',
                          onTap: () =>
                              Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const SuperAdminAnalyticsScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),

                // ── Add Admin Panel (Super Admin only) ───
                if (_isSuperAdmin) ...[
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: colors.brandPrimary
                                    .withOpacity(0.12),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.person_add_rounded,
                                color: colors.brandPrimary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Add Admin',
                              style: GoogleFonts.poppins(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Name field
                        _Field(
                          controller: _adminNameCtrl,
                          hint: 'Admin Full Name',
                        ),
                        const SizedBox(height: 12),

                        // Email field
                        _Field(
                          controller: _adminEmailCtrl,
                          hint: 'Admin Email (must be a registered user)',
                        ),
                        const SizedBox(height: 14),

                        // ── Role Selector ──────────────────
                        _buildRoleSelector(colors),
                        const SizedBox(height: 14),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _addingAdmin
                                ? null
                                : _addAdmin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  colors.brandPrimary,
                              foregroundColor:
                                  AppPalette.secondary,
                              padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                            ),
                            child: _addingAdmin
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          AppPalette.secondary,
                                    ),
                                  )
                                : Text(
                                    'Add ${_selectedRoleForNewAdmin.label}',
                                    style: GoogleFonts.poppins(
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Current Admins ────────────────
                        Row(
                          children: [
                            Icon(
                              Icons.people_alt_rounded,
                              color: colors.textSecondary,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Team Members',
                              style: GoogleFonts.poppins(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Admin list with role management
                        _buildAdminList(colors),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // ── Products Section Header ──────────────
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppPalette.primaryDark,
                            AppPalette.primaryLight,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius:
                            BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'My Products',
                      style: GoogleFonts.poppins(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ]),
            ),
          ),

          // ── Products List ──────────────────────────────────────
          StreamBuilder<List<ProductModel>>(
            stream:
                _firebaseService.watchMyUploadedProducts(),
            builder: (context, snapshot) {
              final colors = AppTheme.colorsOf(context);

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                        child: CircularProgressIndicator()),
                  ),
                );
              }

              final items = snapshot.data ?? [];

              if (items.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        16, 0, 16, 24),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius:
                            BorderRadius.circular(18),
                        border: Border.all(
                            color: colors.borderSoft),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.texture_rounded,
                            color: colors.textSecondary
                                .withOpacity(0.4),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No products yet',
                            style:
                                GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap "Add Product" to upload your first\nproduct on Sakash Collection',
                            style: GoogleFonts.poppins(
                              color: colors.textSecondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = items[index];

                      return Container(
                        margin:
                            const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius:
                              BorderRadius.circular(18),
                          border: Border.all(
                              color: colors.borderSoft),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(12),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: _hasValidImage(
                                      product.imageUrl)
                                  ? Image.network(
                                      product.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __,
                                              ___) =>
                                          Container(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        child: Icon(
                                          Icons.texture_rounded,
                                          color: colors
                                              .textSecondary,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: Icon(
                                        Icons.texture_rounded,
                                        color:
                                            colors.textSecondary,
                                      ),
                                    ),
                            ),
                          ),
                          title: Text(
                            product.name,
                            style: GoogleFonts.poppins(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₦${product.price.toStringAsFixed(0)} • Stock: ${product.stockQuantity}',
                                style: GoogleFonts.poppins(
                                  color: colors.brandPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (product.fabricType !=
                                      null &&
                                  product.fabricType!
                                      .isNotEmpty)
                                Text(
                                  product.fabricType!,
                                  style: GoogleFonts.poppins(
                                    color: colors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            color: colors.surfaceAlt,
                            iconColor: colors.textSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                            onSelected: (value) async {
                              if (value == 'preview') {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailScreen(
                                      product: product,
                                    ),
                                  ),
                                );
                              } else if (value == 'edit') {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditProductScreen(
                                      product: product,
                                    ),
                                  ),
                                );
                              } else if (value == 'delete') {
                                await _firebaseService
                                    .deleteProduct(product.id);
                              } else if (value == 'pos') {
                                // Quick add to POS from product list
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const PosDashboardScreen(),
                                  ),
                                );
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'pos',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons
                                          .point_of_sale_rounded,
                                      color:
                                          colors.brandPrimary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Sell via POS',
                                      style:
                                          GoogleFonts.poppins(
                                        color:
                                            colors.brandPrimary,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'preview',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.visibility_outlined,
                                      color: colors.textPrimary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Preview',
                                      style:
                                          GoogleFonts.poppins(
                                        color:
                                            colors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      color: colors.textPrimary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Edit',
                                      style:
                                          GoogleFonts.poppins(
                                        color:
                                            colors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons
                                          .delete_outline_rounded,
                                      color: colors.error,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style:
                                          GoogleFonts.poppins(
                                        color: colors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: colors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Card ────────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle = '',
    this.isHighlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Material(
      color: isHighlighted
          ? colors.brandPrimary.withOpacity(0.08)
          : colors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isHighlighted
                  ? colors.brandPrimary.withOpacity(0.4)
                  : colors.borderSoft,
              width: isHighlighted ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? colors.brandPrimary
                      : colors.brandPrimary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isHighlighted
                      ? Colors.black
                      : colors.brandPrimary,
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
                      title,
                      style: GoogleFonts.poppins(
                        color: colors.textPrimary,
                        fontWeight: isHighlighted
                            ? FontWeight.w700
                            : FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          color: colors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Text Field ─────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.poppins(color: colors.textSecondary),
        filled: true,
        fillColor: colors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: colors.borderSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: colors.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: colors.brandPrimary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}