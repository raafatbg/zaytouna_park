// ignore_for_file: deprecated_member_use, use_build_context_synchronously, camel_case_types
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zaytouna_park/Core/Routers/route_guard.dart';
import 'package:zaytouna_park/Core/Routers/routes.dart';

// ─── RESPONSIVE BREAKPOINTS ────────────────────────────────────────────────
class _Bp {
  _Bp._();
  static const double phone = 600;
  static const double tabletPortrait = 900;
  static const double tabletLandscape = 1200;
  static const double wide = 1600;

  static bool isPhone(double w) => w < phone;
  static bool isWide(double w) => w >= wide;
}

// ─── DISPLAY CURRENCY ──────────────────────────────────────────────────────
class Money {
  static const String code = 'USD';
  static const String symbol = '\$';
}

// ─── COLOR PALETTE ─────────────────────────────────────────────────────────
class ZaytounaColors {
  ZaytounaColors._();
  static const primary = Color(0xFFB8860B);
  static const primaryDark = Color(0xFF8B6914);
  static const primaryLight = Color(0xFFFFD700);
  static const bg = Color(0xFFFFFFFF);
  static const bgSecondary = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFF1F3F5);
  static const border = Color(0xFFE9ECEF);
  static const textPrimary = Color(0xFF212529);
  static const textSecondary = Color(0xFF6C757D);
  static const textTertiary = Color(0xFFADB5BD);
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const danger = Color(0xFFEF4444);
  static const dangerLight = Color(0xFFFEE2E2);
  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFFDBEAFE);
}

// ─── TYPOGRAPHY ────────────────────────────────────────────────────────────
class ZaytounaTypography {
  static TextStyle displayLarge({
    FontWeight weight = FontWeight.w700,
    Color? color,
    double fontSize = 48,
  }) => GoogleFonts.inter(
    fontSize: fontSize.sp,
    fontWeight: weight,
    letterSpacing: -0.5,
    color: color ?? ZaytounaColors.textPrimary,
  );

  static TextStyle heading({
    FontWeight weight = FontWeight.w600,
    Color? color,
    double fontSize = 24,
  }) => GoogleFonts.inter(
    fontSize: fontSize.sp,
    fontWeight: weight,
    letterSpacing: -0.2,
    color: color ?? ZaytounaColors.textPrimary,
  );

  static TextStyle subheading({
    FontWeight weight = FontWeight.w600,
    Color? color,
    double fontSize = 18,
  }) => GoogleFonts.inter(
    fontSize: fontSize.sp,
    fontWeight: weight,
    letterSpacing: -0.1,
    color: color ?? ZaytounaColors.textPrimary,
  );

  static TextStyle body({
    FontWeight weight = FontWeight.w400,
    Color? color,
    double fontSize = 15,
  }) => GoogleFonts.inter(
    fontSize: fontSize.sp,
    fontWeight: weight,
    color: color ?? ZaytounaColors.textSecondary,
  );

  static TextStyle caption({
    FontWeight weight = FontWeight.w500,
    Color? color,
    double fontSize = 12,
  }) => GoogleFonts.inter(
    fontSize: fontSize.sp,
    fontWeight: weight,
    letterSpacing: 0.3,
    color: color ?? ZaytounaColors.textTertiary,
  );
}

// ─── MODELS ────────────────────────────────────────────────────────────────
class MenuTileData {
  final String title;
  final IconData icon;
  final Color iconColor, bgColor;
  final String route;

  const MenuTileData({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.route,
  });
}

class SaleMetrics {
  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final int itemsSold;
  final DateTime timestamp;

  SaleMetrics({
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.itemsSold,
    required this.timestamp,
  });
}

// ─── HOME SCREEN ───────────────────────────────────────────────────────────
class PremiumCashierHome extends StatefulWidget {
  final VoidCallback onLaunchTerminal;

  const PremiumCashierHome({super.key, required this.onLaunchTerminal});

  @override
  State<PremiumCashierHome> createState() => _PremiumCashierHomeState();
}

