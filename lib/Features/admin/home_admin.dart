// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;

  // Dashboard Data
  double _totalSales = 0.0;
  int _totalOrders = 0;
  int _activeOrders = 0;
  int _lowStockCount = 0;

  List<Map<String, dynamic>> _recentOrders = [];
  List<Map<String, dynamic>> _topItems = [];

  // Chart Data
  List<double> _weeklySales = List.filled(7, 0.0);
  List<String> _weekDays = [];
  double _maxWeeklySale = 0.0;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _fetchDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper to get day name
  String _dayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekAgo = todayStart.subtract(const Duration(days: 6));

      // 1. Fetch Orders for the last 7 days
      final ordersRes = await _supabase
          .from('orders')
          .select('id, total_amount, order_status, created_at')
          .gte('created_at', weekAgo.toIso8601String())
          .order('created_at', ascending: false);

      // Initialize Weekly Chart
      _weekDays = List.generate(
        7,
        (i) => _dayName(weekAgo.add(Duration(days: i)).weekday),
      );
      _weeklySales = List.filled(7, 0.0);

      double tempTodaySales = 0;
      int tempTodayOrders = 0;
      int tempActiveOrders = 0;

      for (var order in ordersRes as List) {
        final dt = DateTime.parse(order['created_at']).toLocal();
        final amt = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
        final status = order['order_status'];
        final isCompleted = status == 'completed' || status == 'ready';

        // Process Today's KPIs
        if (dt.isAfter(todayStart) || dt.isAtSameMomentAs(todayStart)) {
          if (isCompleted) {
            tempTodaySales += amt;
            tempTodayOrders++;
          } else if (status == 'active' || status == 'pending') {
            tempActiveOrders++;
          }
        }

        // Process Weekly Chart
        if (isCompleted) {
          // Calculate difference in days from the start of our 7-day window
          final diffDays = DateTime(
            dt.year,
            dt.month,
            dt.day,
          ).difference(weekAgo).inDays;
          if (diffDays >= 0 && diffDays < 7) {
            _weeklySales[diffDays] += amt;
          }
        }
      }

      // Calculate max sale for chart scaling
      _maxWeeklySale = _weeklySales.reduce(math.max);
      if (_maxWeeklySale == 0) _maxWeeklySale = 1; // Prevent division by zero

      // 2. Fetch Low Stock Items (Mocking threshold as < 10 for example, adapt to your needs)
      final inventoryRes = await _supabase
          .from('inventory_items')
          .select('id')
          .lt('current_quantity', 10);

      // 3. Fetch Top Selling Items from order_items
      // Grabbing a sample of recent order items to aggregate top sellers
      final orderItemsRes = await _supabase
          .from('order_items')
          .select('quantity, menu_items(name, price)')
          .limit(500); // Analyze the last 500 items sold

      final Map<String, Map<String, dynamic>> itemAgg = {};
      for (var item in orderItemsRes as List) {
        final name = item['menu_items']?['name'] ?? 'Unknown';
        final qty = (item['quantity'] as num?)?.toInt() ?? 0;
        final price = (item['menu_items']?['price'] as num?)?.toDouble() ?? 0.0;

        if (!itemAgg.containsKey(name)) {
          itemAgg[name] = {'name': name, 'sales': 0, 'price': price};
        }
        itemAgg[name]!['sales'] += qty;
      }

      final topList = itemAgg.values.toList();
      topList.sort((a, b) => (b['sales'] as int).compareTo(a['sales'] as int));

      if (mounted) {
        setState(() {
          _totalSales = tempTodaySales;
          _totalOrders = tempTodayOrders;
          _activeOrders = tempActiveOrders;
          _lowStockCount = (inventoryRes as List).length;
          _recentOrders = List<Map<String, dynamic>>.from(ordersRes.take(6));
          _topItems = topList.take(5).toList();
          _isLoading = false;
        });
        _animationController.forward(from: 0.0);
      }
    } catch (e) {
      debugPrint('Dashboard Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 1000;
                final isTablet =
                    constraints.maxWidth > 650 && constraints.maxWidth <= 1000;

                return _buildMainContent(isDesktop, isTablet);
              },
            ),
    );
  }

  // ─── MAIN DASHBOARD CONTENT ─────────────────────────────────────────────

  Widget _buildMainContent(bool isDesktop, bool isTablet) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Top Header Bar
          Container(
            height: 80,
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Good Morning, Admin',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isDesktop || isTablet)
                        Text(
                          'Here is what\'s happening at Zaytouna Park today.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.refresh, color: Colors.grey.shade700),
                    onPressed: _fetchDashboardData,
                  ),
                ),
                const SizedBox(width: 16),
                const CircleAvatar(
                  backgroundColor: Color(0xFFDCFCE7),
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Dashboard Body
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 32 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // KPI Cards
                  _buildKpiSection(isDesktop, isTablet),

                  SizedBox(height: isDesktop ? 32 : 16),

                  // Charts & Tables Row/Column
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildSalesChart(),
                              const SizedBox(height: 32),
                              _buildRecentOrdersTable(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(flex: 1, child: _buildTopSellingItems()),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSalesChart(),
                        const SizedBox(height: 16),
                        _buildTopSellingItems(),
                        const SizedBox(height: 16),
                        _buildRecentOrdersTable(),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── WIDGET BUILDERS ──────────────────────────────────────────────────

  Widget _buildKpiSection(bool isDesktop, bool isTablet) {
    final kpis = [
      _buildKpiCard(
        'Today\'s Sales',
        '\$${_totalSales.toStringAsFixed(2)}',
        Icons.attach_money,
        const Color(0xFF10B981),
      ),
      _buildKpiCard(
        'Total Orders',
        '$_totalOrders',
        Icons.shopping_bag_outlined,
        const Color(0xFF3B82F6),
      ),
      _buildKpiCard(
        'Active Kitchen',
        '$_activeOrders',
        Icons.restaurant,
        const Color(0xFFF59E0B),
      ),
      _buildKpiCard(
        'Low Stock',
        '$_lowStockCount',
        Icons.warning_amber_rounded,
        const Color(0xFFEF4444),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: kpis
            .map(
              (widget) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: widget == kpis.last ? 0 : 16),
                  child: widget,
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
              Expanded(child: kpis[0]),
              const SizedBox(width: 16),
              Expanded(child: kpis[1]),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: kpis[2]),
              const SizedBox(width: 16),
              Expanded(child: kpis[3]),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: kpis
            .map(
              (widget) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: widget,
              ),
            )
            .toList(),
      );
    }
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Dynamic Bar Chart
  Widget _buildSalesChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Last 7 Days Revenue',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                // Calculate height percentage based on max value
                final heightFactor = _weeklySales[index] / _maxWeeklySale;

                return Tooltip(
                  message: '\$${_weeklySales[index].toStringAsFixed(2)}',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutQuart,
                        width: MediaQuery.of(context).size.width > 600
                            ? 40
                            : 25,
                        // Give it a minimum height of 4px just so zero-sales days are slightly visible
                        height: math.max(4.0, 150 * heightFactor),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              const Color(0xFF10B981),
                              const Color(0xFF34D399).withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _weekDays[index],
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
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

  Widget _buildRecentOrdersTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Orders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          if (_recentOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No recent orders.')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentOrders.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final order = _recentOrders[index];
                final isCompleted =
                    order['order_status'] == 'completed' ||
                    order['order_status'] == 'ready';
                final time = DateTime.parse(order['created_at']).toLocal();

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: isCompleted
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEF3C7),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle_outline
                          : Icons.pending_actions,
                      color: isCompleted
                          ? const Color(0xFF10B981)
                          : const Color(0xFFD97706),
                    ),
                  ),
                  title: Text(
                    'Order #${order['id']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  subtitle: Text(
                    '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${(order['total_amount'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (order['order_status'] as String).toUpperCase(),
                          style: TextStyle(
                            color: isCompleted
                                ? const Color(0xFF059669)
                                : const Color(0xFFD97706),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
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

  Widget _buildTopSellingItems() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Selling Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 24),
          if (_topItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('Not enough data.')),
            )
          else
            ..._topItems.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.fastfood_rounded,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item['sales']} Sales',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${(item['price'] as double).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
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
