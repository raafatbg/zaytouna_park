// lib/Features/Home/Shell/admin_shell.dart

// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// Core Imports
import 'package:zaytouna_park/Core/Routers/route_guard.dart';
import 'package:zaytouna_park/Core/Routers/routes.dart';

// Feature Screens (Ensure these point to the files we just created!)
import 'package:zaytouna_park/Features/admin/home_admin.dart'; // The standalone Dashboard
import 'package:zaytouna_park/Features/cashier/Widgets/Terminal/terminalscreen.dart';
import 'package:zaytouna_park/Features/kitchen/home_kitchen.dart';
import 'package:zaytouna_park/Features/kitchen/widgets/menu%20mangement/menumanagementscreen.dart';
// Menu Manager
import 'package:zaytouna_park/Features/shared/placeholder_screen.dart';

// ─── CLEAN WHITE PALETTE ──────────────────────────────────────────────────────────
class ShellColors {
  ShellColors._();
  static const bg = Color(0xFFFFFFFF);
  static const sidebarBg = Color(0xFFF8F9FA);
  static const sidebarAccent = Color(0xFFE9ECEF);
  static const activeAccent = Color(0xFFB8860B); // Gold/Amber to match Zaytouna theme
  static const textPrimary = Color(0xFF212529);
  static const textSecondary = Color(0xFF6C757D);
  static const textTertiary = Color(0xFFADB5BD);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE9ECEF);
  static const hover = Color(0xFFF1F3F5);
}

enum AdminNavTab {
  dashboard,
  pos,
  kitchen,
  inventory,
  menuManager,
  staff,
  reports,
  settings,
}

class NavMeta {
  final AdminNavTab tab;
  final IconData icon;
  final String label;
  const NavMeta({required this.tab, required this.icon, required this.label});
}