class _PremiumCashierHomeState extends State<PremiumCashierHome>
    with SingleTickerProviderStateMixin {
  late final SupabaseClient _supabase;
  late final AnimationController _animationController;

  SaleMetrics? _cachedMetrics;
  DateTime? _lastFetchTime;
  RealtimeChannel? _realtimeChannel;
  Timer? _refreshDebounce;
  late Future<List<dynamic>> _recentOrdersFuture;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _recentOrdersFuture = _fetchRecentOrders();
    _setupRealtimeSubscriptions();
    _fetchMetrics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshDebounce?.cancel();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  // ─── DATA ────────────────────────────────────────────────────────────────
  void _setupRealtimeSubscriptions() {
    _realtimeChannel = _supabase
        .channel('dashboard_orders_insert')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            if (!mounted) return;
            HapticFeedback.lightImpact();
            _showNewOrderNotification(payload.newRecord['id']?.toString());
            _scheduleRefresh();
          },
        )
        .subscribe();
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(seconds: 2), () {
      _cachedMetrics = null;
      _fetchMetrics();
      setState(() => _recentOrdersFuture = _fetchRecentOrders());
    });
  }

  Future<List<dynamic>> _fetchRecentOrders() async {
    return await _supabase
        .from('orders')
        .select('id, total_amount, created_at, status')
        .neq('status', 'voided')
        .order('created_at', ascending: false)
        .limit(5);
  }

  Future<void> _fetchMetrics() async {
    if (_cachedMetrics != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inSeconds < 30) {
      return;
    }
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final salesData = await _supabase
          .from('orders')
          .select('id, total_amount')
          .gte('created_at', startOfDay.toIso8601String())
          .neq('status', 'voided');

      final orderIds = (salesData as List<dynamic>)
          .map((o) => o['id'])
          .toList();

      int itemsSold = 0;
      if (orderIds.isNotEmpty) {
        final itemsData = await _supabase
            .from('order_items')
            .select('quantity')
            .inFilter('order_id', orderIds);
        itemsSold = (itemsData as List<dynamic>).fold(
          0,
          (sum, item) => sum + (item['quantity'] as int? ?? 0),
        );
      }

      final revenue = salesData.fold<double>(
        0.0,
        (sum, item) => sum + ((item['total_amount'] as num?) ?? 0).toDouble(),
      );
      final totalSalesCount = salesData.length;
      final avgOrder = totalSalesCount > 0 ? revenue / totalSalesCount : 0.0;

      if (mounted) {
        setState(() {
          _cachedMetrics = SaleMetrics(
            totalOrders: totalSalesCount,
            totalRevenue: revenue,
            averageOrderValue: avgOrder,
            itemsSold: itemsSold,
            timestamp: now,
          );
          _lastFetchTime = now;
        });
      }
    } catch (e, st) {
      developer.log('Error fetching metrics', error: e, stackTrace: st);
      if (mounted && _cachedMetrics == null) {
        setState(() {
          _cachedMetrics = SaleMetrics(
            totalOrders: 0,
            totalRevenue: 0.0,
            averageOrderValue: 0.0,
            itemsSold: 0,
            timestamp: DateTime.now(),
          );
        });
      }
    }
  }

  // ─── UI HELPERS ──────────────────────────────────────────────────────────
  void _showNewOrderNotification(String? orderId) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                orderId != null
                    ? 'New order #$orderId received!'
                    : 'New order received!',
                style: ZaytounaTypography.body(
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: ZaytounaColors.primary,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () => context.push(Routes.orders),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: ZaytounaColors.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: ZaytounaColors.dangerLight,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: ZaytounaColors.danger,
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 20.h),
              Text('Sign Out', style: ZaytounaTypography.heading()),
              SizedBox(height: 12.h),
              Text(
                'Are you sure you want to sign out?',
                style: ZaytounaTypography.body(),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 28.h),
              Row(
                children: [
                  Expanded(
                    child: _buildButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.pop(context, false),
                      variant: 'secondary',
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildButton(
                      label: 'Sign Out',
                      onPressed: () => Navigator.pop(context, true),
                      variant: 'danger',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true && mounted) {
      await RouteGuard.logout();
      if (mounted) context.go(Routes.login);
    }
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    String variant = 'primary',
  }) {
    final isPrimary = variant == 'primary';
    final isDanger = variant == 'danger';
    final isSecondary = variant == 'secondary';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isDanger
                ? ZaytounaColors.danger
                : isPrimary
                ? ZaytounaColors.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: isSecondary
                ? Border.all(color: ZaytounaColors.border, width: 1.5)
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: ZaytounaTypography.body(
                weight: FontWeight.w600,
                color: isDanger || isPrimary
                    ? Colors.white
                    : ZaytounaColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZaytounaColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isPhone = _Bp.isPhone(w);

            final double hPad = isPhone
                ? 12
                : _Bp.isWide(w)
                ? 32
                : 24;

            return FadeTransition(
              opacity: _animationController.drive(
                Tween<double>(begin: 0.0, end: 1.0),
              ),
              child: RefreshIndicator(
                color: ZaytounaColors.primary,
                onRefresh: () async {
                  _cachedMetrics = null;
                  await _fetchMetrics();
                  setState(() => _recentOrdersFuture = _fetchRecentOrders());
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad.w, 12.h, hPad.w, 0),
                      sliver: SliverToBoxAdapter(
                        child: _buildProHeader(isPhone: isPhone),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad.w, 16.h, hPad.w, 32.h),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildQuickLaunch(isPhone: isPhone),
                          SizedBox(height: isPhone ? 24.h : 32.h),
                          _buildMetrics(maxWidth: w),
                          SizedBox(height: isPhone ? 28.h : 40.h),
                          Text(
                            'Venue Management',
                            style: ZaytounaTypography.heading(
                              fontSize: isPhone ? 20 : 24,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          _buildMenuGrid(context, maxWidth: w),
                          SizedBox(height: isPhone ? 28.h : 40.h),
                          _buildRecentActivity(isPhone: isPhone),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── HEADER (plain, not Sliver) ──────────────────────────────────────────
  Widget _buildProHeader({required bool isPhone}) {
    final user = RouteGuard.user;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isPhone ? 4 : 8, vertical: 8),
      child: Row(
        children: [
          Container(
            height: isPhone ? 44 : 54,
            width: isPhone ? 44 : 54,
            decoration: BoxDecoration(
              color: ZaytounaColors.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: ZaytounaColors.primary.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: ZaytounaColors.primary.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.all(isPhone ? 6 : 8),
            child: Image.asset(
              'assets/logo/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.storefront_rounded,
                color: ZaytounaColors.primary,
                size: (isPhone ? 22 : 28).sp,
              ),
            ),
          ),
          SizedBox(width: isPhone ? 10.w : 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.fullName.isNotEmpty == true
                      ? user!.fullName
                      : 'Zaytouna Staff',
                  style: ZaytounaTypography.heading(
                    fontSize: isPhone ? 16 : 20,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  (user?.role ?? 'Cashier').toUpperCase(),
                  style: ZaytounaTypography.caption(
                    weight: FontWeight.w700,
                    color: ZaytounaColors.primary,
                    fontSize: isPhone ? 10 : 12,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleLogout,
              borderRadius: BorderRadius.circular(14.r),
              child: Container(
                padding: EdgeInsets.all(isPhone ? 9 : 12),
                decoration: BoxDecoration(
                  color: ZaytounaColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: ZaytounaColors.border, width: 1),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: ZaytounaColors.textSecondary,
                  size: (isPhone ? 18 : 20).sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── QUICK LAUNCH ────────────────────────────────────────────────────────
  Widget _buildQuickLaunch({required bool isPhone}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onLaunchTerminal,
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          padding: EdgeInsets.all(isPhone ? 18.w : 24.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ZaytounaColors.primary.withOpacity(0.12),
                ZaytounaColors.primary.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: ZaytounaColors.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ready to Serve',
                      style: ZaytounaTypography.caption(
                        color: ZaytounaColors.primaryDark,
                        weight: FontWeight.w700,
                        fontSize: isPhone ? 11 : 13,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Point of Sale Terminal',
                      style: ZaytounaTypography.heading(
                        fontSize: isPhone ? 17 : 22,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Process F&B orders and checkouts',
                      style: ZaytounaTypography.body(
                        fontSize: isPhone ? 12 : 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                padding: EdgeInsets.all(isPhone ? 14.w : 18.w),
                decoration: BoxDecoration(
                  color: ZaytounaColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ZaytounaColors.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.point_of_sale_rounded,
                  color: Colors.white,
                  size: (isPhone ? 24 : 32).sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── METRICS (responsive 1/2/4 cols) ─────────────────────────────────────
  Widget _buildMetrics({required double maxWidth}) {
    final isPhone = _Bp.isPhone(maxWidth);

    if (_cachedMetrics == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Overview",
            style: ZaytounaTypography.subheading(fontSize: isPhone ? 16 : 18),
          ),
          SizedBox(height: 16.h),
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      );
    }

    final metrics = _cachedMetrics!;

    int crossAxisCount;
    double childAspectRatio;
    if (maxWidth < 380) {
      crossAxisCount = 1;
      childAspectRatio = 2.8;
    } else if (maxWidth < 600) {
      crossAxisCount = 2;
      childAspectRatio = 1.35;
    } else if (maxWidth < 1100) {
      crossAxisCount = 2;
      childAspectRatio = 1.8;
    } else {
      crossAxisCount = 4;
      childAspectRatio = 1.4;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Overview",
          style: ZaytounaTypography.subheading(fontSize: isPhone ? 16 : 18),
        ),
        SizedBox(height: 16.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: childAspectRatio,
          children: [
            _MetricCard(
              title: 'Total Orders',
              value: metrics.totalOrders.toString(),
              unit: 'orders',
              icon: Icons.receipt_long_rounded,
              color: ZaytounaColors.success,
            ),
            _MetricCard(
              title: 'Revenue',
              value:
                  '${Money.symbol}${metrics.totalRevenue.toStringAsFixed(2)}',
              unit: Money.code,
              icon: Icons.attach_money_rounded,
              color: ZaytounaColors.primary,
            ),
            _MetricCard(
              title: 'Avg Order',
              value:
                  '${Money.symbol}${metrics.averageOrderValue.toStringAsFixed(2)}',
              unit: 'per order',
              icon: Icons.analytics_rounded,
              color: ZaytounaColors.info,
            ),
            _MetricCard(
              title: 'Items Sold',
              value: metrics.itemsSold.toString(),
              unit: 'items',
              icon: Icons.fastfood_rounded,
              color: ZaytounaColors.warning,
            ),
          ],
        ),
      ],
    );
  }

  // ─── MENU GRID (responsive 2/3/4/5/6 cols) ───────────────────────────────
  Widget _buildMenuGrid(BuildContext context, {required double maxWidth}) {
    const allMenuTiles = <MenuTileData>[
      MenuTileData(
        title: 'Menu',
        icon: Icons.restaurant_menu_rounded,
        iconColor: Colors.white,
        bgColor: ZaytounaColors.warning,
        route: Routes.menu,
      ),
      MenuTileData(
        title: 'Floor Plan',
        icon: Icons.table_restaurant_rounded,
        iconColor: Colors.white,
        bgColor: ZaytounaColors.primaryDark,
        route: Routes.tables,
      ),
      MenuTileData(
        title: 'Manage Tables',
        icon: Icons.edit_note_rounded,
        iconColor: Colors.white,
        bgColor: Color(0xFF10B981),
        route: Routes.manageTables,
      ),
      MenuTileData(
        title: 'Inventory',
        icon: Icons.inventory_2_rounded,
        iconColor: Colors.white,
        bgColor: Color(0xFF3B82F6),
        route: Routes.inventory,
      ),
      MenuTileData(
        title: 'Expenses',
        icon: Icons.account_balance_wallet_rounded,
        iconColor: Colors.white,
        bgColor: ZaytounaColors.danger,
        route: Routes.expenses,
      ),
      MenuTileData(
        title: 'Facilities',
        icon: Icons.apartment_rounded,
        iconColor: Colors.white,
        bgColor: Color(0xFF8B5CF6),
        route: Routes.facilities,
      ),
      MenuTileData(
        title: 'Sales',
        icon: Icons.attach_money_rounded,
        iconColor: Colors.white,
        bgColor: ZaytounaColors.success,
        route: Routes.sales,
      ),
      MenuTileData(
        title: 'Orders',
        icon: Icons.list_rounded,
        iconColor: Colors.white,
        bgColor: ZaytounaColors.primaryDark,
        route: Routes.orders,
      ),
      MenuTileData(
        title: 'Customers',
        icon: Icons.people_rounded,
        iconColor: Colors.white,
        bgColor: ZaytounaColors.success,
        route: Routes.customers,
      ),
      MenuTileData(
        title: 'Categories',
        icon: Icons.category_rounded,
        iconColor: Colors.white,
        bgColor: Color(0xFF8B5CF6),
        route: Routes.categories,
      ),
      MenuTileData(
        title: 'Suppliers',
        icon: Icons.local_shipping_rounded,
        iconColor: Colors.white,
        bgColor: Color(0xFF6366F1),
        route: Routes.suppliers,
      ),
      MenuTileData(
        title: 'Analytics',
        icon: Icons.insights_rounded,
        iconColor: Colors.white,
        bgColor: ZaytounaColors.primary,
        route: Routes.reports,
      ),
      MenuTileData(
        title: 'Settings',
        icon: Icons.settings_rounded,
        iconColor: Colors.white,
        bgColor: Color(0xFF6C757D),
        route: Routes.settings,
      ),
    ];

    final allowedTiles = allMenuTiles.where((tile) {
      final p = AppPermissions.requiredFor(tile.route);
      return p == null || RouteGuard.hasPermission(p);
    }).toList();

    int crossAxisCount;
    if (maxWidth < 380) {
      crossAxisCount = 2;
    } else if (maxWidth < 600) {
      crossAxisCount = 3;
    } else if (maxWidth < 900) {
      crossAxisCount = 4;
    } else if (maxWidth < 1300) {
      crossAxisCount = 5;
    } else {
      crossAxisCount = 6;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.0,
      ),
      itemCount: allowedTiles.length,
      itemBuilder: (_, i) => _buildMenuTile(allowedTiles[i], maxWidth),
    );
  }

  Widget _buildMenuTile(MenuTileData data, double maxWidth) {
    final isPhone = _Bp.isPhone(maxWidth);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push(data.route);
        },
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          decoration: BoxDecoration(
            color: ZaytounaColors.bg,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: ZaytounaColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isPhone ? 12.w : 16.w),
                decoration: BoxDecoration(
                  color: data.bgColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: data.bgColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  data.icon,
                  color: data.iconColor,
                  size: (isPhone ? 22 : 28).sp,
                ),
              ),
              SizedBox(height: isPhone ? 10.h : 14.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: ZaytounaTypography.caption(
                    weight: FontWeight.w700,
                    color: ZaytounaColors.textPrimary,
                    fontSize: isPhone ? 11 : 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── RECENT ACTIVITY ─────────────────────────────────────────────────────
  Widget _buildRecentActivity({required bool isPhone}) {
    return FutureBuilder<List<dynamic>>(
      future: _recentOrdersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Transactions',
                style: ZaytounaTypography.subheading(
                  fontSize: isPhone ? 16 : 18,
                ),
              ),
              SizedBox(height: 16.h),
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Transactions',
                style: ZaytounaTypography.subheading(
                  fontSize: isPhone ? 16 : 18,
                ),
              ),
              SizedBox(height: 16.h),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.h),
                  child: Text(
                    'No recent activity',
                    style: ZaytounaTypography.body(),
                  ),
                ),
              ),
            ],
          );
        }
        final sales = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Recent Transactions',
                    style: ZaytounaTypography.subheading(
                      fontSize: isPhone ? 16 : 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(Routes.orders),
                  style: TextButton.styleFrom(
                    foregroundColor: ZaytounaColors.primary,
                    padding: EdgeInsets.symmetric(
                      horizontal: isPhone ? 8.w : 12.w,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'View all',
                    style: ZaytounaTypography.body(
                      weight: FontWeight.w600,
                      color: ZaytounaColors.primary,
                      fontSize: isPhone ? 13 : 15,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sales.length,
              separatorBuilder: (_, _) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final sale = sales[index];
                final createdAt = DateTime.parse(sale['created_at']);
                final timeAgo = _getTimeAgo(createdAt);
                return Container(
                  padding: EdgeInsets.all(isPhone ? 12.w : 14.w),
                  decoration: BoxDecoration(
                    color: ZaytounaColors.bg,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: ZaytounaColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isPhone ? 10.w : 12.w),
                        decoration: BoxDecoration(
                          color: ZaytounaColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: ZaytounaColors.textSecondary,
                          size: (isPhone ? 18 : 20).sp,
                        ),
                      ),
                      SizedBox(width: isPhone ? 10.w : 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${sale['id'].toString().padLeft(6, '0')}',
                              style: ZaytounaTypography.body(
                                weight: FontWeight.w600,
                                fontSize: isPhone ? 13 : 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              timeAgo,
                              style: ZaytounaTypography.caption(
                                fontSize: isPhone ? 11 : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${Money.symbol}${((sale['total_amount'] as num?) ?? 0).toStringAsFixed(2)}',
                        style: ZaytounaTypography.body(
                          weight: FontWeight.w700,
                          color: ZaytounaColors.primary,
                          fontSize: isPhone ? 14 : 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ZaytounaColors.bg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: ZaytounaColors.border, width: 1.5),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 18.sp),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: ZaytounaTypography.heading(fontSize: 20),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Text(
                title,
                style: ZaytounaTypography.caption(
                  color: ZaytounaColors.textSecondary,
                  weight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
