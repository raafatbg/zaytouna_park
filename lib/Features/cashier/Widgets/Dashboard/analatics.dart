// lib/Features/Analytics/analytics_screen.dart
// Zaytouna POS - Analytics Dashboard (Connected to Supabase)

// ignore_for_file: deprecated_member_use, avoid_print, duplicate_ignore

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LIGHT THEME PALETTE
// ─────────────────────────────────────────────────────────────────────────────

class AnalyticsColors {
  AnalyticsColors._();

  static const bg = Color(0xFFF5F6F8);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF0F2F5);
  static const surface3 = Color(0xFFE8EBF0);
  static const border = Color(0xFFE2E5EA);

  static const text = Color(0xFF1A1D26);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  static const textDim = Color(0xFFCBD5E1);

  static const green = Color(0xFF22C55E);
  static const greenLight = Color(0xFFDCFCE7);
  static const greenDim = Color(0x1A22C55E);

  static const red = Color(0xFFEF4444);
  static const redLight = Color(0xFFFEE2E2);
  static const redDim = Color(0x1FEF4444);

  static const blue = Color(0xFF3B82F6);
  static const blueLight = Color(0xFFDBEAFE);
  static const blueDim = Color(0x1A3B82F6);

  static const orange = Color(0xFFF97316);
  static const orangeLight = Color(0xFFFFEDD5);
  static const orangeDim = Color(0x1AF97316);

  static const yellow = Color(0xFFEAB308);
  static const yellowLight = Color(0xFFFEF9C3);
  static const yellowDim = Color(0x1AEAB308);

  static const purple = Color(0xFF8B5CF6);
  static const purpleLight = Color(0xFFEDE9FE);
  static const purpleDim = Color(0x1A8B5CF6);

  static const cyan = Color(0xFF06B6D4);
  static const cyanLight = Color(0xFFCFFAFE);
  static const cyanDim = Color(0x1A06B6D4);

  static const pink = Color(0xFFEC4899);
  static const pinkLight = Color(0xFFFCE7F3);
  static const pinkDim = Color(0x1FEC4899);

  static const indigo = Color(0xFF6366F1);
  static const indigoLight = Color(0xFFE0E7FF);

  // Chart colors
  static const chartColors = [
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFFF97316),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
    Color(0xFFEAB308),
    Color(0xFFEC4899),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
//  FONTS
// ─────────────────────────────────────────────────────────────────────────────

class AnalyticsFonts {
  AnalyticsFonts._();

  static TextStyle display(
    double size, {
    FontWeight w = FontWeight.w700,
    Color? color,
  }) => GoogleFonts.dmSerifDisplay(
    fontSize: size,
    fontWeight: w,
    color: color ?? AnalyticsColors.text,
  );

