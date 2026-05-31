// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:zaytouna_park/Core/Routers/route_guard.dart';
import 'package:zaytouna_park/Core/Routers/routes.dart';
import 'package:zaytouna_park/Features/admin/home_admin.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Customers/customers.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Terminal/terminalscreen.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Orders/orders.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Facilities/facilities_booking_page.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Facilities/facility_bookings_list_page.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Tables/tables.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Tables/manage_tables_page.dart';

import 'package:zaytouna_park/Features/kitchen/home_kitchen.dart';
import 'package:zaytouna_park/Features/kitchen/widgets/menu%20mangement/menumanagementscreen.dart';
import 'package:zaytouna_park/Features/shared/placeholder_screen.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────────
class _S {
  static const primary = Color(0xFF1A6B3C);
  static const primaryD = Color(0xFF134D2B);

  static const bg = Color(0xFFFFFFFF);
  static const sidebarBg = Color(0xFFF8FAF9);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFDDE6DF);

  static const ink = Color(0xFF0D1F15);
  static const muted = Color(0xFF6B7F72);
  static const muted2 = Color(0xFFA0B0A7);

  static const danger = Color(0xFFDC2626);
  static const dangerBg = Color(0xFFFEE2E2);
}

TextStyle _sLabel(double s, {FontWeight w = FontWeight.w600, Color? c}) =>
    GoogleFonts.inter(fontSize: s, fontWeight: w, color: c ?? _S.ink);

// ─── NAV TABS (ALL admin-accessible pages) ────────────────────────────
enum AdminNavTab {
  // Core
  dashboard,
  pos,
  kitchen,
  menuManager,
  // Orders & Customers
  orders,
  customers,
  // Sports & Facilities
  bookings,
  playground,
  bookFacility,
  facilityBookings,
  facilities,
  // Tables
  tables,
  manageTables,
  // Inventory
  inventory,
  // Finance
  expenses,
  sales,
  reports,
  // Admin
  staff,
  settings,
}

class NavMeta {
  final AdminNavTab tab;
  final IconData icon;
  final String label;
  final String? section; // section header label (null = same section as prev)
  const NavMeta({
    required this.tab,
    required this.icon,
    required this.label,
    this.section,
  });
}

const navItems = [
  // ── CORE ──
  NavMeta(
    tab: AdminNavTab.dashboard,
    icon: Icons.dashboard_rounded,
    label: 'Dashboard',
    section: 'CORE',
  ),
  NavMeta(
    tab: AdminNavTab.pos,
    icon: Icons.point_of_sale_rounded,
    label: 'POS Terminal',
  ),
  NavMeta(
    tab: AdminNavTab.kitchen,
    icon: Icons.restaurant_menu_rounded,
    label: 'Kitchen Display',
  ),
  NavMeta(
    tab: AdminNavTab.menuManager,
    icon: Icons.menu_book_rounded,
    label: 'Menu Manager',
  ),
  // ── SALES ──
  NavMeta(
    tab: AdminNavTab.orders,
    icon: Icons.receipt_long_rounded,
    label: 'Orders',
    section: 'SALES',
  ),
  NavMeta(
    tab: AdminNavTab.customers,
    icon: Icons.people_alt_rounded,
    label: 'Customers',
  ),
  NavMeta(
    tab: AdminNavTab.sales,
    icon: Icons.attach_money_rounded,
    label: 'Sales Report',
  ),
  NavMeta(
    tab: AdminNavTab.reports,
    icon: Icons.insights_rounded,
    label: 'Reports & Analytics',
  ),
  // ── FACILITIES ──
  NavMeta(
    tab: AdminNavTab.bookFacility,
    icon: Icons.event_available_rounded,
    label: 'Book Facility',
    section: 'FACILITIES',
  ),
  NavMeta(
    tab: AdminNavTab.facilityBookings,
    icon: Icons.event_note_rounded,
    label: 'Facility Bookings',
  ),
  NavMeta(
    tab: AdminNavTab.facilities,
    icon: Icons.apartment_rounded,
    label: 'Manage Facilities',
  ),
  NavMeta(
    tab: AdminNavTab.bookings,
    icon: Icons.sports_tennis_rounded,
    label: 'Sports Bookings',
  ),
  NavMeta(
    tab: AdminNavTab.playground,
    icon: Icons.child_friendly_rounded,
    label: 'Playground',
  ),
  // ── RESTAURANT ──
  NavMeta(
    tab: AdminNavTab.tables,
    icon: Icons.table_restaurant_rounded,
    label: 'Tables View',
    section: 'RESTAURANT',
  ),
  NavMeta(
    tab: AdminNavTab.manageTables,
    icon: Icons.table_chart_rounded,
    label: 'Manage Tables',
  ),
  // ── BACK OFFICE ──
  NavMeta(
    tab: AdminNavTab.inventory,
    icon: Icons.inventory_2_rounded,
    label: 'Inventory',
    section: 'BACK OFFICE',
  ),
  NavMeta(
    tab: AdminNavTab.expenses,
    icon: Icons.monetization_on_rounded,
    label: 'Expenses & Bills',
  ),
  NavMeta(
    tab: AdminNavTab.staff,
    icon: Icons.badge_rounded,
    label: 'Staff Management',
  ),
  NavMeta(
    tab: AdminNavTab.settings,
    icon: Icons.settings_rounded,
    label: 'System Settings',
  ),
];

