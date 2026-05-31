// ignore_for_file: deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── SHARED TOKENS (same as POS) ──────────────────────────────────────
class _T {
  static const primary = Color(0xFF1A6B3C);
  static const primaryD = Color(0xFF134D2B);
  static const primaryL = Color(0xFFE8F5EE);
  static const accent = Color(0xFFD4A017);
  static const accentL = Color(0xFFFFF8E1);
  static const bg = Color(0xFFF4F6F4);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF0F4F1);
  static const ink = Color(0xFF0D1F15);
  static const ink2 = Color(0xFF2E4A38);
  static const muted = Color(0xFF6B7F72);
  static const muted2 = Color(0xFFA0B0A7);
  static const line = Color(0xFFDDE6DF);
  static const lineSoft = Color(0xFFEDF2EE);
  static const success = Color(0xFF059669);
  static const successBg = Color(0xFFD1FAE5);
  static const danger = Color(0xFFDC2626);
  static const dangerBg = Color(0xFFFEE2E2);
  static const warn = Color(0xFFD97706);
  static const warnBg = Color(0xFFFEF3C7);
}

TextStyle _h(
  double s, {
  FontWeight w = FontWeight.w700,
  Color? c,
  double? ls,
}) => GoogleFonts.inter(
  fontSize: s,
  fontWeight: w,
  color: c ?? _T.ink,
  letterSpacing: ls,
);