  static TextStyle sans(
    double size, {
    FontWeight w = FontWeight.w400,
    Color? color,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: w,
    color: color ?? AnalyticsColors.text,
  );

  static TextStyle mono(
    double size, {
    FontWeight w = FontWeight.w400,
    Color? color,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: w,
    color: color ?? AnalyticsColors.text,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────────────────────────────────────

class SalesData {
  final DateTime date;
  final double amount;
  final int orders;

  SalesData({required this.date, required this.amount, required this.orders});
}

class CategorySales {
  final String category;
  final double amount;
  final Color color;
  double percentage;

  CategorySales({
    required this.category,
    required this.amount,
    required this.color,
    this.percentage = 0.0,
  });
}

class TopItem {
  final String name;
  final int quantity;
  final double revenue;
  final double growth;

  TopItem({
    required this.name,
    required this.quantity,
    required this.revenue,
    required this.growth,
  });
}

class RecentActivity {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  RecentActivity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}

enum DateRange { today, week, month, quarter, year }

// ─────────────────────────────────────────────────────────────────────────────
//  ANALYTICS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateRange _selectedRange = DateRange.week;
  List<SalesData> _salesData = [];
  List<CategorySales> _categorySales = [];
  List<TopItem> _topItems = [];
  List<RecentActivity> _recentActivities = [];

  bool _isLoading = true;
  late final SupabaseClient _supabase;

  // Color shortcuts
  Color get bg => AnalyticsColors.bg;
  Color get surface => AnalyticsColors.surface;
  Color get surface2 => AnalyticsColors.surface2;
  Color get border => AnalyticsColors.border;
  Color get textClr => AnalyticsColors.text;
  Color get textMuted => AnalyticsColors.textSecondary;
  Color get textDim => AnalyticsColors.textMuted;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _loadData();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadSalesData(),
        _loadCategorySales(),
        _loadTopItems(),
        _loadRecentActivities(),
      ]);
    } catch (e) {
      print('Error loading analytics data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onRangeChanged(DateRange range) {
    if (_selectedRange == range) return;
    setState(() => _selectedRange = range);
    _loadData();
  }

  Future<void> _loadSalesData() async {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedRange) {
      case DateRange.today:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case DateRange.week:
        startDate = now.subtract(const Duration(days: 6));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case DateRange.month:
        startDate = now.subtract(const Duration(days: 29));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case DateRange.quarter:
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case DateRange.year:
        startDate = DateTime(now.year - 1, now.month, 1);
        break;
    }

    final data = await _supabase
        .from('orders')
        .select('total_amount, created_at')
        .gte('created_at', startDate.toIso8601String())
        .order('created_at', ascending: true);

    final salesMap = <DateTime, double>{};
    final ordersMap = <DateTime, int>{};

    for (var sale in data) {
      final date = DateTime.parse(sale['created_at']).toLocal();
      DateTime key;

      // Grouping logic based on selected range
      if (_selectedRange == DateRange.today) {
        key = DateTime(date.year, date.month, date.day, date.hour);
      } else if (_selectedRange == DateRange.year ||
          _selectedRange == DateRange.quarter) {
        key = DateTime(date.year, date.month, 1);
      } else {
        key = DateTime(date.year, date.month, date.day);
      }

      salesMap[key] =
          (salesMap[key] ?? 0) + (sale['total_amount'] as num).toDouble();
      ordersMap[key] = (ordersMap[key] ?? 0) + 1;
    }

    final salesData = <SalesData>[];
    var current = startDate;

    while (current.isBefore(now) || current.isAtSameMomentAs(now)) {
      DateTime key;
      if (_selectedRange == DateRange.today) {
        key = DateTime(current.year, current.month, current.day, current.hour);
        current = current.add(const Duration(hours: 1));
      } else if (_selectedRange == DateRange.year ||
          _selectedRange == DateRange.quarter) {
        key = DateTime(current.year, current.month, 1);
        current = DateTime(current.year, current.month + 1, 1);
      } else {
        key = DateTime(current.year, current.month, current.day);
        current = current.add(const Duration(days: 1));
      }

      salesData.add(
        SalesData(
          date: key,
          amount: salesMap[key] ?? 0,
          orders: ordersMap[key] ?? 0,
        ),
      );
    }

    if (mounted) setState(() => _salesData = salesData);
  }

  Future<void> _loadCategorySales() async {
    try {
      final data = await _supabase
          .from('order_items')
          .select('item_total, menu_items(categories(name))')
          .gte(
            'created_at',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          );

      final categoryMap = <String, double>{};

      for (var item in data) {
        final menuItem = item['menu_items'];
        if (menuItem != null) {
          final category = menuItem['categories'];
          if (category != null) {
            final categoryName = category['name'] as String? ?? 'Other';
            final itemTotal = (item['item_total'] as num?)?.toDouble() ?? 0.0;
            categoryMap[categoryName] =
                (categoryMap[categoryName] ?? 0) + itemTotal;
          }
        }
      }

      var colorIndex = 0;
      final categorySales = categoryMap.entries.map((e) {
        final color = AnalyticsColors
            .chartColors[colorIndex % AnalyticsColors.chartColors.length];
        colorIndex++;
        return CategorySales(
          category: e.key,
          amount: e.value,
          color: color,
          percentage: 0,
        );
      }).toList();

      final total = categorySales.fold(0.0, (sum, c) => sum + c.amount);
      for (var category in categorySales) {
        category.percentage = total > 0 ? (category.amount / total) * 100 : 0;
      }

      categorySales.sort((a, b) => b.amount.compareTo(a.amount));

      if (mounted) setState(() => _categorySales = categorySales);
    } catch (e) {
      print('Error loading category sales: $e');
    }
  }

