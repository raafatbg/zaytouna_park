// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print, camel_case_types

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── YOUR PROJECT IMPORTS ───
// Make sure these paths match your actual project structure!
import 'package:zaytouna_park/Core/Routers/routes.dart';
import 'package:zaytouna_park/Core/Routers/route_guard.dart';

// ─── CLEAN WHITE COLOR PALETTE ─────────────────────────────────────────────────
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

// ─── CLEAN TYPOGRAPHY ────────────────────────────────────────────────────
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

  static TextStyle displayMedium({
    FontWeight weight = FontWeight.w600,
    Color? color,
    double fontSize = 36,
  }) => GoogleFonts.inter(
    fontSize: fontSize.sp,
    fontWeight: weight,
    letterSpacing: -0.2,
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
    letterSpacing: 0,
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

// ─── DATA MODELS ──────────────────────────────────────────────────────────
class MenuTileData {
  final String title;
  final IconData icon;
  final Color iconColor, bgColor;
  final String route;
  final String? requiredPermission;

  const MenuTileData({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.route,
    this.requiredPermission,
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

// ─── OPTIMIZED HOME SCREEN ───────────────────────────────────────────────────
class PremiumCashierHome extends StatefulWidget {
  final VoidCallback onLaunchTerminal;

  const PremiumCashierHome({super.key, required this.onLaunchTerminal});

  @override
  State<PremiumCashierHome> createState() => _PremiumCashierHomeState();
}

class _PremiumCashierHomeState extends State<PremiumCashierHome>
    with SingleTickerProviderStateMixin {
  late final SupabaseClient _supabase;
  late AnimationController _animationController;

  SaleMetrics? _cachedMetrics;
  DateTime? _lastFetchTime;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _setupAnimations();
    _setupRealtimeSubscriptions();
    _fetchMetrics();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  void _setupRealtimeSubscriptions() {
    _realtimeChannel = _supabase.channel('public:cashier_dashboard');

    _realtimeChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            if (mounted) {
              HapticFeedback.lightImpact();
              _showNewOrderNotification(payload.newRecord['id']?.toString());
              _cachedMetrics = null;
              _fetchMetrics();
            }
          },
        )
        .subscribe();
  }

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
          onPressed: () {
            Navigator.pushNamed(context, Routes.orders);
          },
        ),
      ),
    );
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

      final results = await Future.wait([
        _supabase
            .from('orders')
            .select('total_amount')
            .gte('created_at', startOfDay.toIso8601String()),
        _supabase
            .from('order_items')
            .select('quantity')
            .gte('created_at', startOfDay.toIso8601String()),
      ]);

      final salesData = results[0] as List<dynamic>;
      final itemsData = results[1] as List<dynamic>;

      double revenue = salesData.fold(
        0.0,
        (sum, item) => sum + (item['total_amount'] as num? ?? 0).toDouble(),
      );
      int itemsSold = itemsData.fold(
        0,
        (sum, item) => sum + (item['quantity'] as int? ?? 0),
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
    } catch (e) {
      print('Error fetching metrics: $e');
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

  @override
  void dispose() {
    _animationController.dispose();
    _realtimeChannel?.unsubscribe();
    super.dispose();
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
      if (mounted) Navigator.pushReplacementNamed(context, Routes.login);
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

  @override
  Widget build(BuildContext context) {
    final user = RouteGuard.user;

    return Scaffold(
      backgroundColor: ZaytounaColors.bg,
      body: FadeTransition(
        opacity: _animationController.drive(
          Tween<double>(begin: 0.0, end: 1.0),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: ZaytounaColors.primary,
            onRefresh: () async {
              _cachedMetrics = null;
              await _fetchMetrics();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeader(
                        userName: user?.fullName ?? 'Staff',
                        userRole: user?.role ?? 'Cashier',
                      ),
                      SizedBox(height: 24.h),
                      _buildQuickLaunch(),
                      SizedBox(height: 32.h),
                      _buildMetrics(),
                      SizedBox(height: 40.h),
                      Text(
                        'Venue Management',
                        style: ZaytounaTypography.heading(),
                      ),
                      SizedBox(height: 20.h),
                      _buildMenuGrid(context),
                      SizedBox(height: 40.h),
                      _buildRecentActivity(),
                      SizedBox(height: 20.h),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required String userName, required String userRole}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back,', style: ZaytounaTypography.caption()),
              SizedBox(height: 4.h),
              Text(
                userName,
                style: ZaytounaTypography.heading(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: ZaytounaColors.primaryLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  userRole.toUpperCase(),
                  style: ZaytounaTypography.caption(
                    weight: FontWeight.w700,
                    color: ZaytounaColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleLogout,
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: ZaytounaColors.dangerLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: ZaytounaColors.danger,
                size: 20.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLaunch() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onLaunchTerminal,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ZaytounaColors.primary.withOpacity(0.1),
                ZaytounaColors.primary.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(20.r),
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
                        color: ZaytounaColors.primary,
                        weight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Point of Sale Terminal',
                      style: ZaytounaTypography.subheading(),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Process F&B orders and checkouts',
                      style: ZaytounaTypography.body(fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: ZaytounaColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ZaytounaColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.point_of_sale_rounded,
                  color: Colors.white,
                  size: 28.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetrics() {
    if (_cachedMetrics == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today\'s Overview', style: ZaytounaTypography.subheading()),
          SizedBox(height: 16.h),
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      );
    }

    final metrics = _cachedMetrics!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today\'s Overview', style: ZaytounaTypography.subheading()),
        SizedBox(height: 16.h),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1.4,
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
                  value: '\$${metrics.totalRevenue.toStringAsFixed(2)}',
                  unit: 'USD',
                  icon: Icons.attach_money_rounded,
                  color: ZaytounaColors.primary,
                ),
                _MetricCard(
                  title: 'Avg Order',
                  value: '\$${metrics.averageOrderValue.toStringAsFixed(2)}',
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
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    // ─── ADDED FLOOR PLAN AND MANAGE TABLES ───
    final List<MenuTileData> menuTiles = [
      const MenuTileData(
        title: 'Menu',
        icon: Icons.restaurant_menu_rounded,
        iconColor: Colors.white,
        bgColor: ZaytounaColors.warning,
        route: '/menu',
      ),
      const MenuTileData(
        title: 'Floor Plan',
        icon: Icons.table_restaurant_rounded,
        iconColor: Colors.white,
        bgColor: ZaytounaColors.primaryDark,
        route: Routes.tables, // For Cashiers to view Tables
      ),
      const MenuTileData(
        title: 'Manage Tables',
        icon: Icons.edit_note_rounded,
        iconColor: Colors.white,
        bgColor: Color(0xFF10B981), // Green
        route: '/manage-tables', // For Admins to Add/Remove Tables
      ),
      const MenuTileData(
        title: 'Inventory',
        icon: Icons.inventory_2_rounded,
        iconColor: Colors.white,
        bgColor: Color(0xFF3B82F6), // Blue
        route: Routes.inventory,
      ),
      const MenuTileData(
        title: 'Expenses',
        icon: Icons.account_balance_wallet_rounded,
        iconColor: Colors.white,
        bgColor: ZaytounaColors.danger,
        route: Routes.expenses,
      ),
      const MenuTileData(
        title: 'Facilities',
        icon: Icons.apartment_rounded,
        iconColor: Colors.white,
        bgColor: Color(0xFF8B5CF6), // Purple
        route: '/facilities',
      ),
      const MenuTileData(
        title: 'Sales',
        icon: Icons.attach_money_rounded,
        iconColor: Colors.white,
        bgColor: ZaytounaColors.success,
        route: '/sales',
      ),
      const MenuTileData(
        title: 'Orders',
        icon: Icons.list_rounded,
        iconColor: Colors.white,
        bgColor: ZaytounaColors.primaryDark,
        route: Routes.orders,
      ),
      const MenuTileData(
        title: 'Customers',
        icon: Icons.people_rounded,
        iconColor: Colors.white,
        bgColor: ZaytounaColors.success,
        route: Routes.customers,
      ),
      const MenuTileData(
        title: 'Categories',
        icon: Icons.category_rounded,
        iconColor: Colors.white,
        bgColor: Color(0xFF8B5CF6), // Purple
        route: Routes.categories,
      ),
      const MenuTileData(
        title: 'Suppliers',
        icon: Icons.local_shipping_rounded,
        iconColor: Colors.white,
        bgColor: Color(0xFF6366F1), // Indigo
        route: Routes.suppliers,
      ),
      const MenuTileData(
        title: 'Analytics',
        icon: Icons.insights_rounded,
        iconColor: Colors.white,
        bgColor: ZaytounaColors.primary,
        route: Routes.reports,
      ),
      const MenuTileData(
        title: 'Settings',
        icon: Icons.settings_rounded,
        iconColor: Colors.white,
        bgColor: Color(0xFF6C757D), // Grey
        route: '/settings',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 600) crossAxisCount = 3;
        if (constraints.maxWidth > 800) crossAxisCount = 4;
        if (constraints.maxWidth > 1100) crossAxisCount = 5;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 1.0,
          ),
          itemCount: menuTiles.length,
          itemBuilder: (_, i) => _buildMenuTile(menuTiles[i]),
        );
      },
    );
  }

  Widget _buildMenuTile(MenuTileData data) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(context, data.route);
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
            color: ZaytounaColors.bg,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: ZaytounaColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: data.bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, color: data.iconColor, size: 28.sp),
              ),
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: ZaytounaTypography.caption(
                    weight: FontWeight.w600,
                    color: ZaytounaColors.textPrimary,
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

  Widget _buildRecentActivity() {
    return FutureBuilder<List<dynamic>>(
      future: _supabase
          .from('orders')
          .select('id, total_amount, created_at')
          .order('created_at', ascending: false)
          .limit(5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.h),
              child: Text(
                'No recent activity',
                style: ZaytounaTypography.body(),
              ),
            ),
          );
        }

        final sales = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: ZaytounaTypography.subheading(),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, Routes.orders),
                  child: Text(
                    'View all',
                    style: ZaytounaTypography.body(
                      weight: FontWeight.w600,
                      color: ZaytounaColors.primary,
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
              separatorBuilder: (_, _) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                final sale = sales[index];
                final createdAt = DateTime.parse(sale['created_at']);
                final timeAgo = _getTimeAgo(createdAt);

                return Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: ZaytounaColors.bg,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: ZaytounaColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: const BoxDecoration(
                          color: ZaytounaColors.surfaceLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: ZaytounaColors.textSecondary,
                          size: 18.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${sale['id'].toString().padLeft(6, '0')}',
                              style: ZaytounaTypography.body(
                                weight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(timeAgo, style: ZaytounaTypography.caption()),
                          ],
                        ),
                      ),
                      Text(
                        '\$${(sale['total_amount'] ?? 0).toStringAsFixed(2)}',
                        style: ZaytounaTypography.body(
                          weight: FontWeight.w700,
                          color: ZaytounaColors.primary,
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
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}

// ─── METRIC CARD ───────────────────────────────────────────────────────────
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
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ZaytounaColors.bg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: ZaytounaColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: color, size: 16.sp),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: ZaytounaTypography.heading(fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Text(
                title,
                style: ZaytounaTypography.caption(
                  color: ZaytounaColors.textSecondary,
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
