// lib/features/admin/presentation/screens/super_admin_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfb/core/constants/app_constants.dart';
import 'package:pfb/core/theme/app_theme.dart';
import 'package:pfb/features/admin/presentation/widgets/analytics_bar_chart_card.dart';
import 'package:pfb/features/admin/presentation/widgets/comparison_duel_card.dart';
import 'package:pfb/features/admin/presentation/widgets/performance_status_card.dart';
import 'package:pfb/features/admin/presentation/widgets/top_rank_card.dart';
import 'package:pfb/features/pos/data/models/pos_sale_model.dart';
import 'package:pfb/features/pos/data/repositories/pos_analytics_bridge.dart';
import 'package:pfb/features/pos/data/repositories/pos_repository.dart';
import 'package:pfb/models/order_model.dart';
import 'package:pfb/services/firebase_service.dart';
import 'package:pfb/shared/widgets/app_page_scaffold.dart';
import 'package:pfb/shared/widgets/app_section_title.dart';
import 'package:pfb/shared/widgets/app_surface_card.dart';
import 'package:pfb/core/theme/build_context_theme_x.dart';

enum AnalyticsRange { today, week, month, all, custom }

// ── Analytics Tab ──────────────────────────────────────────────────────────────

enum AnalyticsTab { online, physical, combined }

class SuperAdminAnalyticsScreen extends StatefulWidget {
  const SuperAdminAnalyticsScreen({super.key});

  @override
  State<SuperAdminAnalyticsScreen> createState() =>
      _SuperAdminAnalyticsScreenState();
}