TextStyle _m(double s, {FontWeight w = FontWeight.w700, Color? c}) =>
    GoogleFonts.inter(
      fontSize: s,
      fontWeight: w,
      color: c ?? _T.ink,
      letterSpacing: -0.3,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

TextStyle _eye(double s, {Color? c}) => GoogleFonts.inter(
  fontSize: s,
  fontWeight: FontWeight.w800,
  color: c ?? _T.muted,
  letterSpacing: 1.1,
);

// ─── WIDGET ───────────────────────────────────────────────────────────
class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});
  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  double _totalSales = 0.0;
  int _totalOrders = 0;
  int _activeOrders = 0;
  int _lowStockCount = 0;

  List<Map<String, dynamic>> _recentOrders = [];
  List<Map<String, dynamic>> _topItems = [];

  List<double> _weeklySales = List.filled(7, 0.0);
  List<String> _weekDays = [];
  double _maxWeeklySale = 1.0;

  late AnimationController _ac;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  String _dayName(int weekday) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekAgo = todayStart.subtract(const Duration(days: 6));

      final ordersRes = await _supabase
          .from('orders')
          .select('id, total_amount, order_status, created_at')
          .gte('created_at', weekAgo.toIso8601String())
          .order('created_at', ascending: false);

      _weekDays = List.generate(
        7,
        (i) => _dayName(weekAgo.add(Duration(days: i)).weekday),
      );
      _weeklySales = List.filled(7, 0.0);

      double todaySales = 0;
      int todayOrders = 0;
      int activeOrders = 0;

      for (final order in ordersRes as List) {
        final dt = DateTime.parse(order['created_at']).toLocal();
        final amt = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
        final status = order['order_status'] as String? ?? '';
        final done = status == 'completed' || status == 'ready';

        if (!dt.isBefore(todayStart)) {
          if (done) {
            todaySales += amt;
            todayOrders++;
          } else if (status == 'active' || status == 'pending')
            activeOrders++;
        }
        if (done) {
          final diff = DateTime(
            dt.year,
            dt.month,
            dt.day,
          ).difference(weekAgo).inDays;
          if (diff >= 0 && diff < 7) _weeklySales[diff] += amt;
        }
      }

      _maxWeeklySale = _weeklySales.reduce(math.max);
      if (_maxWeeklySale == 0) _maxWeeklySale = 1;

      final inventoryRes = await _supabase
          .from('inventory_items')
          .select('id')
          .lt('current_quantity', 10);
      final orderItemsRes = await _supabase
          .from('order_items')
          .select('quantity, menu_items(name, price)')
          .limit(500);

      final Map<String, Map<String, dynamic>> agg = {};
      for (final item in orderItemsRes as List) {
        final name = item['menu_items']?['name'] as String? ?? 'Unknown';
        final qty = (item['quantity'] as num?)?.toInt() ?? 0;
        final price = (item['menu_items']?['price'] as num?)?.toDouble() ?? 0.0;
        agg.putIfAbsent(name, () => {'name': name, 'sales': 0, 'price': price});
        agg[name]!['sales'] = (agg[name]!['sales'] as int) + qty;
      }
      final topList = agg.values.toList()
        ..sort((a, b) => (b['sales'] as int).compareTo(a['sales'] as int));

      if (mounted) {
        setState(() {
          _totalSales = todaySales;
          _totalOrders = todayOrders;
          _activeOrders = activeOrders;
          _lowStockCount = (inventoryRes as List).length;
          _recentOrders = List<Map<String, dynamic>>.from(ordersRes.take(6));
          _topItems = topList.take(5).toList();
          _isLoading = false;
        });
        _ac.forward(from: 0.0);
      }
    } catch (e) {
      debugPrint('Dashboard error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── BUILD ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _T.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: _T.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 14),
              Text(
                'Loading dashboard…',
                style: _h(13, w: FontWeight.w500, c: _T.muted),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: _T.bg,
      body: FadeTransition(
        opacity: _fade,
        child: LayoutBuilder(
          builder: (context, cs) {
            final isDesktop = cs.maxWidth > 1000;
            final isTablet = cs.maxWidth > 650 && cs.maxWidth <= 1000;
            return Column(
              children: [
                _buildHeader(isDesktop, isTablet),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 28 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _kpiSection(isDesktop, isTablet),
                        SizedBox(height: isDesktop ? 28 : 16),
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    _salesChart(),
                                    const SizedBox(height: 24),
                                    _recentOrdersTable(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(flex: 1, child: _topSellingItems()),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _salesChart(),
                              const SizedBox(height: 16),
                              _topSellingItems(),
                              const SizedBox(height: 16),
                              _recentOrdersTable(),
                            ],
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDesktop, bool isTablet) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 28 : 16,
        vertical: 18,
      ),
      decoration: const BoxDecoration(
        color: _T.surface,
        border: Border(bottom: BorderSide(color: _T.line)),
      ),
      child: Row(
        children: [
          // Brand mark
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_T.primary, _T.primaryD],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _T.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.dashboard_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greeting, Admin', style: _h(18, w: FontWeight.w800)),
                if (isDesktop || isTablet)
                  Text(
                    "Here's what's happening at Zaytouna Park today.",
                    style: _h(12, w: FontWeight.w500, c: _T.muted),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Refresh btn
          _ActionBtn(icon: Icons.refresh_rounded, onTap: _fetchDashboardData),
          const SizedBox(width: 10),
          // Date chip
          if (isDesktop || isTablet) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _T.primaryL,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _T.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: _T.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(DateTime.now()),
                    style: _h(11.5, w: FontWeight.w700, c: _T.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],
          // Avatar
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _T.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: _T.primaryL,
              child: Text(
                'A',
                style: _h(13, w: FontWeight.w800, c: _T.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  // ─── KPI SECTION ────────────────────────────────────────────────────
  Widget _kpiSection(bool isDesktop, bool isTablet) {
    final kpis = [
      _KpiData(
        "Today's Sales",
        '\$${_totalSales.toStringAsFixed(2)}',
        Icons.attach_money_rounded,
        _T.primary,
        _T.primaryL,
      ),
      _KpiData(
        'Completed Orders',
        '$_totalOrders',
        Icons.receipt_long_rounded,
        _T.success,
        _T.successBg,
      ),
      _KpiData(
        'Active Kitchen',
        '$_activeOrders',
        Icons.restaurant_rounded,
        _T.warn,
        _T.warnBg,
      ),
      _KpiData(
        'Low Stock Items',
        '$_lowStockCount',
        Icons.warning_amber_rounded,
        _T.danger,
        _T.dangerBg,
      ),
    ];
    if (isDesktop) {
      return Row(
        children: kpis
            .asMap()
            .entries
            .map(
              (e) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: e.key < kpis.length - 1 ? 16 : 0,
                  ),
                  child: _KpiCard(data: e.value),
                ),
              ),
            )
            .toList(),
      );
    } else if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _KpiCard(data: kpis[0])),
              const SizedBox(width: 14),
              Expanded(child: _KpiCard(data: kpis[1])),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _KpiCard(data: kpis[2])),
              const SizedBox(width: 14),
              Expanded(child: _KpiCard(data: kpis[3])),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: kpis
            .map(
              (k) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _KpiCard(data: k),
              ),
            )
            .toList(),
      );
    }
  }

  // ─── SALES CHART ────────────────────────────────────────────────────
  Widget _salesChart() {
    final maxVal = _maxWeeklySale;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weekly Revenue', style: _h(16, w: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    'Last 7 days',
                    style: _h(11, w: FontWeight.w500, c: _T.muted),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _T.primaryL,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '\$${_weeklySales.fold(0.0, (a, b) => a + b).toStringAsFixed(0)} total',
                  style: _h(11, w: FontWeight.w700, c: _T.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final ratio = _weeklySales[i] / maxVal;
                final isToday = i == 6;
                final barColor = isToday ? _T.primary : _T.primaryL;
                final textColor = isToday ? _T.primary : _T.muted;
                return Tooltip(
                  message: '\$${_weeklySales[i].toStringAsFixed(2)}',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Value label
                      if (_weeklySales[i] > 0)
                        Text(
                          '\$${_weeklySales[i].toStringAsFixed(0)}',
                          style: _h(9, w: FontWeight.w700, c: _T.primary),
                        ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutQuart,
                        width: MediaQuery.of(context).size.width > 600
                            ? 38
                            : 22,
                        height: math.max(6.0, 140 * ratio),
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(8),
                          border: isToday
                              ? Border.all(
                                  color: _T.primary.withValues(alpha: 0.5),
                                  width: 1.5,
                                )
                              : Border.all(color: _T.line),
                          boxShadow: isToday
                              ? [
                                  BoxShadow(
                                    color: _T.primary.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _weekDays[i],
                        style: _h(
                          11,
                          w: isToday ? FontWeight.w800 : FontWeight.w600,
                          c: textColor,
                        ),
                      ),
                      if (isToday)
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: _T.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ─── RECENT ORDERS ──────────────────────────────────────────────────
  Widget _recentOrdersTable() {
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Orders', style: _h(16, w: FontWeight.w800)),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: _T.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: _T.primaryL),
                    ),
                  ),
                  child: Text(
                    'View All',
                    style: _h(12, w: FontWeight.w700, c: _T.primary),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _T.lineSoft),
          if (_recentOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text('No recent orders.', style: _h(13, c: _T.muted)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentOrders.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: _T.lineSoft),
              itemBuilder: (_, i) {
                final order = _recentOrders[i];
                final status = order['order_status'] as String? ?? '';
                final done = status == 'completed' || status == 'ready';
                final time = DateTime.parse(order['created_at']).toLocal();
                final amount =
                    (order['total_amount'] as num?)?.toDouble() ?? 0.0;

                Color statusColor = done
                    ? _T.success
                    : status == 'active'
                    ? _T.warn
                    : _T.muted;
                Color statusBg = done
                    ? _T.successBg
                    : status == 'active'
                    ? _T.warnBg
                    : _T.lineSoft;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      done
                          ? Icons.check_circle_outline_rounded
                          : Icons.pending_actions_rounded,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Order #${order['id']}',
                    style: _h(13, w: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                    style: _h(11, w: FontWeight.w500, c: _T.muted),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${amount.toStringAsFixed(2)}',
                        style: _m(15, w: FontWeight.w800, c: _T.ink),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: _h(
                            9,
                            w: FontWeight.w800,
                            c: statusColor,
                            ls: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ─── TOP SELLING ────────────────────────────────────────────────────
  Widget _topSellingItems() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _T.accentL,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: _T.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text('Top Selling Items', style: _h(16, w: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 20),
          if (_topItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text('Not enough data.', style: _h(13, c: _T.muted)),
              ),
            )
          else
            ...List.generate(_topItems.length, (i) {
              final item = _topItems[i];
              final rank = i + 1;
              final Color rankColor = rank == 1
                  ? _T.accent
                  : rank == 2
                  ? _T.muted
                  : rank == 3
                  ? const Color(0xFFCD7F32)
                  : _T.muted2;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    // Rank badge
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: rankColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '#$rank',
                          style: _h(11, w: FontWeight.w800, c: rankColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Icon
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _T.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.fastfood_rounded,
                        color: _T.muted2,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] as String,
                            style: _h(13, w: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${item['sales']} sold',
                            style: _h(11, w: FontWeight.w500, c: _T.muted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${(item['price'] as double).toStringAsFixed(2)}',
                      style: _m(14, w: FontWeight.w800, c: _T.primary),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─── SHARED COMPONENTS ────────────────────────────────────────────────
class _KpiData {
  final String label, value;
  final IconData icon;
  final Color color, bg;
  const _KpiData(this.label, this.value, this.icon, this.color, this.bg);
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _T.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _T.line),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                data.label,
                style: _eye(10, c: _T.muted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: data.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(data.icon, color: data.color, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          data.value,
          style: _m(26, w: FontWeight.w900),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Container(
          height: 3,
          width: 32,
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    ),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _Card({required this.child, this.padding});
  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _T.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _T.line),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _T.line),
        ),
        child: Icon(icon, size: 19, color: _T.ink2),
      ),
    ),
  );
}
