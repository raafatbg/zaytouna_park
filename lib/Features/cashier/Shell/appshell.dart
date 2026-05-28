// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:zaytouna_park/Core/Routers/route_guard.dart';
import 'package:zaytouna_park/Core/Routers/routes.dart';
import 'package:zaytouna_park/Features/admin/Widgets/Categories/categories.dart';
import 'package:zaytouna_park/Features/admin/Widgets/Facilities/facilities.dart';
import 'package:zaytouna_park/Features/admin/Widgets/Inventory/inventory.dart';
import 'package:zaytouna_park/Features/admin/Widgets/Suppliers/suppliers.dart';
import 'package:zaytouna_park/Features/cashier/cash_home.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Analytics/analatics.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Customers/customers.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Expenses/expenses.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Orders/orders.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Sales/sales.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Settings/settings.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Terminal/terminalscreen.dart';
import 'package:zaytouna_park/Features/kitchen/widgets/menu%20mangement/menumanagementscreen.dart';

// ─── RESPONSIVE BREAKPOINTS ────────────────────────────────────────────────
class Breakpoints {
  Breakpoints._();
  static const double phone = 600;
  static const double tabletPortrait = 900;
  static const double tabletLandscape = 1200;
  static const double wide = 1600;

  static bool isPhone(double w) => w < phone;
  static bool isTabletPortrait(double w) => w >= phone && w < tabletPortrait;
  static bool isTabletLandscape(double w) =>
      w >= tabletPortrait && w < tabletLandscape;
  static bool isDesktop(double w) => w >= tabletLandscape;
}

class ShellColors {
  ShellColors._();
  static const bg = Color(0xFFFFFFFF);
  static const sidebarBg = Color(0xFFF8F9FA);
  static const sidebarAccent = Color(0xFFE9ECEF);
  static const activeBlue = Color(0xFFB8860B);
  static const textPrimary = Color(0xFF212529);
  static const textSecondary = Color(0xFF6C757D);
  static const textTertiary = Color(0xFFADB5BD);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE9ECEF);
  static const hover = Color(0xFFF1F3F5);
}

enum NavTab {
  dashboard,
  pos,
  menu,
  inventory,
  expenses,
  facilities,
  sales,
  orders,
  customers,
  categories,
  suppliers,
  analytics,
  settings,
}

class NavMeta {
  final NavTab tab;
  final IconData icon;
  final String label;
  final String routeName;
  const NavMeta({
    required this.tab,
    required this.icon,
    required this.label,
    required this.routeName,
  });
}

const _allNavItems = [
  NavMeta(
    tab: NavTab.dashboard,
    icon: Icons.grid_view_rounded,
    label: 'Dashboard',
    routeName: Routes.home,
  ),
  NavMeta(
    tab: NavTab.pos,
    icon: Icons.point_of_sale_rounded,
    label: 'POS Terminal',
    routeName: Routes.pos,
  ),
  NavMeta(
    tab: NavTab.menu,
    icon: Icons.restaurant_menu_rounded,
    label: 'Menu',
    routeName: Routes.menu,
  ),
  NavMeta(
    tab: NavTab.inventory,
    icon: Icons.inventory_2_rounded,
    label: 'Inventory',
    routeName: Routes.inventory,
  ),
  NavMeta(
    tab: NavTab.expenses,
    icon: Icons.account_balance_wallet_rounded,
    label: 'Expenses',
    routeName: Routes.expenses,
  ),
  NavMeta(
    tab: NavTab.facilities,
    icon: Icons.apartment_rounded,
    label: 'Facilities',
    routeName: Routes.facilities,
  ),
  NavMeta(
    tab: NavTab.sales,
    icon: Icons.attach_money_rounded,
    label: 'Sales',
    routeName: Routes.sales,
  ),
  NavMeta(
    tab: NavTab.orders,
    icon: Icons.list_rounded,
    label: 'Orders',
    routeName: Routes.orders,
  ),
  NavMeta(
    tab: NavTab.customers,
    icon: Icons.people_rounded,
    label: 'Customers',
    routeName: Routes.customers,
  ),
  NavMeta(
    tab: NavTab.categories,
    icon: Icons.category_rounded,
    label: 'Categories',
    routeName: Routes.categories,
  ),
  NavMeta(
    tab: NavTab.suppliers,
    icon: Icons.local_shipping_rounded,
    label: 'Suppliers',
    routeName: Routes.suppliers,
  ),
  NavMeta(
    tab: NavTab.analytics,
    icon: Icons.insights_rounded,
    label: 'Analytics',
    routeName: Routes.reports,
  ),
  NavMeta(
    tab: NavTab.settings,
    icon: Icons.settings_rounded,
    label: 'Settings',
    routeName: Routes.settings,
  ),
];

class CashierShellScreen extends StatefulWidget {
  const CashierShellScreen({super.key});
  @override
  State<CashierShellScreen> createState() => _CashierShellScreenState();
}

class _CashierShellScreenState extends State<CashierShellScreen> {
  late NavTab _activeTab;
  late List<NavMeta> _allowedTabs;

