// lib/Features/Shell/shell_screen.dart
// ignore_for_file: deprecated_member_use, file_names

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaytouna_park/Core/Models/routes.dart';
import 'package:zaytouna_park/Features/Home/Widgets/Expenses/expenses.dart';
import 'package:zaytouna_park/Features/Home/Widgets/Inventory/inventory.dart';
import 'package:zaytouna_park/Features/Home/Widgets/Terminal/terminalscreen.dart';
import 'package:zaytouna_park/Features/Home/home.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TAB DEFINITIONS
// ─────────────────────────────────────────────────────────────────────────────

enum _Tab { dashboard, inventory, settings, expenses }

class _TabMeta {
  final _Tab tab;
  final IconData icon;
  final String label;
  const _TabMeta(this.tab, this.icon, this.label);
}

const _navItems = [
  _TabMeta(_Tab.dashboard, Icons.dashboard_rounded, 'Dashboard'),
  _TabMeta(_Tab.inventory, Icons.inventory_2_outlined, 'Inventory'),
  _TabMeta(_Tab.expenses, Icons.money, 'Expenses'),
  _TabMeta(_Tab.settings, Icons.settings_outlined, 'Settings'),
];

// ─────────────────────────────────────────────────────────────────────────────
//  SHELL SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  bool _isDark = true;
  _Tab _activeTab = _Tab.dashboard;

  // ── Palette ───────────────────────────────────────────────
  Color get bg => _isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF1F4F9);
  Color get surface =>
      _isDark ? const Color(0xFF111118) : const Color(0xFFFFFFFF);
  Color get bdr => _isDark ? const Color(0x0FFFFFFF) : const Color(0x18000000);
  Color get textMuted =>
      _isDark ? const Color(0x73F0EFF8) : const Color(0x88000000);

  static const Color red = Color(0xFFFF3B3B);

  void _toggleTheme() => setState(() => _isDark = !_isDark);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: LayoutBuilder(
        builder: (ctx, c) {
          if (c.maxWidth >= 700) {
            return Row(
              children: [
                _Sidebar(
                  isDark: _isDark,
                  activeTab: _activeTab,
                  onTab: (t) => setState(() => _activeTab = t),
                  onToggleTheme: _toggleTheme,
                  onTerminal: () => _pushTerminal(ctx),
                  onLogout: () => _logout(ctx),
                ),
                Expanded(child: _page(ctx, c)),
              ],
            );
          }
          return Column(
            children: [
              Expanded(child: _page(ctx, c)),
              _BottomNav(
                isDark: _isDark,
                activeTab: _activeTab,
                onTab: (t) => setState(() => _activeTab = t),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _page(BuildContext ctx, BoxConstraints c) {
    switch (_activeTab) {
      case _Tab.dashboard:
        return HomeScreen(
          isDark: _isDark,
          onToggleTheme: _toggleTheme,
          onNavigateTab: (t) => setState(() => _activeTab = t as _Tab),
          onLaunchTerminal: () => _pushTerminal(ctx),
        );
      case _Tab.inventory:
        return InventoryScreen();
      case _Tab.settings:
        return _Placeholder(
          isDark: _isDark,
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'CONFIGURATION',
          onThemeToggle: _toggleTheme,
          isDarkToggle: _isDark,
        );
      case _Tab.expenses:
        return ExpensesScreen();
    }
  }

  void _pushTerminal(BuildContext ctx) {
    Navigator.of(ctx).push(
      PageRouteBuilder(
        settings: RouteSettings(
          name: Routes.terminal,
          arguments: {'isDark': _isDark},
        ),
        pageBuilder: (_, _, _) => POSScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
  }

  void _logout(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF111118) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Sign Out',
          style: GoogleFonts.syne(
            color: _isDark ? const Color(0xFFF0EFF8) : const Color(0xFF0F0F1A),
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.dmSans(color: textMuted, fontSize: 12.5.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(color: textMuted, fontSize: 12.sp),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(
                ctx,
              ).pushNamedAndRemoveUntil(Routes.login, (_) => false);
            },
            child: Text(
              'Sign Out',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final bool isDark;
  final _Tab activeTab;
  final ValueChanged<_Tab> onTab;
  final VoidCallback onToggleTheme, onTerminal, onLogout;

  const _Sidebar({
    required this.isDark,
    required this.activeTab,
    required this.onTab,
    required this.onToggleTheme,
    required this.onTerminal,
    required this.onLogout,
  });

  static const Color red = Color(0xFFFF3B3B);
  static const Color redDim = Color(0x1FFF3B3B);
  static const Color redGlow = Color(0x40FF3B3B);
  static const Color gold = Color(0xFFF5C842);
  static const Color goldDim = Color(0x1AF5C842);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64.w,
      color: const Color(0xFF0E0E16),
      child: Column(
        children: [
          SizedBox(height: 20.h),
          // Logo
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: red,
              borderRadius: BorderRadius.circular(9.r),
              boxShadow: [const BoxShadow(color: redGlow, blurRadius: 14)],
            ),
            child: Icon(Icons.bolt_rounded, color: Colors.white, size: 17.sp),
          ),
          SizedBox(height: 22.h),
          // Nav items
          ...List.generate(_navItems.length, (i) {
            // Adds a divider before the "Settings" tab
            if (i == _navItems.length - 1) {
              return Column(children: [_div(), _btn(_navItems[i])]);
            }
            return _btn(_navItems[i]);
          }),
          const Spacer(),
          // Terminal shortcut
          Tooltip(
            message: 'Open Terminal',
            preferBelow: false,
            child: GestureDetector(
              onTap: onTerminal,
              child: Container(
                width: 38.w,
                height: 38.w,
                margin: EdgeInsets.only(bottom: 6.h),
                decoration: BoxDecoration(
                  color: redDim,
                  border: Border.all(color: const Color(0x33FF3B3B)),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Icon(
                  Icons.point_of_sale_rounded,
                  size: 16.sp,
                  color: red,
                ),
              ),
            ),
          ),
          // Theme toggle
          Tooltip(
            message: isDark ? 'Light Mode' : 'Dark Mode',
            preferBelow: false,
            child: GestureDetector(
              onTap: onToggleTheme,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36.w,
                height: 36.w,
                margin: EdgeInsets.only(bottom: 6.h),
                decoration: BoxDecoration(
                  color: isDark ? goldDim : const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 16.sp,
                  color: isDark ? gold : const Color(0xFFAAAAAA),
                ),
              ),
            ),
          ),
          // Logout
          Tooltip(
            message: 'Sign Out',
            preferBelow: false,
            child: GestureDetector(
              onTap: onLogout,
              child: Container(
                width: 38.w,
                height: 38.w,
                margin: EdgeInsets.only(bottom: 16.h),
                child: Icon(Icons.logout_rounded, size: 18.sp, color: red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(_TabMeta meta) {
    final active = activeTab == meta.tab;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (active)
            Positioned(
              left: 0,
              child: Container(
                width: 3,
                height: 18.h,
                decoration: BoxDecoration(
                  color: red,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
          Center(
            child: Tooltip(
              message: meta.label,
              preferBelow: false,
              child: GestureDetector(
                onTap: () => onTab(meta.tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: active ? redDim : Colors.transparent,
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                  child: Icon(
                    meta.icon,
                    size: 18.sp,
                    color: active ? red : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _div() => Container(
    width: 26.w,
    height: 1,
    margin: EdgeInsets.symmetric(vertical: 5.h),
    color: const Color(0x1AFFFFFF),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  BOTTOM NAV  (mobile)
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final bool isDark;
  final _Tab activeTab;
  final ValueChanged<_Tab> onTab;
  const _BottomNav({
    required this.isDark,
    required this.activeTab,
    required this.onTab,
  });

  static const Color red = Color(0xFFFF3B3B);
  static const Color redDim = Color(0x1FFF3B3B);

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF111118) : Colors.white;
    final bdr = isDark ? const Color(0x0FFFFFFF) : const Color(0x18000000);
    final textMuted = isDark
        ? const Color(0x73F0EFF8)
        : const Color(0x88000000);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: bdr)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 7.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navItems.map((meta) {
              final active = activeTab == meta.tab;
              return GestureDetector(
                onTap: () => onTab(meta.tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: active ? redDim : Colors.transparent,
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                  child: Icon(
                    meta.icon,
                    size: 20.sp,
                    color: active ? red : textMuted,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PLACEHOLDER
// ─────────────────────────────────────────────────────────────────────────────

class _Placeholder extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onThemeToggle;
  final bool isDarkToggle;

  const _Placeholder({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onThemeToggle,
    this.isDarkToggle = true,
  });

  Color get bg => isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF1F4F9);
  Color get surface =>
      isDark ? const Color(0xFF111118) : const Color(0xFFFFFFFF);
  Color get bdr => isDark ? const Color(0x0FFFFFFF) : const Color(0x18000000);
  Color get textClr =>
      isDark ? const Color(0xFFF0EFF8) : const Color(0xFF0F0F1A);
  Color get textMut =>
      isDark ? const Color(0x73F0EFF8) : const Color(0x88000000);
  Color get surf2 => isDark ? const Color(0xFF16161F) : const Color(0xFFEEF0F6);

  static const Color red = Color(0xFFFF3B3B);
  static const Color redDim = Color(0x1FFF3B3B);
  static const Color gold = Color(0xFFF5C842);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: Column(
        children: [
          Container(
            height: 60.h,
            padding: EdgeInsets.symmetric(horizontal: 22.w),
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: bdr)),
            ),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: GoogleFonts.dmMono(
                        fontSize: 8.sp,
                        color: red,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      title,
                      style: GoogleFonts.syne(
                        color: textClr,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (onThemeToggle != null)
                  GestureDetector(
                    onTap: onThemeToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: surf2,
                        border: Border.all(color: bdr),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        isDarkToggle
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        size: 14.sp,
                        color: isDarkToggle ? gold : textMut,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56.w,
                    height: 56.w,
                    decoration: BoxDecoration(
                      color: redDim,
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                    child: Icon(icon, size: 24.sp, color: red),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    title,
                    style: GoogleFonts.syne(
                      color: textClr,
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Coming soon — in development',
                    style: GoogleFonts.dmSans(fontSize: 12.sp, color: textMut),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