// Complete Admin Sidebar Menu Items
const navItems = [
  NavMeta(
    tab: AdminNavTab.dashboard,
    icon: Icons.dashboard_rounded,
    label: 'Dashboard',
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
  NavMeta(
    tab: AdminNavTab.inventory,
    icon: Icons.inventory_2_rounded,
    label: 'Inventory',
  ),
  NavMeta(
    tab: AdminNavTab.staff,
    icon: Icons.people_alt_rounded,
    label: 'Staff Management',
  ),
  NavMeta(
    tab: AdminNavTab.reports,
    icon: Icons.insights_rounded,
    label: 'Reports & Analytics',
  ),
  NavMeta(
    tab: AdminNavTab.settings,
    icon: Icons.settings_rounded,
    label: 'System Settings',
  ),
];

// ─── MAIN SHELL ──────────────────────────────────────────────────────────────
class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  AdminNavTab _activeTab = AdminNavTab.dashboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShellColors.bg,
      drawer: MediaQuery.of(context).size.width < 1024
          ? Drawer(
              child: _PremiumSidebar(
                activeTab: _activeTab,
                onTab: (t) {
                  Navigator.pop(context); // Close drawer on mobile
                  _handleTabSelection(t);
                },
                onLogout: () => _confirmLogout(context),
              ),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1024;
          final isMedium = constraints.maxWidth >= 700;

          return Row(
            children: [
              if (isWide)
                _PremiumSidebar(
                  activeTab: _activeTab,
                  onTab: _handleTabSelection,
                  onLogout: () => _confirmLogout(context),
                ),
              Expanded(
                child: Column(
                  children: [
                    _ShellHeader(
                      activeTab: _activeTab,
                      isWide: isWide,
                      onMenuTap: () => Scaffold.of(context).openDrawer(),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey(_activeTab),
                          child: _buildPage(),
                        ),
                      ),
                    ),
                    if (!isMedium)
                      _PremiumBottomNav(
                        activeTab: _activeTab,
                        onTab: _handleTabSelection,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleTabSelection(AdminNavTab tab) {
    // If you want POS or KDS to open full-screen (without the shell), use Navigator.pushNamed instead
    // For now, they load inside the shell.
    setState(() => _activeTab = tab);
  }

  Widget _buildPage() {
    switch (_activeTab) {
      case AdminNavTab.dashboard:
        return const HomeAdmin(); // The dashboard UI we built
      case AdminNavTab.pos:
        return const UpgradedPOS(); // The POS UI we built
      case AdminNavTab.kitchen:
        return const KitchenScreen(); // The KDS UI we built
      case AdminNavTab.menuManager:
        return const MenuManagementScreen(); // The Menu UI we built
      case AdminNavTab.inventory:
        return const PlaceholderScreen(title: 'Inventory', icon: Icons.inventory_2);
      case AdminNavTab.staff:
        return const PlaceholderScreen(title: 'Staff Management', icon: Icons.people);
      case AdminNavTab.reports:
        return const PlaceholderScreen(title: 'Reports & Analytics', icon: Icons.insights);
      case AdminNavTab.settings:
        return const PlaceholderScreen(title: 'System Settings', icon: Icons.settings);
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
                        await RouteGuard.logout();
                        if (ctx.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            ctx,
                            Routes.login,
                            (r) => false,
                          );
                        }
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

// ─── COMPONENTS ──────────────────────────────────────────────────────────────

class _PremiumSidebar extends StatelessWidget {
  final AdminNavTab activeTab;
  final ValueChanged<AdminNavTab> onTab;
  final VoidCallback onLogout;

  const _PremiumSidebar({
    required this.activeTab,
    required this.onTab,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280.w,
      decoration: const BoxDecoration(
        color: ShellColors.bg,
        border: Border(right: BorderSide(color: ShellColors.border, width: 1)),
      ),
      child: Column(
        children: [
          SizedBox(height: 32.h),
          const _SidebarLogo(),
          SizedBox(height: 40.h),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              physics: const BouncingScrollPhysics(),
              children: navItems
                  .map(
                    (item) => _SidebarItem(
                      meta: item,
                      isActive: activeTab == item.tab,
                      onTap: () => onTab(item.tab),
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            child: _SidebarLogout(onTap: onLogout),
          ),
        ],
      ),
    );
  }
}

class _SidebarLogo extends StatelessWidget {
  const _SidebarLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Container(
            height: 40.w,
            width: 40.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB8860B), Color(0xFF8B6914)],
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(
                "Z",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Zaytouna Park",
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: ShellColors.textPrimary,
                ),
              ),
              Text(
                "Admin Portal",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: ShellColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          margin: EdgeInsets.only(bottom: 4.h),
          decoration: BoxDecoration(
            color: isActive
                ? ShellColors.activeAccent.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(
                meta.icon,
                color: isActive
                    ? ShellColors.activeAccent
                    : ShellColors.textSecondary,
                size: 22.sp,
              ),
              SizedBox(width: 14.w),
              Text(
                meta.label,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? ShellColors.activeAccent
                      : ShellColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellHeader extends StatelessWidget {
  final AdminNavTab activeTab;
  final bool isWide;
  final VoidCallback onMenuTap;

  const _ShellHeader({
    required this.activeTab,
    required this.isWide,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeItem = navItems.firstWhere((e) => e.tab == activeTab);
    final user = RouteGuard.user;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: const BoxDecoration(
        color: ShellColors.bg,
        border: Border(bottom: BorderSide(color: ShellColors.border, width: 1)),
      ),
      child: Row(
        children: [
          if (!isWide) ...[
            IconButton(
              onPressed: onMenuTap,
              icon: const Icon(
                Icons.menu_rounded,
                color: ShellColors.textPrimary,
              ),
            ),
            SizedBox(width: 8.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeItem.label,
                  style: GoogleFonts.inter(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w600,
                    color: ShellColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  "Overview & Controls",
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: ShellColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          const _HeaderAction(icon: Icons.notifications_none_rounded),
          SizedBox(width: 12.w),
          _UserProfile(userName: user?.fullName.split(' ').first ?? 'Admin'),
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
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: ShellColors.surface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: ShellColors.border),
          ),
          child: Icon(icon, size: 20.sp, color: ShellColors.textSecondary),
        ),
      ),
    );
  }
}

class _UserProfile extends StatelessWidget {
  final String userName;

  const _UserProfile({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: ShellColors.surface,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: ShellColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16.r,
            backgroundColor: ShellColors.activeAccent,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: Text(
              userName,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: ShellColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarLogout extends StatelessWidget {
  final VoidCallback onTap;
  const _SidebarLogout({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: const Color(0xFFEF4444),
                size: 20.sp,
              ),
              SizedBox(width: 14.w),
              Text(
                'Sign Out',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumBottomNav extends StatelessWidget {
  final AdminNavTab activeTab;
  final ValueChanged<AdminNavTab> onTab;

  const _PremiumBottomNav({required this.activeTab, required this.onTab});

  @override
  Widget build(BuildContext context) {
    // Filter to the 5 most important tabs for mobile admin
    final mobileItems = navItems
        .where(
          (i) => [
            AdminNavTab.dashboard,
            AdminNavTab.pos,
            AdminNavTab.kitchen,
            AdminNavTab.menuManager,
            AdminNavTab.reports,
          ].contains(i.tab),
        )
        .toList();

    return Container(
      height: 70.h,
      decoration: const BoxDecoration(
        color: ShellColors.bg,
        border: Border(top: BorderSide(color: ShellColors.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: mobileItems.map((item) {
          final isActive = activeTab == item.tab;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onTab(item.tab);
              },
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      color: isActive
                          ? ShellColors.activeAccent
                          : ShellColors.textSecondary,
                      size: 22.sp,
                    ),
                    if (isActive) ...[
                      SizedBox(height: 4.h),
                      Container(
                        width: 4.w,
                        height: 4.h,
                        decoration: const BoxDecoration(
                          color: ShellColors.activeAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
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