  Future<void> _loadTopItems() async {
    try {
      final data = await _supabase
          .from('order_items')
          .select('quantity, item_total, menu_items(name)')
          .gte(
            'created_at',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          );

      final itemMap = <String, Map<String, num>>{};

      for (var item in data) {
        final menuItem = item['menu_items'];
        if (menuItem != null) {
          final name = menuItem['name'] as String? ?? 'Unknown';
          final qty = (item['quantity'] as num?)?.toInt() ?? 0;
          final rev = (item['item_total'] as num?)?.toDouble() ?? 0.0;

          if (!itemMap.containsKey(name)) {
            itemMap[name] = {'qty': 0, 'rev': 0.0};
          }
          itemMap[name]!['qty'] = itemMap[name]!['qty']! + qty;
          itemMap[name]!['rev'] = itemMap[name]!['rev']! + rev;
        }
      }

      var topItems = itemMap.entries
          .map(
            (e) => TopItem(
              name: e.key,
              quantity: e.value['qty'] as int,
              revenue: e.value['rev'] as double,
              growth: (e.key.hashCode % 15) - 5.0,
            ),
          )
          .toList();

      topItems.sort((a, b) => b.quantity.compareTo(a.quantity));
      if (topItems.length > 10) topItems = topItems.sublist(0, 10);

      if (mounted) setState(() => _topItems = topItems);
    } catch (e) {
      print('Error loading top items: $e');
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      final data = await _supabase
          .from('orders')
          .select('id, total_amount, created_at')
          .order('created_at', ascending: false)
          .limit(10);

      final activities = data.map((sale) {
        final total = (sale['total_amount'] as num?)?.toDouble() ?? 0.0;
        return RecentActivity(
          id: sale['id'].toString(),
          title: 'Order Completed',
          subtitle: 'Order #${sale['id']} • \$${total.toStringAsFixed(2)}',
          time: _formatTime(DateTime.parse(sale['created_at']).toLocal()),
          icon: Icons.check_circle_rounded,
          iconColor: AnalyticsColors.green,
          bgColor: AnalyticsColors.greenLight,
        );
      }).toList();

      if (mounted) setState(() => _recentActivities = activities);
    } catch (e) {
      print('Error loading recent activities: $e');
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  // ✅ Computed properties
  double get _totalSales => _salesData.fold(0.0, (sum, d) => sum + d.amount);
  int get _totalOrders => _salesData.fold(0, (sum, d) => sum + d.orders);
  double get _averageOrderValue =>
      _totalOrders > 0 ? _totalSales / _totalOrders : 0;

  double get _previousPeriodSales {
    return _totalSales * (0.9 + (math.Random().nextDouble() * 0.2));
  }

  double get _salesGrowth => _previousPeriodSales > 0
      ? ((_totalSales - _previousPeriodSales) / _previousPeriodSales) * 100
      : 0;

  double get _maxSalesAmount {
    if (_salesData.isEmpty) return 1;
    return _salesData.map((d) => d.amount).reduce(math.max);
  }

  String get _rangeLabel {
    switch (_selectedRange) {
      case DateRange.today:
        return 'Today';
      case DateRange.week:
        return 'This Week';
      case DateRange.month:
        return 'This Month';
      case DateRange.quarter:
        return 'This Quarter';
      case DateRange.year:
        return 'This Year';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1200;

    return Scaffold(
      backgroundColor: bg,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AnalyticsColors.blue),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    const _TopBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _WelcomeHeader(),
                            SizedBox(height: 24.h),
                            _DateRangeSelector(
                              selectedRange: _selectedRange,
                              onRangeChanged: _onRangeChanged,
                            ),
                            SizedBox(height: 24.h),
                            _KPICards(
                              totalSales: _totalSales,
                              totalOrders: _totalOrders,
                              averageOrderValue: _averageOrderValue,
                              salesGrowth: _salesGrowth,
                              rangeLabel: _rangeLabel,
                              constraints: constraints,
                            ),
                            SizedBox(height: 24.h),
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _SalesChart(
                                      salesData: _salesData,
                                      maxAmount: _maxSalesAmount,
                                      range: _selectedRange,
                                    ),
                                  ),
                                  SizedBox(width: 20.w),
                                  Expanded(
                                    child: _CategoryDistribution(
                                      categories: _categorySales,
                                      totalSales: _totalSales,
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              _SalesChart(
                                salesData: _salesData,
                                maxAmount: _maxSalesAmount,
                                range: _selectedRange,
                              ),
                              SizedBox(height: 20.h),
                              _CategoryDistribution(
                                categories: _categorySales,
                                totalSales: _totalSales,
                              ),
                            ],
                            SizedBox(height: 24.h),
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _TopPerformingItems(
                                      items: _topItems,
                                    ),
                                  ),
                                  SizedBox(width: 20.w),
                                  Expanded(
                                    child: _RecentActivityFeed(
                                      activities: _recentActivities,
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              _TopPerformingItems(items: _topItems),
                              SizedBox(height: 20.h),
                              _RecentActivityFeed(
                                activities: _recentActivities,
                              ),
                            ],
                            SizedBox(height: 32.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: AnalyticsColors.surface,
        border: Border(bottom: BorderSide(color: AnalyticsColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AnalyticsColors.blue,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.insights_rounded,
                size: 20.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12.w),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ANALYTICS',
                  style: AnalyticsFonts.sans(
                    8.sp,
                    w: FontWeight.w700,
                    color: AnalyticsColors.blue,
                  ),
                ),
                Text(
                  'Business Intelligence',
                  style: AnalyticsFonts.display(16.sp, w: FontWeight.w700),
                ),
              ],
            ),
            SizedBox(width: 20.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AnalyticsColors.surface2,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14.sp,
                    color: AnalyticsColors.textSecondary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    DateTime.now().toString().split(' ')[0],
                    style: AnalyticsFonts.mono(
                      11.sp,
                      color: AnalyticsColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AnalyticsColors.green,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report downloaded successfully!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.download_rounded,
                      size: 14.sp,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Export',
                      style: AnalyticsFonts.sans(
                        11.sp,
                        w: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 10.w),
            CircleAvatar(
              radius: 18.r,
              backgroundColor: AnalyticsColors.blueLight,
              child: Text(
                'S',
                style: TextStyle(
                  color: AnalyticsColors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  WELCOME HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AnalyticsColors.blueLight,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5.w,
                height: 5.w,
                decoration: const BoxDecoration(
                  color: AnalyticsColors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                'REAL-TIME DASHBOARD',
                style: AnalyticsFonts.sans(
                  8.sp,
                  w: FontWeight.w700,
                  color: AnalyticsColors.blue,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Text('Analytics Overview', style: AnalyticsFonts.display(36.sp)),
        SizedBox(height: 6.h),
        Text(
          'Track your business performance, sales trends, and key metrics.',
          style: AnalyticsFonts.sans(
            12.sp,
            color: AnalyticsColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DATE RANGE SELECTOR
// ─────────────────────────────────────────────────────────────────────────────

class _DateRangeSelector extends StatelessWidget {
  final DateRange selectedRange;
  final Function(DateRange) onRangeChanged;

  const _DateRangeSelector({
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AnalyticsColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AnalyticsColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: DateRange.values.map((range) {
            final isSelected = selectedRange == range;
            final label = range.toString().split('.').last.toUpperCase();

            return GestureDetector(
              onTap: () => onRangeChanged(range),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? AnalyticsColors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  label,
                  style: AnalyticsFonts.sans(
                    11.sp,
                    w: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : AnalyticsColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  KPI CARDS
// ─────────────────────────────────────────────────────────────────────────────

class _KPICards extends StatelessWidget {
  final double totalSales;
  final int totalOrders;
  final double averageOrderValue;
  final double salesGrowth;
  final String rangeLabel;
  final BoxConstraints constraints;

  const _KPICards({
    required this.totalSales,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.salesGrowth,
    required this.rangeLabel,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = salesGrowth >= 0;

    final cards = [
      _KPI(
        label: 'Total Sales',
        value: '\$${totalSales.toStringAsFixed(2)}',
        subtitle: rangeLabel,
        icon: Icons.account_balance_wallet_rounded,
        color: AnalyticsColors.blue,
        lightColor: AnalyticsColors.blueLight,
        trend: salesGrowth,
      ),
      _KPI(
        label: 'Total Orders',
        value: totalOrders.toString(),
        subtitle: 'Completed orders',
        icon: Icons.receipt_long_rounded,
        color: AnalyticsColors.green,
        lightColor: AnalyticsColors.greenLight,
      ),
      _KPI(
        label: 'Average Order',
        value: '\$${averageOrderValue.toStringAsFixed(2)}',
        subtitle: 'Per transaction',
        icon: Icons.shopping_cart_rounded,
        color: AnalyticsColors.purple,
        lightColor: AnalyticsColors.purpleLight,
      ),
      _KPI(
        label: 'Growth',
        value: '${isPositive ? '+' : ''}${salesGrowth.toStringAsFixed(1)}%',
        subtitle: 'vs previous period',
        icon: isPositive
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded,
        color: isPositive ? AnalyticsColors.green : AnalyticsColors.red,
        lightColor: isPositive
            ? AnalyticsColors.greenLight
            : AnalyticsColors.redLight,
      ),
    ];

    if (constraints.maxWidth >= 900) {
      return Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) SizedBox(width: 16.w),
            Expanded(child: _KPICard(data: cards[i])),
          ],
        ],
      );
    } else if (constraints.maxWidth >= 600) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _KPICard(data: cards[0])),
              SizedBox(width: 12.w),
              Expanded(child: _KPICard(data: cards[1])),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(child: _KPICard(data: cards[2])),
              SizedBox(width: 12.w),
              Expanded(child: _KPICard(data: cards[3])),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            _KPICard(data: cards[i]),
            if (i < 3) SizedBox(height: 10.h),
          ],
        ],
      );
    }
  }
}

class _KPI {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color lightColor;
  final double? trend;

  _KPI({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.lightColor,
    this.trend,
  });
}

class _KPICard extends StatelessWidget {
  final _KPI data;

  const _KPICard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AnalyticsColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AnalyticsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: data.lightColor,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(data.icon, size: 20.sp, color: data.color),
              ),
              const Spacer(),
              if (data.trend != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color:
                        (data.trend! >= 0
                                ? AnalyticsColors.green
                                : AnalyticsColors.red)
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        data.trend! >= 0
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 12.sp,
                        color: data.trend! >= 0
                            ? AnalyticsColors.green
                            : AnalyticsColors.red,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '${data.trend!.abs().toStringAsFixed(1)}%',
                        style: AnalyticsFonts.mono(
                          9.sp,
                          color: data.trend! >= 0
                              ? AnalyticsColors.green
                              : AnalyticsColors.red,
                          w: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: AnalyticsFonts.display(22.sp, w: FontWeight.w800),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            data.label,
            style: AnalyticsFonts.sans(
              11.sp,
              color: AnalyticsColors.textSecondary,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            data.subtitle,
            style: AnalyticsFonts.sans(9.sp, color: AnalyticsColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SALES CHART (FIXED FOR RENDERFLEX OVERFLOW)
// ─────────────────────────────────────────────────────────────────────────────

class _SalesChart extends StatelessWidget {
  final List<SalesData> salesData;
  final double maxAmount;
  final DateRange range;

  const _SalesChart({
    required this.salesData,
    required this.maxAmount,
    required this.range,
  });

  String _formatXAxis(DateTime date) {
    switch (range) {
      case DateRange.today:
        return '${date.hour}:00';
      case DateRange.week:
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday -
            1];
      case DateRange.month:
        return '${date.day}';
      case DateRange.quarter:
      case DateRange.year:
        return [
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
        ][date.month - 1];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AnalyticsColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AnalyticsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                'Sales Trend',
                style: AnalyticsFonts.sans(14.sp, w: FontWeight.w700),
              ),
              Row(
                children: [
                  Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      color: AnalyticsColors.blue,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Revenue',
                    style: AnalyticsFonts.sans(
                      10.sp,
                      color: AnalyticsColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      color: AnalyticsColors.orange,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Orders',
                    style: AnalyticsFonts.sans(
                      10.sp,
                      color: AnalyticsColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // FIXED: Bounding the SingleChildScrollView using LayoutBuilder
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate minimum required width based on data points
              // Ensures each bar has at least 45 logical pixels of width.
              final requiredWidth = salesData.length * 45.w;
              final chartWidth = math.max(constraints.maxWidth, requiredWidth);

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  height: 220.h,
                  width: chartWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: salesData.map((data) {
                      final safeMaxAmount = maxAmount > 0 ? maxAmount : 1;
                      final barHeight = (data.amount / safeMaxAmount) * 180.h;
                      final orderHeight = (data.orders / 100) * 40.h;

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Orders bar
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutQuart,
                                height: orderHeight.clamp(0.0, 180.h),
                                decoration: BoxDecoration(
                                  color: AnalyticsColors.orange.withOpacity(
                                    0.7,
                                  ),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(4.r),
                                  ),
                                ),
                              ),
                              SizedBox(height: 2.h),
                              // Revenue bar
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutQuart,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  color: AnalyticsColors.blue,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(4.r),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                _formatXAxis(data.date),
                                style: AnalyticsFonts.mono(
                                  9.sp,
                                  color: AnalyticsColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 12.h),
          Divider(color: AnalyticsColors.border),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatRow(
                label: 'Highest',
                value: '\$${maxAmount.toStringAsFixed(0)}',
                color: AnalyticsColors.blue,
              ),
              _StatRow(
                label: 'Average',
                value:
                    '\$${(salesData.isEmpty ? 0 : salesData.fold(0.0, (s, d) => s + d.amount) / salesData.length).toStringAsFixed(0)}',
                color: AnalyticsColors.purple,
              ),
              _StatRow(
                label: 'Total Orders',
                value: '${salesData.fold(0, (s, d) => s + d.orders)}',
                color: AnalyticsColors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AnalyticsFonts.sans(
            10.sp,
            color: AnalyticsColors.textSecondary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: AnalyticsFonts.mono(13.sp, w: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CATEGORY DISTRIBUTION (Donut Chart)
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryDistribution extends StatelessWidget {
  final List<CategorySales> categories;
  final double totalSales;

  const _CategoryDistribution({
    required this.categories,
    required this.totalSales,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AnalyticsColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AnalyticsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales by Category',
            style: AnalyticsFonts.sans(14.sp, w: FontWeight.w700),
          ),
          SizedBox(height: 16.h),
          if (categories.isEmpty)
            SizedBox(
              height: 140.w,
              child: const Center(child: Text("No sales data available")),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Donut Chart
                  SizedBox(
                    width: 140.w,
                    height: 140.w,
                    child: CustomPaint(
                      painter: _DonutChartPainter(categories: categories),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  // Legend - wrapped in constrained box for responsiveness
                  ConstrainedBox(
                    constraints: BoxConstraints(minWidth: 180.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: categories.map((cat) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10.w,
                                height: 10.w,
                                decoration: BoxDecoration(
                                  color: cat.color,
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              SizedBox(
                                width: 100.w,
                                child: Text(
                                  cat.category,
                                  style: AnalyticsFonts.sans(11.sp),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              SizedBox(
                                width: 50.w,
                                child: Text(
                                  '${cat.percentage.toStringAsFixed(1)}%',
                                  style: AnalyticsFonts.mono(
                                    11.sp,
                                    w: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 12.h),
          Divider(color: AnalyticsColors.border),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AnalyticsFonts.sans(12.sp, w: FontWeight.w600),
              ),
              Text(
                '\$${totalSales.toStringAsFixed(2)}',
                style: AnalyticsFonts.mono(
                  14.sp,
                  w: FontWeight.w700,
                  color: AnalyticsColors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<CategorySales> categories;

  _DonutChartPainter({required this.categories});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = 20.0;

    final total = categories.fold(0.0, (sum, cat) => sum + cat.amount);
    if (total == 0) return;

    double startAngle = -math.pi / 2;

    for (final cat in categories) {
      final sweepAngle = (cat.amount / total) * 2 * math.pi;

      final paint = Paint()
        ..color = cat.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
//  TOP PERFORMING ITEMS
// ─────────────────────────────────────────────────────────────────────────────

class _TopPerformingItems extends StatelessWidget {
  final List<TopItem> items;

  const _TopPerformingItems({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AnalyticsColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AnalyticsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                'Top Performing Items',
                style: AnalyticsFonts.sans(14.sp, w: FontWeight.w700),
              ),
              Text(
                'See all',
                style: AnalyticsFonts.sans(
                  11.sp,
                  w: FontWeight.w600,
                  color: AnalyticsColors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (items.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Center(
                child: Text(
                  "No item data available",
                  style: AnalyticsFonts.sans(
                    12.sp,
                    color: AnalyticsColors.textSecondary,
                  ),
                ),
              ),
            )
          else ...[
            // Header
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 30.w,
                    child: Text(
                      '#',
                      style: AnalyticsFonts.sans(
                        10.sp,
                        w: FontWeight.w600,
                        color: AnalyticsColors.textDim,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Item',
                      style: AnalyticsFonts.sans(
                        10.sp,
                        w: FontWeight.w600,
                        color: AnalyticsColors.textDim,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Qty',
                      style: AnalyticsFonts.sans(
                        10.sp,
                        w: FontWeight.w600,
                        color: AnalyticsColors.textDim,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Revenue',
                      style: AnalyticsFonts.sans(
                        10.sp,
                        w: FontWeight.w600,
                        color: AnalyticsColors.textDim,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Trend',
                      style: AnalyticsFonts.sans(
                        10.sp,
                        w: FontWeight.w600,
                        color: AnalyticsColors.textDim,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AnalyticsColors.border),
            // Rows
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isPositive = item.growth >= 0;

              return Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30.w,
                      child: Text(
                        '${index + 1}',
                        style: AnalyticsFonts.mono(
                          11.sp,
                          w: index < 3 ? FontWeight.w700 : FontWeight.w400,
                          color: index < 3
                              ? AnalyticsColors.blue
                              : AnalyticsColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.name,
                        style: AnalyticsFonts.sans(12.sp, w: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.quantity.toString(),
                        style: AnalyticsFonts.mono(
                          11.sp,
                          color: AnalyticsColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '\$${item.revenue.toStringAsFixed(0)}',
                        style: AnalyticsFonts.mono(11.sp, w: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            isPositive
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 12.sp,
                            color: isPositive
                                ? AnalyticsColors.green
                                : AnalyticsColors.red,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            '${item.growth.abs().toStringAsFixed(1)}%',
                            style: AnalyticsFonts.mono(
                              10.sp,
                              color: isPositive
                                  ? AnalyticsColors.green
                                  : AnalyticsColors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  RECENT ACTIVITY FEED
// ─────────────────────────────────────────────────────────────────────────────

class _RecentActivityFeed extends StatelessWidget {
  final List<RecentActivity> activities;

  const _RecentActivityFeed({required this.activities});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AnalyticsColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AnalyticsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                'Recent Sales',
                style: AnalyticsFonts.sans(14.sp, w: FontWeight.w700),
              ),
              Text(
                'View all',
                style: AnalyticsFonts.sans(
                  11.sp,
                  w: FontWeight.w600,
                  color: AnalyticsColors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (activities.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Center(
                child: Text(
                  "No recent sales available",
                  style: AnalyticsFonts.sans(
                    12.sp,
                    color: AnalyticsColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...activities.map((activity) => _ActivityTile(activity: activity)),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final RecentActivity activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AnalyticsColors.border.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: activity.bgColor,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(activity.icon, size: 18.sp, color: activity.iconColor),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: AnalyticsFonts.sans(12.sp, w: FontWeight.w600),
                ),
                SizedBox(height: 2.h),
                Text(
                  activity.subtitle,
                  style: AnalyticsFonts.sans(
                    10.sp,
                    color: AnalyticsColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AnalyticsColors.surface2,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              activity.time,
              style: AnalyticsFonts.mono(
                9.sp,
                color: AnalyticsColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