// bottom nav (mobile) — 5 most important
const _mobileNavTabs = [
  AdminNavTab.dashboard,
  AdminNavTab.pos,
  AdminNavTab.kitchen,
  AdminNavTab.orders,
  AdminNavTab.reports,
];

// ─── SHELL ────────────────────────────────────────────────────────────
class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});
  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  AdminNavTab _active = AdminNavTab.dashboard;

  void _select(AdminNavTab tab) => setState(() => _active = tab);

  Widget _buildPage() {
    switch (_active) {
      // Core
      case AdminNavTab.dashboard:
        return const HomeAdmin();
      case AdminNavTab.pos:
        return const UpgradedPOS();
      case AdminNavTab.kitchen:
        return const KitchenScreen();
      case AdminNavTab.menuManager:
        return const MenuManagementScreen();
      // Sales
      case AdminNavTab.orders:
        return const OrdersScreen();
      case AdminNavTab.customers:
        return const CustomersScreen();
      case AdminNavTab.sales:
        return const PlaceholderScreen(
          title: 'Sales Report',
          icon: Icons.attach_money,
        );
      case AdminNavTab.reports:
        return const PlaceholderScreen(
          title: 'Reports & Analytics',
          icon: Icons.insights,
        );
      // Facilities
      case AdminNavTab.bookFacility:
        return const FacilitiesBookingPage();
      case AdminNavTab.facilityBookings:
        return const FacilityBookingsListPage();
      case AdminNavTab.facilities:
        return const PlaceholderScreen(
          title: 'Manage Facilities',
          icon: Icons.apartment,
        );
      case AdminNavTab.bookings:
        return const PlaceholderScreen(
          title: 'Sports Bookings',
          icon: Icons.sports_tennis,
        );
      case AdminNavTab.playground:
        return const PlaceholderScreen(
          title: 'Playground',
          icon: Icons.child_friendly,
        );
      // Restaurant
      case AdminNavTab.tables:
        return const TablesPage();
      case AdminNavTab.manageTables:
        return const ManageTablesPage();
      // Back Office
      case AdminNavTab.inventory:
        return const PlaceholderScreen(
          title: 'Inventory',
          icon: Icons.inventory_2,
        );
      case AdminNavTab.expenses:
        return const PlaceholderScreen(
          title: 'Expenses & Bills',
          icon: Icons.monetization_on,
        );
      case AdminNavTab.staff:
        return const PlaceholderScreen(
          title: 'Staff Management',
          icon: Icons.badge,
        );
      case AdminNavTab.settings:
        return const PlaceholderScreen(
          title: 'System Settings',
          icon: Icons.settings,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _S.bg,
      drawer: MediaQuery.of(context).size.width < 1024
          ? Drawer(
              backgroundColor: _S.sidebarBg,
              child: _Sidebar(
                active: _active,
                onTab: (t) {
                  Navigator.pop(context);
                  _select(t);
                },
                onLogout: () => _confirmLogout(context),
              ),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, cs) {
          final isWide = cs.maxWidth >= 1024;
          final isMedium = cs.maxWidth >= 700;
          return Row(
            children: [
              if (isWide)
                _Sidebar(
                  active: _active,
                  onTab: _select,
                  onLogout: () => _confirmLogout(context),
                ),
              Expanded(
                child: Column(
                  children: [
                    _Header(
                      active: _active,
                      isWide: isWide,
                      onMenuTap: () => Scaffold.of(context).openDrawer(),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: KeyedSubtree(
                          key: ValueKey(_active),
                          child: _buildPage(),
                        ),
                      ),
                    ),
                    if (!isMedium) _BottomNav(active: _active, onTab: _select),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _S.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: _S.dangerBg,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: _S.danger,
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 18.h),
              Text('Sign Out', style: _sLabel(22.sp, w: FontWeight.w700)),
              SizedBox(height: 8.h),
              Text(
                'Are you sure you want to sign out?',
                style: _sLabel(14.sp, w: FontWeight.w500, c: _S.muted),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: const BorderSide(color: _S.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: _sLabel(13.sp, w: FontWeight.w600, c: _S.muted),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await RouteGuard.logout();
                        if (ctx.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            ctx,
                            Routes.login,
                            (_) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _S.danger,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Sign Out',
                        style: _sLabel(
                          13.sp,
                          w: FontWeight.w600,
                          c: Colors.white,
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

// ─── SIDEBAR ──────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final AdminNavTab active;
  final ValueChanged<AdminNavTab> onTab;
  final VoidCallback onLogout;
  const _Sidebar({
    required this.active,
    required this.onTab,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 265.w,
    decoration: const BoxDecoration(
      color: _S.sidebarBg,
      border: Border(right: BorderSide(color: _S.border)),
    ),
    child: Column(
      children: [
        SizedBox(height: 24.h),
        _SidebarLogo(),
        SizedBox(height: 20.h),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            physics: const BouncingScrollPhysics(),
            itemCount: navItems.length,
            itemBuilder: (_, i) {
              final item = navItems[i];
              // Section header
              if (item.section != null) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 8.w,
                    top: i == 0 ? 0 : 16.h,
                    bottom: 6.h,
                  ),
                  child: Text(
                    item.section!,
                    style: GoogleFonts.inter(
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.w800,
                      color: _S.muted2,
                      letterSpacing: 1.2,
                    ),
                  ),
                );
              }
              return _SidebarItem(
                meta: item,
                isActive: active == item.tab,
                onTap: () => onTab(item.tab),
              );
            },
          ),
        ),
        const Divider(color: _S.border, height: 1),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: _SidebarLogout(onTap: onLogout),
        ),
      ],
    ),
  );
}

// Note: section headers need special handling since they're interleaved
// The ListView above already handles it. But we need to NOT show section
// headers as nav items. Let's fix the itemCount / itemBuilder to be correct:
// (The navItems list has section labels baked into the NavMeta.section field
//  so every item is either a section-header row OR a nav item.)

class _SidebarLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 20.w),
    child: Row(
      children: [
        Container(
          height: 40.w,
          width: 40.w,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_S.primary, _S.primaryD],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: _S.primary.withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Z',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zaytouna Park',
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: _S.ink,
              ),
            ),
            Text(
              'Admin Portal',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: _S.muted,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SidebarItem extends StatelessWidget {
  final NavMeta meta;
  final bool isActive;
  final VoidCallback onTap;
  const _SidebarItem({
    required this.meta,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(10.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        margin: EdgeInsets.only(bottom: 2.h),
        decoration: BoxDecoration(
          color: isActive
              ? _S.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          border: isActive
              ? Border.all(color: _S.primary.withValues(alpha: 0.2))
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: isActive ? _S.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(width: 10.w),
            Icon(
              meta.icon,
              color: isActive ? _S.primary : _S.muted,
              size: 19.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                meta.label,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? _S.primary : _S.muted,
                ),
              ),
            ),
            if (isActive)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _S.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _SidebarLogout extends StatelessWidget {
  final VoidCallback onTap;
  const _SidebarLogout({required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: _S.dangerBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: _S.danger.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 13),
            Icon(Icons.logout_rounded, color: _S.danger, size: 19.sp),
            SizedBox(width: 12.w),
            Text(
              'Sign Out',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: _S.danger,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── HEADER ───────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final AdminNavTab active;
  final bool isWide;
  final VoidCallback onMenuTap;
  const _Header({
    required this.active,
    required this.isWide,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final item = navItems.firstWhere((e) => e.tab == active);
    final user = RouteGuard.user;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: const BoxDecoration(
        color: _S.bg,
        border: Border(bottom: BorderSide(color: _S.border)),
      ),
      child: Row(
        children: [
          if (!isWide) ...[
            IconButton(
              onPressed: onMenuTap,
              icon: const Icon(Icons.menu_rounded, color: _S.ink),
            ),
            SizedBox(width: 4.w),
          ],
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: _S.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(item.icon, size: 18.sp, color: _S.primary),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: _S.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Admin View',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: _S.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          _HeaderIconBtn(icon: Icons.notifications_outlined, onTap: () {}),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: _S.surface,
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(color: _S.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 15.r,
                  backgroundColor: _S.primary,
                  child: Text(
                    (user?.fullName.isNotEmpty == true)
                        ? user!.fullName[0].toUpperCase()
                        : 'A',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Padding(
                  padding: EdgeInsets.only(right: 10.w),
                  child: Text(
                    user?.fullName.split(' ').first ?? 'Admin',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: _S.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.all(9.w),
        decoration: BoxDecoration(
          color: _S.surface,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: _S.border),
        ),
        child: Icon(icon, size: 19.sp, color: _S.muted),
      ),
    ),
  );
}

// ─── BOTTOM NAV (mobile) ──────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final AdminNavTab active;
  final ValueChanged<AdminNavTab> onTab;
  const _BottomNav({required this.active, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final mobileItems = navItems
        .where((i) => _mobileNavTabs.contains(i.tab))
        .toList();

    return Container(
      height: 68.h,
      decoration: const BoxDecoration(
        color: _S.bg,
        border: Border(top: BorderSide(color: _S.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: mobileItems.map((item) {
          final isActive = active == item.tab;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onTab(item.tab);
              },
              borderRadius: BorderRadius.circular(12.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isActive
                      ? _S.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      color: isActive ? _S.primary : _S.muted2,
                      size: 22.sp,
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      item.label.split(' ').first,
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive ? _S.primary : _S.muted2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
