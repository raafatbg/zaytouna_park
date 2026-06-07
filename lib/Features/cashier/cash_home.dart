// ignore_for_file: use_build_context_synchronously
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

// ─── RESPONSIVE ──────────────────────────────────────────────────────────
enum ScreenSize { phone, tablet, desktop, wide }

class Responsive {
  Responsive._();

  static const double phoneMax = 600;
  static const double tabletMax = 1100;
  static const double desktopMax = 1600;
  static const double maxContentWidth = 1400;

  static ScreenSize sizeOf(double w) {
    if (w < phoneMax) return ScreenSize.phone;
    if (w < tabletMax) return ScreenSize.tablet;
    if (w < desktopMax) return ScreenSize.desktop;
    return ScreenSize.wide;
  }

  static bool isPhone(double w) => w < phoneMax;

  static T value<T>(
    double w, {
    required T phone,
    T? tablet,
    T? desktop,
    T? wide,
  }) {
    switch (sizeOf(w)) {
      case ScreenSize.phone:
        return phone;
      case ScreenSize.tablet:
        return tablet ?? phone;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? phone;
      case ScreenSize.wide:
        return wide ?? desktop ?? tablet ?? phone;
    }
  }

  /// Clamp ScreenUtil scaling so type stays readable (and not huge) on tablets.
  static double clampSp(double size, {double min = 0.85, double max = 1.15}) {
    return size.sp.clamp(size * min, size * max);
  }
}

// ─── DESIGN TOKENS ───────────────────────────────────────────────────────
class Insets {
  Insets._();
  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 12.w;
  static double get lg => 16.w;
  static double get xl => 24.w;
  static double get xxl => 32.w;
}

class Corners {
  Corners._();
  static double get sm => 12.r;
  static double get md => 16.r;
  static double get lg => 20.r;
  static double get xl => 24.r;
}

// ─── DISPLAY CURRENCY ────────────────────────────────────────────────────
class Money {
  Money._();
  static const String code = 'USD';
  static const String symbol = '\$';

  static String format(num? amount) =>
      '$symbol${(amount ?? 0).toStringAsFixed(2)}';
}

// ─── COLOR PALETTE ───────────────────────────────────────────────────────
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
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const dangerLight = Color(0xFFFEE2E2);
  static const info = Color(0xFF3B82F6);
  static const purple = Color(0xFF8B5CF6);
  static const purpleDark = Color(0xFF6D28D9);
  static const indigo = Color(0xFF6366F1);
  static const teal = Color(0xFF14B8A6);
}

// ─── SHARED DECORATIONS ──────────────────────────────────────────────────
class Decorations {
  Decorations._();

  static BoxDecoration card({double? radius, Color? color}) => BoxDecoration(
    color: color ?? ZaytounaColors.bgSecondary,
    borderRadius: BorderRadius.circular(radius ?? Corners.lg),
    border: Border.all(
      color: ZaytounaColors.border.withValues(alpha: 0.8),
      width: 1,
    ),
  );

  static BoxDecoration circleIcon(Color color) => BoxDecoration(
    color: color,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: color.withValues(alpha: 0.25),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration gradientCta(Color base) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [base.withValues(alpha: 0.12), base.withValues(alpha: 0.02)],
    ),
    borderRadius: BorderRadius.circular(Corners.xl),
    border: Border.all(color: base.withValues(alpha: 0.2)),
  );
}

// ─── TYPOGRAPHY ──────────────────────────────────────────────────────────
class ZaytounaTypography {
  ZaytounaTypography._();

  static TextStyle heading({
    FontWeight weight = FontWeight.w600,
    Color? color,
    double fontSize = 24,
  }) => GoogleFonts.inter(
    fontSize: Responsive.clampSp(fontSize),
    fontWeight: weight,
    letterSpacing: -0.2,
    color: color ?? ZaytounaColors.textPrimary,
  );

  static TextStyle subheading({
    FontWeight weight = FontWeight.w600,
    Color? color,
    double fontSize = 18,
  }) => GoogleFonts.inter(
    fontSize: Responsive.clampSp(fontSize),
    fontWeight: weight,
    letterSpacing: -0.1,
    color: color ?? ZaytounaColors.textPrimary,
  );