  @override
  void initState() {
    super.initState();
    _calculateAllowedTabs();
  }

  void _calculateAllowedTabs() {
    _allowedTabs = _allNavItems.where((item) {
      final p = AppPermissions.requiredFor(item.routeName);
      return p == null || RouteGuard.hasPermission(p);
    }).toList();
    _activeTab = _allowedTabs.isNotEmpty
        ? _allowedTabs.first.tab
        : NavTab.dashboard;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isPhone = Breakpoints.isPhone(w);
        final isDesktop = Breakpoints.isDesktop(w); // ≥1200 → full sidebar
        final showSidebar = !isPhone; // tablet+ → some sidebar
        final sidebarCollapsed = !isDesktop && !isPhone; // 600–1199 → icon rail

        return Scaffold(
          backgroundColor: ShellColors.bg,
          drawer: isPhone
              ? Drawer(
                  child: _PremiumSidebar(
                    allowedTabs: _allowedTabs,
                    activeTab: _activeTab,
                    collapsed: false,
                    onTab: (t) {
                      Navigator.pop(context); // close drawer
                      _handleTabSelection(t);
                    },
                    onLogout: () => _confirmLogout(context),
                  ),
                )
              : null,
          body: SafeArea(
            child: Row(
              children: [
                if (showSidebar)
                  _PremiumSidebar(
                    allowedTabs: _allowedTabs,
                    activeTab: _activeTab,
                    collapsed: sidebarCollapsed,
                    onTab: _handleTabSelection,
                    onLogout: () => _confirmLogout(context),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      _ShellHeader(
                        activeTab: _activeTab,
                        allowedTabs: _allowedTabs,
                        isPhone: isPhone,
                        showMenuButton: isPhone,
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: KeyedSubtree(
                            key: ValueKey(_activeTab),
                            child: _buildPage(),
                          ),
                        ),
                      ),
                      if (isPhone)
                        _PremiumBottomNav(
                          allowedTabs: _allowedTabs,
                          activeTab: _activeTab,
                          onTab: _handleTabSelection,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleTabSelection(NavTab tab) {
    if (tab == NavTab.pos) {
      context.push(Routes.pos);
    } else {
      setState(() => _activeTab = tab);
    }
  }

  Widget _buildPage() {
    switch (_activeTab) {
      case NavTab.dashboard:
        return PremiumCashierHome(
          onLaunchTerminal: () => context.push(Routes.pos),
        );
      case NavTab.pos:
        return const UpgradedPOS();
      case NavTab.sales:
        return const SalesScreen();
      case NavTab.menu:
        return const MenuManagementScreen();
      case NavTab.inventory:
        return const InventoryScreen();
      case NavTab.categories:
        return const CategoryScreen();
      case NavTab.suppliers:
        return const SuppliersScreen();
      case NavTab.customers:
        return const CustomersScreen();
      case NavTab.expenses:
        return const ExpensesScreen();
      case NavTab.analytics:
        return const AnalyticsScreen();
      case NavTab.facilities:
        return const FacilitiesScreen();
      case NavTab.settings:
        return const SettingsScreen();
      case NavTab.orders:
        return const OrdersScreen();
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: ShellColors.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: const Color(0xFFEF4444),
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Sign Out',
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w600,
                  color: ShellColors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Are you sure you want to sign out?',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  color: ShellColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 28.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: const BorderSide(color: ShellColors.border),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: ShellColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await RouteGuard.logout();
                        if (mounted) context.go(Routes.login);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Sign Out',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SIDEBAR (collapsed icon-rail or full) ─────────────────────────────────
class _PremiumSidebar extends StatelessWidget {
  final List<NavMeta> allowedTabs;
  final NavTab activeTab;
  final bool collapsed;
  final ValueChanged<NavTab> onTab;
  final VoidCallback onLogout;
  const _PremiumSidebar({
    required this.allowedTabs,
    required this.activeTab,
    required this.collapsed,
    required this.onTab,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final double width = collapsed ? 80 : 260;
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: ShellColors.bg,
        border: Border(right: BorderSide(color: ShellColors.border, width: 1)),
      ),
      child: Column(
        children: [
          SizedBox(height: 24.h),
          _SidebarLogo(collapsed: collapsed),
          SizedBox(height: 24.h),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: collapsed ? 10 : 12),
              physics: const BouncingScrollPhysics(),
              children: allowedTabs
                  .map(
                    (item) => _SidebarItem(
                      meta: item,
                      isActive: activeTab == item.tab,
                      collapsed: collapsed,
                      onTap: () => onTab(item.tab),
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 10 : 12,
              vertical: 16.h,
            ),
            child: _SidebarLogout(collapsed: collapsed, onTap: onLogout),
          ),
        ],
      ),
    );
  }
}

class _SidebarLogo extends StatelessWidget {
  final bool collapsed;
  const _SidebarLogo({required this.collapsed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 16),
      child: Row(
        mainAxisAlignment: collapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB8860B), Color(0xFF8B6914)],
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(
                'Z',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (!collapsed) ...[
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Zaytouna Park',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: ShellColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final NavMeta meta;
  final bool isActive;
  final bool collapsed;
  final VoidCallback onTap;
  const _SidebarItem({
    required this.meta,
    required this.isActive,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? 0 : 14,
        vertical: 12,
      ),
      margin: EdgeInsets.only(bottom: 4.h),
      decoration: BoxDecoration(
        color: isActive
            ? ShellColors.activeBlue.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: collapsed
          ? Center(
              child: Icon(
                meta.icon,
                color: isActive
                    ? ShellColors.activeBlue
                    : ShellColors.textSecondary,
                size: 22.sp,
              ),
            )
          : Row(
              children: [
                Icon(
                  meta.icon,
                  color: isActive
                      ? ShellColors.activeBlue
                      : ShellColors.textSecondary,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    meta.label,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? ShellColors.activeBlue
                          : ShellColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );

    final inkwell = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12.r),
        child: content,
      ),
    );

    return collapsed
        ? Tooltip(message: meta.label, preferBelow: false, child: inkwell)
        : inkwell;
  }
}

class _ShellHeader extends StatelessWidget {
  final List<NavMeta> allowedTabs;
  final NavTab activeTab;
  final bool isPhone;
  final bool showMenuButton;

  const _ShellHeader({
    required this.allowedTabs,
    required this.activeTab,
    required this.isPhone,
    required this.showMenuButton,
  });

  @override
  Widget build(BuildContext context) {
    final activeItemLabel = allowedTabs
        .firstWhere((e) => e.tab == activeTab, orElse: () => _allNavItems.first)
        .label;

    final user = RouteGuard.user;
    final fullName = user?.fullName;
    final firstName = (fullName == null || fullName.trim().isEmpty)
        ? 'User'
        : fullName.trim().split(' ').first;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 12 : 24,
        vertical: isPhone ? 12 : 16,
      ),
      decoration: const BoxDecoration(
        color: ShellColors.bg,
        border: Border(bottom: BorderSide(color: ShellColors.border, width: 1)),
      ),
      child: Row(
        children: [
          if (showMenuButton) ...[
            Builder(
              builder: (ctx) => IconButton(
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                icon: const Icon(
                  Icons.menu_rounded,
                  color: ShellColors.textPrimary,
                ),
              ),
            ),
            SizedBox(width: 4.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activeItemLabel,
                  style: GoogleFonts.inter(
                    fontSize: isPhone ? 18.sp : 22.sp,
                    fontWeight: FontWeight.w600,
                    color: ShellColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isPhone) ...[
                  SizedBox(height: 2.h),
                  Text(
                    'Zaytouna Park Management System',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: ShellColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          const _HeaderAction(icon: Icons.notifications_none_rounded),
          SizedBox(width: 8.w),
          _UserProfile(userName: firstName, condensed: isPhone),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  const _HeaderAction({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ShellColors.surface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: ShellColors.border),
          ),
          child: Icon(icon, size: 18.sp, color: ShellColors.textSecondary),
        ),
      ),
    );
  }
}

class _UserProfile extends StatelessWidget {
  final String userName;
  final bool condensed;
  const _UserProfile({required this.userName, required this.condensed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: condensed ? 4 : 6, vertical: 4),
      decoration: BoxDecoration(
        color: ShellColors.surface,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: ShellColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: ShellColors.activeBlue,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!condensed) ...[
            SizedBox(width: 8.w),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                userName,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: ShellColors.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarLogout extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onTap;
  const _SidebarLogout({required this.collapsed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? 0 : 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: collapsed
          ? Center(
              child: Icon(
                Icons.logout_rounded,
                color: const Color(0xFFEF4444),
                size: 20.sp,
              ),
            )
          : Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: const Color(0xFFEF4444),
                  size: 18.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Sign Out',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFEF4444),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );

    final inkwell = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: content,
      ),
    );

    return collapsed
        ? Tooltip(message: 'Sign Out', preferBelow: false, child: inkwell)
        : inkwell;
  }
}

class _PremiumBottomNav extends StatelessWidget {
  final List<NavMeta> allowedTabs;
  final NavTab activeTab;
  final ValueChanged<NavTab> onTab;
  const _PremiumBottomNav({
    required this.allowedTabs,
    required this.activeTab,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context) {
    const preferredMobileTabs = [
      NavTab.dashboard,
      NavTab.pos,
      NavTab.sales,
      NavTab.menu,
      NavTab.orders,
    ];
    final mobileItems = allowedTabs
        .where((i) => preferredMobileTabs.contains(i.tab))
        .take(5)
        .toList();

    return SafeArea(
      top: false,
      child: Container(
        height: 64.h,
        decoration: const BoxDecoration(
          color: ShellColors.bg,
          border: Border(top: BorderSide(color: ShellColors.border, width: 1)),
        ),
        child: Row(
          children: mobileItems.map((item) {
            final isActive = activeTab == item.tab;
            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTab(item.tab);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isActive
                            ? ShellColors.activeBlue
                            : ShellColors.textSecondary,
                        size: 22.sp,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isActive
                              ? ShellColors.activeBlue
                              : ShellColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