class _SuperAdminAnalyticsScreenState
    extends State<SuperAdminAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final PosRepository _posRepo = PosRepository();
  final PosAnalyticsBridge _analyticsBridge =
      PosAnalyticsBridge();

  late TabController _tabController;

  AnalyticsRange _range = AnalyticsRange.all;
  DateTimeRange? _customRange;

  String _selectedState = 'All';
  String _selectedAdmin = 'All';
  String _selectedArea = 'All';

  // ── Date Helpers ────────────────────────────────────────────────

  DateTime _orderDate(OrderModel order) {
    return DateTime.tryParse(order.createdAt) ??
        DateTime(2000);
  }

  DateTime _rangeStart() {
    final now = DateTime.now();
    switch (_range) {
      case AnalyticsRange.today:
        return DateTime(now.year, now.month, now.day);
      case AnalyticsRange.week:
        return now.subtract(const Duration(days: 7));
      case AnalyticsRange.month:
        return now.subtract(const Duration(days: 30));
      case AnalyticsRange.custom:
        return _customRange?.start ?? DateTime(2000);
      case AnalyticsRange.all:
        return DateTime(2000);
    }
  }

  DateTime _rangeEnd() {
    if (_range == AnalyticsRange.custom &&
        _customRange != null) {
      return DateTime(
        _customRange!.end.year,
        _customRange!.end.month,
        _customRange!.end.day,
        23,
        59,
        59,
      );
    }
    return DateTime.now();
  }

  bool _inRange(DateTime date) {
    final start = _rangeStart();
    final end = _rangeEnd();
    return (date.isAfter(start) ||
            date.isAtSameMomentAs(start)) &&
        (date.isBefore(end) || date.isAtSameMomentAs(end));
  }

  bool _matchesOrderFilters(OrderModel order) {
    if (!_inRange(_orderDate(order))) return false;
    if (_selectedState != 'All' &&
        order.assignedAdminState != _selectedState) {
      return false;
    }
    if (_selectedAdmin != 'All' &&
        order.assignedAdminName != _selectedAdmin) {
      return false;
    }
    if (_selectedArea != 'All' &&
        order.assignedAdminArea != _selectedArea) {
      return false;
    }
    return true;
  }

  bool _matchesPosFilters(PosSaleModel sale) {
    if (!_inRange(sale.createdAt)) return false;
    return true;
  }

  // ── Analytics Computations ──────────────────────────────────────

  Map<String, double> _sumOrderTotalsByField(
    List<OrderModel> orders,
    String Function(OrderModel order) keyBuilder,
  ) {
    final map = <String, double>{};
    for (final order in orders) {
      if (order.status != 'delivered') continue;
      final key = keyBuilder(order).trim();
      if (key.isEmpty) continue;
      map[key] = (map[key] ?? 0) + order.totalAmount;
    }
    return map;
  }

  Map<String, int> _countOrdersByField(
    List<OrderModel> orders,
    String Function(OrderModel order) keyBuilder,
  ) {
    final map = <String, int>{};
    for (final order in orders) {
      final key = keyBuilder(order).trim();
      if (key.isEmpty) continue;
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  Map<String, double> _dailySalesSeries(
      List<OrderModel> orders) {
    final series = <String, double>{};
    for (final order in orders) {
      if (order.status != 'delivered') continue;
      final d = _orderDate(order);
      final key =
          '${d.day}/${d.month}/${d.year}';
      series[key] = (series[key] ?? 0) + order.totalAmount;
    }
    return series;
  }

  Map<String, int> _dailyOrderSeries(
      List<OrderModel> orders) {
    final series = <String, int>{};
    for (final order in orders) {
      final d = _orderDate(order);
      final key =
          '${d.day}/${d.month}/${d.year}';
      series[key] = (series[key] ?? 0) + 1;
    }
    return series;
  }

  Map<String, double> _salesByFabricType(
      List<OrderModel> orders) {
    final map = <String, double>{};
    for (final order in orders) {
      if (order.status != 'delivered') continue;
      for (final item in order.items) {
        final fabric =
            (item['fabricType'] ?? 'General')
                .toString()
                .trim();
        final price =
            ((item['price'] ?? 0) as num).toDouble() *
                ((item['qty'] ?? 1) as int);
        map[fabric] = (map[fabric] ?? 0) + price;
      }
    }
    return map;
  }

  Map<String, int> _ordersByFabricType(
      List<OrderModel> orders) {
    final map = <String, int>{};
    for (final order in orders) {
      for (final item in order.items) {
        final fabric =
            (item['fabricType'] ?? 'General')
                .toString()
                .trim();
        map[fabric] = (map[fabric] ?? 0) + 1;
      }
    }
    return map;
  }

  // ── POS Analytics Computations ──────────────────────────────────

  Map<String, double> _posDailySales(
      List<PosSaleModel> sales) {
    final series = <String, double>{};
    for (final sale in sales) {
      if (sale.status != 'completed') continue;
      final d = sale.createdAt;
      final key = '${d.day}/${d.month}/${d.year}';
      series[key] = (series[key] ?? 0) + sale.finalTotal;
    }
    return series;
  }

  Map<String, double> _posSalesByCategory(
      List<PosSaleModel> sales) {
    final map = <String, double>{};
    for (final sale in sales) {
      if (sale.status != 'completed') continue;
      for (final item in sale.items) {
        final cat =
            (item['category'] ?? 'Other').toString().trim();
        final lineTotal =
            (item['lineTotal'] as num?)?.toDouble() ?? 0;
        map[cat] = (map[cat] ?? 0) + lineTotal;
      }
    }
    return map;
  }

  Map<String, double> _posSalesByBranch(
      List<PosSaleModel> sales) {
    final map = <String, double>{};
    for (final sale in sales) {
      if (sale.status != 'completed') continue;
      final branch = sale.branchName;
      map[branch] = (map[branch] ?? 0) + sale.finalTotal;
    }
    return map;
  }

  Map<String, double> _posSalesByPaymentMethod(
      List<PosSaleModel> sales) {
    final map = <String, double>{};
    for (final sale in sales) {
      if (sale.status != 'completed') continue;
      final method = sale.paymentMethod.label;
      map[method] =
          (map[method] ?? 0) + sale.finalTotal;
    }
    return map;
  }

  Map<String, int> _posTopProducts(
      List<PosSaleModel> sales) {
    final map = <String, int>{};
    for (final sale in sales) {
      if (sale.status != 'completed') continue;
      for (final item in sale.items) {
        final name =
            (item['productName'] ?? '').toString().trim();
        final qty =
            (item['quantity'] as num?)?.toInt() ?? 1;
        if (name.isNotEmpty) {
          map[name] = (map[name] ?? 0) + qty;
        }
      }
    }
    return map;
  }

  Map<String, double> _posCashierRevenue(
      List<PosSaleModel> sales) {
    final map = <String, double>{};
    for (final sale in sales) {
      if (sale.status != 'completed') continue;
      final cashier = sale.cashierName;
      map[cashier] =
          (map[cashier] ?? 0) + sale.finalTotal;
    }
    return map;
  }

  // ── Combined Revenue Merge ──────────────────────────────────────

  Map<String, double> _combinedDailySales(
    List<OrderModel> orders,
    List<PosSaleModel> posSales,
  ) {
    final merged = <String, double>{};
    // Online
    for (final entry in _dailySalesSeries(orders).entries) {
      merged[entry.key] =
          (merged[entry.key] ?? 0) + entry.value;
    }
    // Physical
    for (final entry in _posDailySales(posSales).entries) {
      merged[entry.key] =
          (merged[entry.key] ?? 0) + entry.value;
    }
    return merged;
  }

  // ── UI Helpers ──────────────────────────────────────────────────

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final colors = context.appColors;

    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderSoft),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            dropdownColor: colors.surfaceAlt,
            style: GoogleFonts.poppins(
                color: colors.textPrimary, fontSize: 12),
            iconEnabledColor: colors.iconPrimary,
            isExpanded: true,
            hint: Text(
              label,
              style: GoogleFonts.poppins(
                  color: colors.textSecondary),
            ),
            items: items
                .map((e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(
                        e,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  String get _rangeLabel {
    switch (_range) {
      case AnalyticsRange.today:
        return 'Today';
      case AnalyticsRange.week:
        return 'Last 7 Days';
      case AnalyticsRange.month:
        return 'Last 30 Days';
      case AnalyticsRange.custom:
        if (_customRange == null) return 'Custom Range';
        return '${_customRange!.start.day}/${_customRange!.start.month}/${_customRange!.start.year}'
            ' — ${_customRange!.end.day}/${_customRange!.end.month}/${_customRange!.end.year}';
      case AnalyticsRange.all:
        return 'All Time';
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _customRange,
    );
    if (result == null) return;
    setState(() {
      _customRange = result;
      _range = AnalyticsRange.custom;
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSuperAdmin = AppConstants.isSuperAdminUid(
        _firebaseService.currentUser?.uid);

    return AppPageScaffold(
      title: 'Analytics Dashboard',
      body: !isSuperAdmin
          ? Center(
              child: Text(
                'Only super admins can view analytics.',
                style: GoogleFonts.poppins(
                    color: colors.textSecondary),
              ),
            )
          : Column(
              children: [
                // ── Channel Tabs ──────────────────────────
                Container(
                  color: colors.scaffold,
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(
                        icon: Icon(
                            Icons.shopping_bag_outlined),
                        text: 'Online',
                      ),
                      Tab(
                        icon: Icon(
                            Icons.point_of_sale_rounded),
                        text: 'Physical Shop',
                      ),
                      Tab(
                        icon:
                            Icon(Icons.merge_type_rounded),
                        text: 'Combined',
                      ),
                    ],
                  ),
                ),

                // ── Tab Views ─────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // ── Tab 1: Online Orders ───────────
                      _buildOnlineAnalytics(colors),

                      // ── Tab 2: Physical Shop (POS) ─────
                      _buildPhysicalAnalytics(colors),

                      // ── Tab 3: Combined ────────────────
                      _buildCombinedAnalytics(colors),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ── Filter Panel ────────────────────────────────────────────────

  Widget _buildFilterPanel(
    AppThemeColors colors, {
    List<String>? states,
    List<String>? admins,
    List<String>? areas,
    bool showOnlineFilters = true,
  }) {
    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 18),
      color: colors.brandPrimary.withOpacity(0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Range: $_rangeLabel',
                  style: GoogleFonts.poppins(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<AnalyticsRange>(
                  value: _range,
                  dropdownColor: colors.surfaceAlt,
                  style: GoogleFonts.poppins(
                    color: colors.textPrimary,
                  ),
                  iconEnabledColor: colors.iconPrimary,
                  items: const [
                    DropdownMenuItem(
                      value: AnalyticsRange.today,
                      child: Text('Today'),
                    ),
                    DropdownMenuItem(
                      value: AnalyticsRange.week,
                      child: Text('7 Days'),
                    ),
                    DropdownMenuItem(
                      value: AnalyticsRange.month,
                      child: Text('30 Days'),
                    ),
                    DropdownMenuItem(
                      value: AnalyticsRange.all,
                      child: Text('All Time'),
                    ),
                    DropdownMenuItem(
                      value: AnalyticsRange.custom,
                      child: Text('Custom'),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == null) return;
                    if (value == AnalyticsRange.custom) {
                      await _pickCustomRange();
                      return;
                    }
                    setState(() => _range = value);
                  },
                ),
              ),
            ],
          ),
          if (_range == AnalyticsRange.custom)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: OutlinedButton.icon(
                onPressed: _pickCustomRange,
                icon: const Icon(Icons.date_range_rounded),
                label: const Text('Change Custom Range'),
              ),
            ),
          if (showOnlineFilters &&
              states != null &&
              admins != null &&
              areas != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _filterDropdown(
                  label: 'State',
                  value: _selectedState,
                  items: states,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedState = v);
                  },
                ),
                const SizedBox(width: 10),
                _filterDropdown(
                  label: 'Admin',
                  value: _selectedAdmin,
                  items: admins,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedAdmin = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _filterDropdown(
                  label: 'Area',
                  value: _selectedArea,
                  items: areas,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedArea = v);
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _selectedState = 'All';
                      _selectedAdmin = 'All';
                      _selectedArea = 'All';
                    }),
                    child: const Text('Clear Filters'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Tab 1: Online Orders Analytics ──────────────────────────────

  Widget _buildOnlineAnalytics(AppThemeColors colors) {
    return StreamBuilder<List<OrderModel>>(
      stream: _firebaseService.watchAllOrders(),
      builder: (context, orderSnapshot) {
        final orders = orderSnapshot.data ?? [];

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firebaseService.watchAdmins(),
          builder: (context, adminSnapshot) {
            final admins = adminSnapshot.data ?? [];

            final availableStates = {
              'All',
              ...orders
                  .map((e) => e.assignedAdminState)
                  .where((e) => e.trim().isNotEmpty),
            }.toList()
              ..sort();

            final availableAdmins = {
              'All',
              ...orders
                  .map((e) => e.assignedAdminName)
                  .where((e) => e.trim().isNotEmpty),
            }.toList()
              ..sort();

            final availableAreas = {
              'All',
              ...orders
                  .map((e) => e.assignedAdminArea)
                  .where((e) => e.trim().isNotEmpty),
            }.toList()
              ..sort();

            if (!availableStates.contains(_selectedState)) {
              _selectedState = 'All';
            }
            if (!availableAdmins.contains(_selectedAdmin)) {
              _selectedAdmin = 'All';
            }
            if (!availableAreas.contains(_selectedArea)) {
              _selectedArea = 'All';
            }

            final filteredOrders = orders
                .where(_matchesOrderFilters)
                .toList();

            final deliveredOrders = filteredOrders
                .where((e) => e.status == 'delivered')
                .toList();
            final cancelledOrders = filteredOrders
                .where((e) => e.status == 'cancelled')
                .toList();
            final processingOrders = filteredOrders
                .where((e) => e.status == 'processing')
                .toList();
            final shippedOrders = filteredOrders
                .where((e) => e.status == 'shipped')
                .toList();

            final totalSales = deliveredOrders.fold<double>(
              0,
              (sum, item) => sum + item.totalAmount,
            );
            final totalOrders = filteredOrders.length;
            final totalEscalations = filteredOrders
                .where((e) => e.escalatedToSuperAdmin)
                .length;
            final totalReassignments = filteredOrders
                .where((e) =>
                    e.assignmentMethod ==
                    'manual_reassignment')
                .length;

            final orderCompletionRate = totalOrders == 0
                ? 0.0
                : (deliveredOrders.length / totalOrders) *
                    100;
            final orderCancellationRate = totalOrders == 0
                ? 0.0
                : (cancelledOrders.length / totalOrders) *
                    100;

            final salesByAdmin = _sumOrderTotalsByField(
              filteredOrders,
              (o) => o.assignedAdminName,
            );
            final salesByState = _sumOrderTotalsByField(
              filteredOrders,
              (o) => o.assignedAdminState,
            );
            final salesByArea = _sumOrderTotalsByField(
              filteredOrders,
              (o) => o.assignedAdminArea,
            );
            final salesByFabric =
                _salesByFabricType(filteredOrders);
            final ordersByAdmin = _countOrdersByField(
              filteredOrders,
              (o) => o.assignedAdminName,
            );
            final ordersByFabric =
                _ordersByFabricType(filteredOrders);
            final reassignmentsByAdmin =
                _countOrdersByField(
              filteredOrders
                  .where((e) =>
                      e.assignmentMethod ==
                      'manual_reassignment')
                  .toList(),
              (o) => o.assignedAdminName,
            );
            final salesSeries =
                _dailySalesSeries(filteredOrders);
            final orderSeries =
                _dailyOrderSeries(filteredOrders);

            final sortedAdminSales =
                salesByAdmin.entries.toList()
                  ..sort(
                      (a, b) => b.value.compareTo(a.value));
            final sortedStateSales =
                salesByState.entries.toList()
                  ..sort(
                      (a, b) => b.value.compareTo(a.value));
            final sortedAreaSales =
                salesByArea.entries.toList()
                  ..sort(
                      (a, b) => b.value.compareTo(a.value));

            final topAdmin = sortedAdminSales.isEmpty
                ? null
                : sortedAdminSales.first;
            final worstAdmin = sortedAdminSales.isEmpty
                ? null
                : sortedAdminSales.last;
            final topState = sortedStateSales.isEmpty
                ? null
                : sortedStateSales.first;
            final worstState = sortedStateSales.isEmpty
                ? null
                : sortedStateSales.last;
            final topArea = sortedAreaSales.isEmpty
                ? null
                : sortedAreaSales.first;
            final worstArea = sortedAreaSales.isEmpty
                ? null
                : sortedAreaSales.last;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildFilterPanel(
                  colors,
                  states: availableStates,
                  admins: availableAdmins,
                  areas: availableAreas,
                ),

                // Online channel badge
                _buildChannelBadge(
                  'Online Orders',
                  Icons.shopping_bag_outlined,
                  colors.info,
                  colors,
                ),
                const SizedBox(height: 16),

                const AppSectionTitle(
                    title: 'Sales Overview'),
                const SizedBox(height: 10),

                _buildMetricGrid([
                  _MetricCardData(
                    title: 'Online Revenue',
                    value:
                        '₦${totalSales.toStringAsFixed(0)}',
                    icon: Icons.payments_rounded,
                  ),
                  _MetricCardData(
                    title: 'Delivered Orders',
                    value: '${deliveredOrders.length}',
                    icon:
                        Icons.check_circle_outline_rounded,
                  ),
                  _MetricCardData(
                    title: 'All Orders',
                    value: '$totalOrders',
                    icon: Icons.receipt_long_rounded,
                  ),
                  _MetricCardData(
                    title: 'Processing',
                    value: '${processingOrders.length}',
                    icon: Icons.autorenew_rounded,
                  ),
                  _MetricCardData(
                    title: 'Shipped',
                    value: '${shippedOrders.length}',
                    icon: Icons.local_shipping_outlined,
                  ),
                  _MetricCardData(
                    title: 'Cancelled',
                    value: '${cancelledOrders.length}',
                    icon: Icons.cancel_outlined,
                  ),
                  _MetricCardData(
                    title: 'Admins',
                    value:
                        '${admins.length + AppConstants.superAdminUids.length}',
                    icon: Icons
                        .admin_panel_settings_outlined,
                  ),
                  _MetricCardData(
                    title: 'Escalations',
                    value: '$totalEscalations',
                    icon: Icons.warning_amber_rounded,
                  ),
                  _MetricCardData(
                    title: 'Reassignments',
                    value: '$totalReassignments',
                    icon: Icons.swap_horiz_rounded,
                  ),
                ]),

                const SizedBox(height: 20),
                const AppSectionTitle(
                    title: 'Performance Health'),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: PerformanceStatusCard(
                        title: 'Completion Rate',
                        value:
                            '${orderCompletionRate.toStringAsFixed(1)}%',
                        subtitle:
                            'Delivered / total orders',
                        accentColor: colors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PerformanceStatusCard(
                        title: 'Cancellation Rate',
                        value:
                            '${orderCancellationRate.toStringAsFixed(1)}%',
                        subtitle:
                            'Cancelled / total orders',
                        accentColor: colors.error,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const AppSectionTitle(
                    title: 'Top Performers'),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TopRankCard(
                        title: 'Top Admin',
                        name: topAdmin?.key ?? 'N/A',
                        value: topAdmin == null
                            ? '₦0'
                            : '₦${topAdmin.value.toStringAsFixed(0)}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TopRankCard(
                        title: 'Top State',
                        name: topState?.key ?? 'N/A',
                        value: topState == null
                            ? '₦0'
                            : '₦${topState.value.toStringAsFixed(0)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TopRankCard(
                        title: 'Top Area',
                        name: topArea?.key ?? 'N/A',
                        value: topArea == null
                            ? '₦0'
                            : '₦${topArea.value.toStringAsFixed(0)}',
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),

                const SizedBox(height: 20),
                const AppSectionTitle(
                    title: 'Best vs Needs Attention'),
                const SizedBox(height: 10),

                ComparisonDuelCard(
                  title: 'Admin Sales Comparison',
                  bestLabel: topAdmin?.key ?? 'N/A',
                  bestValue: topAdmin == null
                      ? '₦0'
                      : '₦${topAdmin.value.toStringAsFixed(0)}',
                  worstLabel: worstAdmin?.key ?? 'N/A',
                  worstValue: worstAdmin == null
                      ? '₦0'
                      : '₦${worstAdmin.value.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 12),

                ComparisonDuelCard(
                  title: 'State Sales Comparison',
                  bestLabel: topState?.key ?? 'N/A',
                  bestValue: topState == null
                      ? '₦0'
                      : '₦${topState.value.toStringAsFixed(0)}',
                  worstLabel: worstState?.key ?? 'N/A',
                  worstValue: worstState == null
                      ? '₦0'
                      : '₦${worstState.value.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 12),

                ComparisonDuelCard(
                  title: 'Area Sales Comparison',
                  bestLabel: topArea?.key ?? 'N/A',
                  bestValue: topArea == null
                      ? '₦0'
                      : '₦${topArea.value.toStringAsFixed(0)}',
                  worstLabel: worstArea?.key ?? 'N/A',
                  worstValue: worstArea == null
                      ? '₦0'
                      : '₦${worstArea.value.toStringAsFixed(0)}',
                ),

                const SizedBox(height: 20),
                const AppSectionTitle(
                    title: 'Revenue Trend'),
                AnalyticsBarChartCard(
                  title: 'Daily Sales (₦)',
                  data: salesSeries,
                  isCurrency: true,
                  emptyLabel:
                      'No sales trend data yet',
                ),

                const SizedBox(height: 20),
                const AppSectionTitle(
                    title: 'Order Trend'),
                AnalyticsBarChartCard(
                  title: 'Daily Orders',
                  data: orderSeries,
                  isCurrency: false,
                  emptyLabel: 'No order trend data yet',
                ),

                const SizedBox(height: 20),
                const AppSectionTitle(
                    title: 'Revenue by Product Type'),
                AnalyticsBarChartCard(
                  title: 'Product Type Sales',
                  data: salesByFabric,
                  isCurrency: true,
                  emptyLabel: 'No sales data yet',
                ),

                const SizedBox(height: 20),
                const AppSectionTitle(
                    title: 'Orders by Product Type'),
                AnalyticsBarChartCard(
                  title: 'Product Type Orders',
                  data: ordersByFabric,
                  isCurrency: false,
                  emptyLabel:
                      'No order data yet',
                ),

                const SizedBox(height: 20),
                const AppSectionTitle(
                    title: 'Sales by Admin'),
                AnalyticsBarChartCard(
                  title: 'Admin Revenue',
                  data: salesByAdmin,
                  isCurrency: true,
                  emptyLabel: 'No admin sales data yet',
                ),

                const SizedBox(height: 20),
                const AppSectionTitle(
                    title: 'Sales by State'),
                AnalyticsBarChartCard(
                  title: 'State Revenue',
                  data: salesByState,
                  isCurrency: true,
                  emptyLabel: 'No state sales data yet',
                ),

                const SizedBox(height: 20),
                const AppSectionTitle(
                    title: 'Sales by Area'),
                AnalyticsBarChartCard(
                  title: 'Area Revenue',
                  data: salesByArea,
                  isCurrency: true,
                  emptyLabel: 'No area sales data yet',
                ),

                const SizedBox(height: 20),
                const AppSectionTitle(
                    title: 'Orders by Admin'),
                AnalyticsBarChartCard(
                  title: 'Admin Order Count',
                  data: ordersByAdmin,
                  isCurrency: false,
                  emptyLabel:
                      'No admin order data yet',
                ),

                const SizedBox(height: 20),
                const AppSectionTitle(
                    title: 'Reassignments by Admin'),
                AnalyticsBarChartCard(
                  title: 'Reassignment Count',
                  data: reassignmentsByAdmin,
                  isCurrency: false,
                  emptyLabel:
                      'No reassignment data yet',
                ),

                const SizedBox(height: 32),
              ],
            );
          },
        );
      },
    );
  }

  // ── Tab 2: Physical Shop Analytics ─────────────────────────────

  Widget _buildPhysicalAnalytics(AppThemeColors colors) {
    return StreamBuilder<List<PosSaleModel>>(
      stream: _posRepo.watchAllPosSales(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
                ConnectionState.waiting &&
            (snapshot.data == null)) {
          return Center(
            child: CircularProgressIndicator(
                color: colors.brandPrimary),
          );
        }

        final allSales = snapshot.data ?? [];
        final filteredSales = allSales
            .where(_matchesPosFilters)
            .toList();
        final completedSales = filteredSales
            .where((s) => s.status == 'completed')
            .toList();

        final totalRevenue = completedSales.fold<double>(
          0,
          (sum, s) => sum + s.finalTotal,
        );
        final totalTransactions = completedSales.length;
        final totalDiscounts = completedSales.fold<double>(
          0,
          (sum, s) {
            final discountAmount =
                _posRepo.calculateDiscount(
              subtotal: s.subtotal,
              discountValue: s.discountValue,
              discountType: s.discountType,
            );
            return sum + discountAmount;
          },
        );
        final avgTransaction = totalTransactions == 0
            ? 0.0
            : totalRevenue / totalTransactions;

        final dailySales = _posDailySales(filteredSales);
        final salesByCategory =
            _posSalesByCategory(filteredSales);
        final salesByBranch =
            _posSalesByBranch(filteredSales);
        final salesByPayment =
            _posSalesByPaymentMethod(filteredSales);
        final topProducts =
            _posTopProducts(filteredSales);
        final cashierRevenue =
            _posCashierRevenue(filteredSales);

        // Admin performance stream
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFilterPanel(colors,
                showOnlineFilters: false),

            // Physical channel badge
            _buildChannelBadge(
              'Physical Shop (POS)',
              Icons.point_of_sale_rounded,
              colors.brandPrimary,
              colors,
            ),
            const SizedBox(height: 16),

            const AppSectionTitle(
                title: 'POS Sales Overview'),
            const SizedBox(height: 10),

            _buildMetricGrid([
              _MetricCardData(
                title: 'Total Revenue',
                value:
                    '₦${totalRevenue.toStringAsFixed(0)}',
                icon: Icons.payments_rounded,
              ),
              _MetricCardData(
                title: 'Transactions',
                value: '$totalTransactions',
                icon: Icons.receipt_rounded,
              ),
              _MetricCardData(
                title: 'Avg. Transaction',
                value:
                    '₦${avgTransaction.toStringAsFixed(0)}',
                icon: Icons.trending_up_rounded,
              ),
              _MetricCardData(
                title: 'Total Discounts',
                value:
                    '₦${totalDiscounts.toStringAsFixed(0)}',
                icon: Icons.discount_outlined,
              ),
            ]),

            const SizedBox(height: 20),
            const AppSectionTitle(
                title: 'Daily POS Revenue'),
            AnalyticsBarChartCard(
              title: 'POS Daily Sales (₦)',
              data: dailySales,
              isCurrency: true,
              emptyLabel: 'No POS sales yet',
            ),

            const SizedBox(height: 20),
            const AppSectionTitle(
                title: 'Revenue by Category'),
            AnalyticsBarChartCard(
              title: 'Category Revenue',
              data: salesByCategory,
              isCurrency: true,
              emptyLabel:
                  'No category data yet',
            ),

            const SizedBox(height: 20),
            const AppSectionTitle(
                title: 'Revenue by Branch'),
            AnalyticsBarChartCard(
              title: 'Branch Revenue',
              data: salesByBranch,
              isCurrency: true,
              emptyLabel: 'No branch data yet',
            ),

            const SizedBox(height: 20),
            const AppSectionTitle(
                title: 'Sales by Payment Method'),
            AnalyticsBarChartCard(
              title: 'Payment Methods',
              data: salesByPayment,
              isCurrency: true,
              emptyLabel:
                  'No payment method data yet',
            ),

            const SizedBox(height: 20),
            const AppSectionTitle(
                title: 'Top Selling Products (Units)'),
            AnalyticsBarChartCard(
              title: 'Product Units Sold',
              data: topProducts
                  .map((k, v) => MapEntry(k, v.toDouble())),
              isCurrency: false,
              emptyLabel: 'No product data yet',
            ),

            const SizedBox(height: 20),
            const AppSectionTitle(
                title: 'Revenue by Cashier'),
            AnalyticsBarChartCard(
              title: 'Cashier Revenue',
              data: cashierRevenue,
              isCurrency: true,
              emptyLabel: 'No cashier data yet',
            ),

            const SizedBox(height: 20),
            const AppSectionTitle(
                title: 'Cashier Performance'),
            const SizedBox(height: 10),

            // Admin performance from Firestore
            StreamBuilder<
                List<Map<String, dynamic>>>(
              stream: _posRepo
                  .watchAllAdminPerformance(),
              builder: (context, perfSnap) {
                final performers =
                    perfSnap.data ?? [];
                if (performers.isEmpty) {
                  return AppSurfaceCard(
                    child: Text(
                      'No cashier performance data yet.',
                      style: GoogleFonts.poppins(
                          color: colors.textSecondary),
                    ),
                  );
                }

                return Column(
                  children: performers.map((p) {
                    final name = (p['name'] ??
                            p['email'] ??
                            'Unknown')
                        .toString();
                    final revenue =
                        (p['totalRevenue'] as num?)
                                ?.toDouble() ??
                            0;
                    final txns =
                        (p['totalTransactions']
                                    as num?)
                                ?.toInt() ??
                            0;
                    final discounts = (p[
                                    'totalDiscountsApplied']
                                as num?)
                            ?.toInt() ??
                        0;
                    final products =
                        (p['totalProductsSold'] as num?)
                                ?.toInt() ??
                            0;

                    return Container(
                      margin: const EdgeInsets.only(
                          bottom: 10),
                      padding:
                          const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius:
                            BorderRadius.circular(14),
                        border: Border.all(
                            color: colors.borderSoft),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: AppGradients
                                      .goldVertical,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0]
                                            .toUpperCase()
                                        : 'C',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight:
                                          FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  name,
                                  style:
                                      GoogleFonts.poppins(
                                    color:
                                        colors.textPrimary,
                                    fontWeight:
                                        FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                '₦${revenue.toStringAsFixed(0)}',
                                style:
                                    GoogleFonts.poppins(
                                  color:
                                      colors.brandPrimary,
                                  fontWeight:
                                      FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _perfChip(
                                '$txns txns',
                                Icons.receipt_rounded,
                                colors.info,
                              ),
                              _perfChip(
                                '$products items',
                                Icons.texture_rounded,
                                colors.success,
                              ),
                              _perfChip(
                                '$discounts discounts',
                                Icons.discount_outlined,
                                colors.warning,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  // ── Tab 3: Combined Analytics ───────────────────────────────────

  Widget _buildCombinedAnalytics(AppThemeColors colors) {
    return StreamBuilder<List<OrderModel>>(
      stream: _firebaseService.watchAllOrders(),
      builder: (context, orderSnap) {
        return StreamBuilder<List<PosSaleModel>>(
          stream: _posRepo.watchAllPosSales(),
          builder: (context, posSnap) {
            final orders = orderSnap.data ?? [];
            final posSales = posSnap.data ?? [];

            final filteredOrders = orders
                .where(_matchesOrderFilters)
                .toList();
            final filteredPos = posSales
                .where(_matchesPosFilters)
                .toList();

            // Online metrics
            final onlineRevenue = filteredOrders
                .where((o) => o.status == 'delivered')
                .fold<double>(
                    0, (s, o) => s + o.totalAmount);

            // Physical metrics
            final physicalRevenue = filteredPos
                .where((s) => s.status == 'completed')
                .fold<double>(
                    0, (s, sale) => s + sale.finalTotal);

            final totalRevenue =
                onlineRevenue + physicalRevenue;

            final onlineOrders = filteredOrders.length;
            final physicalTransactions = filteredPos
                .where((s) => s.status == 'completed')
                .length;

            // Combined daily chart
            final combinedDaily = _combinedDailySales(
              filteredOrders,
              filteredPos,
            );

            // Online share / Physical share
            final onlineShare = totalRevenue == 0
                ? 0.0
                : (onlineRevenue / totalRevenue) * 100;
            final physicalShare = totalRevenue == 0
                ? 0.0
                : (physicalRevenue / totalRevenue) *
                    100;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildFilterPanel(colors,
                    showOnlineFilters: false),

                // Combined badge
                _buildChannelBadge(
                  'All Channels Combined',
                  Icons.merge_type_rounded,
                  colors.success,
                  colors,
                ),
                const SizedBox(height: 16),

                const AppSectionTitle(
                    title: 'Platform Revenue Overview'),
                const SizedBox(height: 10),

                // Key metrics
                _buildMetricGrid([
                  _MetricCardData(
                    title: 'Total Revenue',
                    value:
                        '₦${totalRevenue.toStringAsFixed(0)}',
                    icon: Icons.payments_rounded,
                  ),
                  _MetricCardData(
                    title: 'Online Revenue',
                    value:
                        '₦${onlineRevenue.toStringAsFixed(0)}',
                    icon: Icons.shopping_bag_outlined,
                  ),
                  _MetricCardData(
                    title: 'Physical Revenue',
                    value:
                        '₦${physicalRevenue.toStringAsFixed(0)}',
                    icon: Icons.point_of_sale_rounded,
                  ),
                  _MetricCardData(
                    title: 'Online Orders',
                    value: '$onlineOrders',
                    icon: Icons.receipt_long_rounded,
                  ),
                  _MetricCardData(
                    title: 'POS Transactions',
                    value: '$physicalTransactions',
                    icon: Icons.receipt_rounded,
                  ),
                  _MetricCardData(
                    title: 'Total Transactions',
                    value:
                        '${onlineOrders + physicalTransactions}',
                    icon: Icons.bar_chart_rounded,
                  ),
                ]),

                const SizedBox(height: 20),

                // Channel split
                AppSurfaceCard(
                  margin:
                      const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revenue Channel Split',
                        style: GoogleFonts.poppins(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildChannelSplitBar(
                        onlineShare,
                        physicalShare,
                        onlineRevenue,
                        physicalRevenue,
                        colors,
                      ),
                    ],
                  ),
                ),

                const AppSectionTitle(
                    title: 'Combined Daily Revenue'),
                AnalyticsBarChartCard(
                  title: 'All Channels Daily Revenue',
                  data: combinedDaily,
                  isCurrency: true,
                  emptyLabel:
                      'No combined revenue data yet',
                ),

                const SizedBox(height: 20),
                const AppSectionTitle(
                    title:
                        'Performance Comparison'),
                const SizedBox(height: 10),

                ComparisonDuelCard(
                  title: 'Channel Revenue Comparison',
                  bestLabel: 'Online',
                  bestValue:
                      '₦${onlineRevenue.toStringAsFixed(0)}',
                  worstLabel: 'Physical Shop',
                  worstValue:
                      '₦${physicalRevenue.toStringAsFixed(0)}',
                ),

                const SizedBox(height: 32),
              ],
            );
          },
        );
      },
    );
  }

  // ── Channel Badge ───────────────────────────────────────────────

  Widget _buildChannelBadge(
    String label,
    IconData icon,
    Color color,
    AppThemeColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Channel Split Bar ───────────────────────────────────────────

  Widget _buildChannelSplitBar(
    double onlineShare,
    double physicalShare,
    double onlineRevenue,
    double physicalRevenue,
    AppThemeColors colors,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: onlineShare > 0
                  ? onlineShare.round()
                  : 1,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: colors.info,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: physicalShare > 0
                  ? physicalShare.round()
                  : 1,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  gradient:
                      AppGradients.goldHorizontal,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _splitLegend(
              'Online',
              '${onlineShare.toStringAsFixed(1)}%',
              '₦${onlineRevenue.toStringAsFixed(0)}',
              colors.info,
            ),
            const Spacer(),
            _splitLegend(
              'Physical',
              '${physicalShare.toStringAsFixed(1)}%',
              '₦${physicalRevenue.toStringAsFixed(0)}',
              colors.brandPrimary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _splitLegend(
    String label,
    String share,
    String revenue,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            Text(
              '$share • $revenue',
              style: GoogleFonts.poppins(
                color: AppTheme.colorsOf(context)
                    .textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Metric Grid Builder ─────────────────────────────────────────

  Widget _buildMetricGrid(
      List<_MetricCardData> metrics) {
    final rows = <Widget>[];
    for (int i = 0; i < metrics.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: metrics[i].title,
                value: metrics[i].value,
                icon: metrics[i].icon,
              ),
            ),
            const SizedBox(width: 12),
            i + 1 < metrics.length
                ? Expanded(
                    child: _MetricCard(
                      title: metrics[i + 1].title,
                      value: metrics[i + 1].value,
                      icon: metrics[i + 1].icon,
                    ),
                  )
                : const Expanded(child: SizedBox()),
          ],
        ),
      );
      if (i + 2 < metrics.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    return Column(children: rows);
  }

  // ── Performance Chip ────────────────────────────────────────────

  Widget _perfChip(
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Metric Card Data Model ──────────────────────────────────────────────────────

class _MetricCardData {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCardData({
    required this.title,
    required this.value,
    this.icon = Icons.bar_chart_rounded,
  });
}

// ── Metric Card Widget ──────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    this.icon = Icons.bar_chart_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppSurfaceCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color:
                    colors.brandPrimary.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: colors.brandPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: colors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}