  static TextStyle body({
    FontWeight weight = FontWeight.w400,
    Color? color,
    double fontSize = 15,
  }) => GoogleFonts.inter(
    fontSize: Responsive.clampSp(fontSize),
    fontWeight: weight,
    color: color ?? ZaytounaColors.textSecondary,
  );

  static TextStyle caption({
    FontWeight weight = FontWeight.w500,
    Color? color,
    double fontSize = 12,
  }) => GoogleFonts.inter(
    fontSize: Responsive.clampSp(fontSize),
    fontWeight: weight,
    letterSpacing: 0.3,
    color: color ?? ZaytounaColors.textTertiary,
  );
}

// ─── MODELS ──────────────────────────────────────────────────────────────
class MenuTileData {
  final String title;
  final IconData icon;
  final Color bgColor;
  final String route;

  const MenuTileData({
    required this.title,
    required this.icon,
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

  const SaleMetrics({
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.itemsSold,
    required this.timestamp,
  });

  factory SaleMetrics.empty() => SaleMetrics(
    totalOrders: 0,
    totalRevenue: 0,
    averageOrderValue: 0,
    itemsSold: 0,
    timestamp: DateTime.now(),
  );
}

enum _BtnVariant { primary, secondary, danger }

// ─── HOME SCREEN ─────────────────────────────────────────────────────────
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
      duration: const Duration(milliseconds: 600),
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

  // ─── DATA ────────────────────────────────────────────────────────────
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
      if (mounted) {
        setState(() => _recentOrdersFuture = _fetchRecentOrders());
      }
    });
  }

  Future<List<dynamic>> _fetchRecentOrders() {
    return _supabase
        .from('orders')
        .select('id, total_amount, created_at, order_status')
        .neq('order_status', 'voided')
        .order('created_at', ascending: false)
        .limit(5);
  }

  Future<void> _fetchMetrics() async {
    final lastFetch = _lastFetchTime;
    if (_cachedMetrics != null &&
        lastFetch != null &&
        DateTime.now().difference(lastFetch).inSeconds < 30) {
      return;
    }

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final salesData =
          await _supabase
                  .from('orders')
                  .select('id, total_amount')
                  .gte('created_at', startOfDay.toIso8601String())
                  .neq('order_status', 'voided')
              as List<dynamic>;

      final orderIds = salesData.map((o) => o['id']).toList();

      int itemsSold = 0;
      if (orderIds.isNotEmpty) {
        final itemsData =
            await _supabase
                    .from('order_items')
                    .select('quantity')
                    .inFilter('order_id', orderIds)
                as List<dynamic>;
        itemsSold = itemsData.fold(
          0,
          (sum, item) => sum + (item['quantity'] as int? ?? 0),
        );
      }

      final revenue = salesData.fold<double>(
        0,
        (sum, item) => sum + ((item['total_amount'] as num?) ?? 0).toDouble(),
      );
      final count = salesData.length;

      if (!mounted) return;
      setState(() {
        _cachedMetrics = SaleMetrics(
          totalOrders: count,
          totalRevenue: revenue,
          averageOrderValue: count > 0 ? revenue / count : 0,
          itemsSold: itemsSold,
          timestamp: now,
        );
        _lastFetchTime = now;
      });
    } catch (e, st) {
      developer.log('Error fetching metrics', error: e, stackTrace: st);
      if (mounted && _cachedMetrics == null) {
        setState(() => _cachedMetrics = SaleMetrics.empty());
      }
    }
  }

  Future<void> _onRefresh() async {
    _cachedMetrics = null;
    await _fetchMetrics();
    if (mounted) {
      setState(() => _recentOrdersFuture = _fetchRecentOrders());
    }
  }

  // ─── TERMINAL LAUNCH (FIXED) ─────────────────────────────────────────
  void _launchTerminal() {
    HapticFeedback.lightImpact();

    final canUse =
        RouteGuard.user?.role == 'admin' ||
        RouteGuard.hasPermission(AppPermissions.useTerminal);

    if (!canUse) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Text("You don't have terminal access"),
            backgroundColor: ZaytounaColors.danger,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(Insets.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Corners.sm),
            ),
          ),
        );
      return;
    }

    // Keep the parent hook (if any) AND guarantee navigation happens.
    widget.onLaunchTerminal.call();
    context.push(Routes.pos);
  }

  // ─── UI HELPERS ────────────────────────────────────────────────────────
  void _showNewOrderNotification(String? orderId) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.notifications_active_rounded,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: Insets.md),
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
          margin: EdgeInsets.all(Insets.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Corners.sm),
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
          borderRadius: BorderRadius.circular(Corners.xl),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: EdgeInsets.all(Insets.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(Insets.lg),
                  decoration: BoxDecoration(
                    color: ZaytounaColors.dangerLight,
                    borderRadius: BorderRadius.circular(Corners.md),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: ZaytounaColors.danger,
                    size: Responsive.clampSp(32),
                  ),
                ),
                SizedBox(height: 20.h),
                Text('Sign Out', style: ZaytounaTypography.heading()),
                SizedBox(height: Insets.md),
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
                        variant: _BtnVariant.secondary,
                      ),
                    ),
                    SizedBox(width: Insets.md),
                    Expanded(
                      child: _buildButton(
                        label: 'Sign Out',
                        onPressed: () => Navigator.pop(context, true),
                        variant: _BtnVariant.danger,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
    _BtnVariant variant = _BtnVariant.primary,
  }) {
    final isFilled = variant != _BtnVariant.secondary;
    final fill = switch (variant) {
      _BtnVariant.primary => ZaytounaColors.primary,
      _BtnVariant.danger => ZaytounaColors.danger,
      _BtnVariant.secondary => Colors.transparent,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(Corners.sm),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(Corners.sm),
            border: variant == _BtnVariant.secondary
                ? Border.all(color: ZaytounaColors.border, width: 1.5)
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: ZaytounaTypography.body(
                weight: FontWeight.w600,
                color: isFilled ? Colors.white : ZaytounaColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZaytounaColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isPhone = Responsive.isPhone(w);
            final hPad = Responsive.value<double>(
              w,
              phone: 12,
              tablet: 24,
              desktop: 28,
              wide: 32,
            );

            return FadeTransition(
              opacity: _animationController,
              child: RefreshIndicator(
                color: ZaytounaColors.primary,
                onRefresh: _onRefresh,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: Responsive.maxContentWidth,
                    ),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(hPad.w, 12.h, hPad.w, 0),
                          sliver: SliverToBoxAdapter(
                            child: _buildHeader(isPhone: isPhone),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            hPad.w,
                            Insets.lg,
                            hPad.w,
                            Insets.xxl,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _buildQuickLaunch(isPhone: isPhone),
                              SizedBox(height: Insets.md),
                              _buildBookFacilityCta(isPhone: isPhone),
                              SizedBox(height: isPhone ? 24.h : 32.h),
                              _buildMetrics(maxWidth: w),
                              SizedBox(height: isPhone ? 28.h : 40.h),
                              _SectionTitle(
                                'Venue Management',
                                fontSize: isPhone ? 20 : 24,
                              ),
                              SizedBox(height: 20.h),
                              _buildMenuGrid(maxWidth: w),
                              SizedBox(height: isPhone ? 28.h : 40.h),
                              _buildRecentActivity(isPhone: isPhone),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────────────────
  Widget _buildHeader({required bool isPhone}) {
    final user = RouteGuard.user;
    final logoSize = isPhone ? 44.0 : 54.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? Insets.xs : Insets.sm,
        vertical: Insets.sm,
      ),
      child: Row(
        children: [
          Container(
            height: logoSize,
            width: logoSize,
            padding: EdgeInsets.all(isPhone ? 6 : 8),
            decoration: BoxDecoration(
              color: ZaytounaColors.surface,
              borderRadius: BorderRadius.circular(Corners.md),
              border: Border.all(
                color: ZaytounaColors.primary.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: ZaytounaColors.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset(
              'assets/logo/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.storefront_rounded,
                color: ZaytounaColors.primary,
                size: Responsive.clampSp(isPhone ? 22 : 28),
              ),
            ),
          ),
          SizedBox(width: isPhone ? Insets.sm : Insets.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (user?.fullName.isNotEmpty ?? false)
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
              borderRadius: BorderRadius.circular(Corners.md),
              child: Container(
                padding: EdgeInsets.all(isPhone ? 9 : 12),
                decoration: BoxDecoration(
                  color: ZaytounaColors.surfaceLight,
                  borderRadius: BorderRadius.circular(Corners.md),
                  border: Border.all(color: ZaytounaColors.border, width: 1),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: ZaytounaColors.textSecondary,
                  size: Responsive.clampSp(isPhone ? 18 : 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── QUICK LAUNCH: POS TERMINAL ────────────────────────────────────────
  Widget _buildQuickLaunch({required bool isPhone}) {
    return _CtaCard(
      onTap: _launchTerminal,
      baseColor: ZaytounaColors.primary,
      iconBg: ZaytounaColors.primary,
      icon: Icons.point_of_sale_rounded,
      eyebrow: 'Ready to Serve',
      title: 'Point of Sale Terminal',
      subtitle: 'Process F&B orders and checkouts',
      isPhone: isPhone,
      large: true,
    );
  }

  // ─── BOOK A FACILITY CTA ───────────────────────────────────────────────
  Widget _buildBookFacilityCta({required bool isPhone}) {
    return _CtaCard(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(Routes.bookFacility);
      },
      baseColor: ZaytounaColors.purple,
      iconBg: ZaytounaColors.purple,
      icon: Icons.event_available_rounded,
      title: 'Book a Facility',
      subtitle: 'Reserve padel, courts, cabins & more',
      trailing: Icon(
        Icons.arrow_forward_rounded,
        color: ZaytounaColors.purple,
        size: Responsive.clampSp(isPhone ? 18 : 22),
      ),
      isPhone: isPhone,
    );
  }

  // ─── METRICS ───────────────────────────────────────────────────────────
  Widget _buildMetrics({required double maxWidth}) {
    final isPhone = Responsive.isPhone(maxWidth);
    final header = _SectionTitle(
      "Today's Overview",
      fontSize: isPhone ? 16 : 18,
      subheading: true,
    );

    if (_cachedMetrics == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          SizedBox(height: Insets.lg),
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      );
    }

    final m = _cachedMetrics!;
    final (crossAxisCount, childAspectRatio) = switch (maxWidth) {
      < 380 => (1, 2.8),
      < 600 => (2, 1.35),
      < 1100 => (2, 1.8),
      _ => (4, 1.4),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        SizedBox(height: Insets.lg),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: Insets.md,
          mainAxisSpacing: Insets.md,
          childAspectRatio: childAspectRatio.toDouble(),
          children: [
            _MetricCard(
              title: 'Total Orders',
              value: m.totalOrders.toString(),
              unit: 'orders',
              icon: Icons.receipt_long_rounded,
              color: ZaytounaColors.success,
            ),
            _MetricCard(
              title: 'Revenue',
              value: Money.format(m.totalRevenue),
              unit: Money.code,
              icon: Icons.attach_money_rounded,
              color: ZaytounaColors.primary,
            ),
            _MetricCard(
              title: 'Avg Order',
              value: Money.format(m.averageOrderValue),
              unit: 'per order',
              icon: Icons.analytics_rounded,
              color: ZaytounaColors.info,
            ),
            _MetricCard(
              title: 'Items Sold',
              value: m.itemsSold.toString(),
              unit: 'items',
              icon: Icons.fastfood_rounded,
              color: ZaytounaColors.warning,
            ),
          ],
        ),
      ],
    );
  }

  // ─── MENU GRID ─────────────────────────────────────────────────────────
  Widget _buildMenuGrid({required double maxWidth}) {
    const allMenuTiles = <MenuTileData>[
      MenuTileData(
        title: 'Menu',
        icon: Icons.restaurant_menu_rounded,
        bgColor: ZaytounaColors.warning,
        route: Routes.menu,
      ),
      MenuTileData(
        title: 'Floor Plan',
        icon: Icons.table_restaurant_rounded,
        bgColor: ZaytounaColors.primaryDark,
        route: Routes.tables,
      ),
      MenuTileData(
        title: 'Manage Tables',
        icon: Icons.edit_note_rounded,
        bgColor: ZaytounaColors.success,
        route: Routes.manageTables,
      ),
      MenuTileData(
        title: 'Inventory',
        icon: Icons.inventory_2_rounded,
        bgColor: ZaytounaColors.info,
        route: Routes.inventory,
      ),
      MenuTileData(
        title: 'Expenses',
        icon: Icons.account_balance_wallet_rounded,
        bgColor: ZaytounaColors.danger,
        route: Routes.expenses,
      ),
      MenuTileData(
        title: 'Book Facility',
        icon: Icons.event_available_rounded,
        bgColor: ZaytounaColors.purple,
        route: Routes.bookFacility,
      ),
      MenuTileData(
        title: 'Manage Facilities',
        icon: Icons.apartment_rounded,
        bgColor: ZaytounaColors.indigo,
        route: Routes.facilities,
      ),
      MenuTileData(
        title: 'Sales',
        icon: Icons.attach_money_rounded,
        bgColor: ZaytounaColors.success,
        route: Routes.sales,
      ),
      MenuTileData(
        title: 'Orders',
        icon: Icons.list_rounded,
        bgColor: ZaytounaColors.primaryDark,
        route: Routes.orders,
      ),
      MenuTileData(
        title: 'Customers',
        icon: Icons.people_rounded,
        bgColor: ZaytounaColors.success,
        route: Routes.customers,
      ),
      MenuTileData(
        title: 'Categories',
        icon: Icons.category_rounded,
        bgColor: ZaytounaColors.purple,
        route: Routes.categories,
      ),
      MenuTileData(
        title: 'Suppliers',
        icon: Icons.local_shipping_rounded,
        bgColor: ZaytounaColors.indigo,
        route: Routes.suppliers,
      ),
      MenuTileData(
        title: 'Analytics',
        icon: Icons.insights_rounded,
        bgColor: ZaytounaColors.primary,
        route: Routes.reports,
      ),
      MenuTileData(
        title: 'Bookings List',
        icon: Icons.event_note_rounded,
        bgColor: ZaytounaColors.teal,
        route: Routes.facilityBookings,
      ),
      MenuTileData(
        title: 'Settings',
        icon: Icons.settings_rounded,
        bgColor: ZaytounaColors.textSecondary,
        route: Routes.settings,
      ),
    ];

    final allowedTiles = allMenuTiles.where((tile) {
      final p = AppPermissions.requiredFor(tile.route);
      return p == null || RouteGuard.hasPermission(p);
    }).toList();

    final crossAxisCount = switch (maxWidth) {
      < 380 => 2,
      < 600 => 3,
      < 900 => 4,
      < 1300 => 5,
      _ => 6,
    };

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: Insets.md,
        mainAxisSpacing: Insets.md,
        childAspectRatio: 1.0,
      ),
      itemCount: allowedTiles.length,
      itemBuilder: (_, i) => _MenuTile(
        data: allowedTiles[i],
        isPhone: Responsive.isPhone(maxWidth),
        onTap: () {
          HapticFeedback.lightImpact();
          context.push(allowedTiles[i].route);
        },
      ),
    );
  }

  // ─── RECENT ACTIVITY ───────────────────────────────────────────────────
  Widget _buildRecentActivity({required bool isPhone}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionTitle(
              'Recent Orders',
              fontSize: isPhone ? 16 : 18,
              subheading: true,
            ),
            TextButton(
              onPressed: () => context.push(Routes.orders),
              child: Text(
                'View All',
                style: ZaytounaTypography.body(
                  weight: FontWeight.w600,
                  color: ZaytounaColors.primary,
                  fontSize: isPhone ? 13 : 14,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: Insets.sm),
        FutureBuilder<List<dynamic>>(
          future: _recentOrdersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            if (snapshot.hasError) {
              return const _EmptyState(
                icon: Icons.error_outline_rounded,
                message: 'Could not load recent orders',
              );
            }
            final orders = snapshot.data ?? const [];
            if (orders.isEmpty) {
              return const _EmptyState(
                icon: Icons.receipt_long_rounded,
                message: 'No recent orders found',
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              separatorBuilder: (_, _) => SizedBox(height: Insets.sm),
              itemBuilder: (_, index) => _OrderTile(order: orders[index]),
            );
          },
        ),
      ],
    );
  }
}

// ─── REUSABLE WIDGETS ──────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  final double fontSize;
  final bool subheading;
  const _SectionTitle(
    this.text, {
    required this.fontSize,
    this.subheading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: subheading
          ? ZaytounaTypography.subheading(fontSize: fontSize)
          : ZaytounaTypography.heading(fontSize: fontSize),
    );
  }
}

class _CtaCard extends StatelessWidget {
  final VoidCallback onTap;
  final Color baseColor;
  final Color iconBg;
  final IconData icon;
  final String? eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool isPhone;
  final bool large;

  const _CtaCard({
    required this.onTap,
    required this.baseColor,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isPhone,
    this.eyebrow,
    this.trailing,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconCircle = Container(
      padding: EdgeInsets.all(isPhone ? 14.w : 18.w),
      decoration: BoxDecoration(
        color: iconBg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: iconBg.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: Responsive.clampSp(isPhone ? 22 : (large ? 32 : 26)),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Corners.xl),
        child: Container(
          padding: EdgeInsets.all(isPhone ? 18.w : 24.w),
          decoration: Decorations.gradientCta(baseColor),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (eyebrow != null) ...[
                      Text(
                        eyebrow!,
                        style: ZaytounaTypography.caption(
                          color: ZaytounaColors.primaryDark,
                          weight: FontWeight.w700,
                          fontSize: isPhone ? 11 : 13,
                        ),
                      ),
                      SizedBox(height: Insets.sm),
                    ],
                    Text(
                      title,
                      style: large
                          ? ZaytounaTypography.heading(
                              fontSize: isPhone ? 17 : 22,
                            )
                          : ZaytounaTypography.subheading(
                              fontSize: isPhone ? 15 : 18,
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: Insets.xs),
                    Text(
                      subtitle,
                      style: ZaytounaTypography.body(
                        fontSize: isPhone ? 12 : 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: Insets.md),
              trailing ?? iconCircle,
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final MenuTileData data;
  final bool isPhone;
  final VoidCallback onTap;
  const _MenuTile({
    required this.data,
    required this.isPhone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Corners.lg),
        child: Container(
          decoration: Decorations.card(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isPhone ? 10.w : 14.w),
                decoration: Decorations.circleIcon(data.bgColor),
                child: Icon(
                  data.icon,
                  color: Colors.white,
                  size: Responsive.clampSp(isPhone ? 20 : 24),
                ),
              ),
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Insets.sm),
                child: Text(
                  data.title,
                  style: ZaytounaTypography.body(
                    weight: FontWeight.w600,
                    fontSize: isPhone ? 12 : 14,
                    color: ZaytounaColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      decoration: Decorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: ZaytounaTypography.caption(
                    weight: FontWeight.w600,
                    color: ZaytounaColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: Responsive.clampSp(20)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: ZaytounaTypography.heading(
                  weight: FontWeight.w700,
                  fontSize: 20,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Text(
                unit,
                style: ZaytounaTypography.caption(fontSize: 10),
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

class _OrderTile extends StatelessWidget {
  final dynamic order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = (order['order_status'] as String? ?? 'pending')
        .toUpperCase();
    final isDone = status == 'COMPLETED';

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: Decorations.card(radius: Corners.md),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: ZaytounaColors.surface,
              borderRadius: BorderRadius.circular(Corners.sm),
            ),
            child: Icon(
              Icons.receipt_rounded,
              color: ZaytounaColors.textSecondary,
              size: Responsive.clampSp(20),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order['id']}',
                  style: ZaytounaTypography.body(
                    weight: FontWeight.w600,
                    color: ZaytounaColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  status,
                  style: ZaytounaTypography.caption(
                    weight: FontWeight.w700,
                    color: isDone
                        ? ZaytounaColors.success
                        : ZaytounaColors.warning,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Money.format(order['total_amount'] as num?),
            style: ZaytounaTypography.body(
              weight: FontWeight.w700,
              color: ZaytounaColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Insets.xl),
      decoration: Decorations.card(radius: Corners.md),
      child: Column(
        children: [
          Icon(
            icon,
            color: ZaytounaColors.textTertiary,
            size: Responsive.clampSp(28),
          ),
          SizedBox(height: Insets.sm),
          Text(message, style: ZaytounaTypography.body()),
        ],
      ),
    );
  }
}
