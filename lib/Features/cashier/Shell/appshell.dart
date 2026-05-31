// lib/Features/Home/Shell/cashier_shell.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaytouna_park/Core/Routers/route_guard.dart';
import 'package:zaytouna_park/Core/Routers/routes.dart';
import 'package:zaytouna_park/Features/admin/Widgets/Inventory/inventory.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Customers/customers.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Expenses/expenses.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Sales/sales.dart';

import 'package:zaytouna_park/Features/cashier/Widgets/Terminal/terminalscreen.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Orders/orders.dart';

import 'package:zaytouna_park/Features/cashier/Widgets/Tables/tables.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Tables/manage_tables_page.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Facilities/facilities_booking_page.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Facilities/facility_bookings_list_page.dart';
import 'package:zaytouna_park/Features/cashier/cash_home.dart';

import 'package:zaytouna_park/Features/kitchen/widgets/menu%20mangement/menumanagementscreen.dart';

// ─── DESIGN TOKENS ───────────────────────────────────────────────────────────
class _C {
  _C._();
  static const primary = Color(0xFF1A6B3C);
  static const primaryD = Color(0xFF134D2B);
  static const primaryL = Color(0xFFE8F5EE);
  static const accent = Color(0xFFD4A017);
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

// ─── NAV TABS ────────────────────────────────────────────────────────────────
enum CashierTab {
  home,
  pos,
  orders,
  customers,
  tables,
  manageTables,
  bookFacility,
  facilityBookings,
  sales,
  expenses,
  inventory,
  menu,
}

// ─── NAV ITEM MODEL ──────────────────────────────────────────────────────────
class _NavItem {
  final CashierTab tab;
  final IconData icon;
  final String label;
  final String? section; // section header above this item
  const _NavItem(this.tab, this.icon, this.label, {this.section});
}

const _navItems = <_NavItem>[
  // ── DAILY OPS
  _NavItem(CashierTab.home, Icons.home_rounded, 'Home', section: 'DAILY OPS'),
  _NavItem(CashierTab.pos, Icons.point_of_sale_rounded, 'POS Terminal'),
  _NavItem(CashierTab.orders, Icons.receipt_long_rounded, 'Orders'),
  _NavItem(CashierTab.customers, Icons.people_rounded, 'Customers'),
  _NavItem(CashierTab.tables, Icons.table_restaurant_rounded, 'Tables'),
  // ── FACILITIES
  _NavItem(
    CashierTab.bookFacility,
    Icons.event_available_rounded,
    'Book Facility',
    section: 'FACILITIES',
  ),
  _NavItem(
    CashierTab.facilityBookings,
    Icons.event_note_rounded,
    'Bookings List',
  ),
  // ── MANAGEMENT
  _NavItem(
    CashierTab.sales,
    Icons.attach_money_rounded,
    'Sales Report',
    section: 'MANAGEMENT',
  ),
  _NavItem(
    CashierTab.expenses,
    Icons.account_balance_wallet_rounded,
    'Expenses & Bills',
  ),
  _NavItem(CashierTab.inventory, Icons.inventory_2_rounded, 'Inventory'),
  _NavItem(CashierTab.menu, Icons.restaurant_menu_rounded, 'Menu Management'),
  _NavItem(CashierTab.manageTables, Icons.edit_note_rounded, 'Manage Tables'),
];

// ─── SHELL ───────────────────────────────────────────────────────────────────
class CashierShellScreen extends StatefulWidget {
  const CashierShellScreen({super.key});
  @override
  State<CashierShellScreen> createState() => _CashierShellScreenState();
}

class _CashierShellScreenState extends State<CashierShellScreen> {
  CashierTab _current = CashierTab.home;

  void _select(CashierTab t) => setState(() => _current = t);

  /// Called by PremiumCashierHome's "Launch Terminal" button
  void _launchTerminal() => _select(CashierTab.pos);

  Widget _buildPage() {
    switch (_current) {
      case CashierTab.home:
        return PremiumCashierHome(onLaunchTerminal: _launchTerminal);
      case CashierTab.pos:
        return const UpgradedPOS();
      case CashierTab.orders:
        return const OrdersScreen();
      case CashierTab.customers:
        return const CustomersScreen();
      case CashierTab.tables:
        return const TablesPage();
      case CashierTab.manageTables:
        return const ManageTablesPage();
      case CashierTab.bookFacility:
        return const FacilitiesBookingPage();
      case CashierTab.facilityBookings:
        return const FacilityBookingsListPage();
      case CashierTab.sales:
        return const SalesScreen();
      case CashierTab.expenses:
        return const ExpensesScreen();
      case CashierTab.inventory:
        return const InventoryScreen();
      case CashierTab.menu:
        return const MenuManagementScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;
    return Scaffold(
      backgroundColor: _C.bg,
      body: isMobile ? _buildMobile() : _buildDesktop(),
    );
  }

  // ── DESKTOP: sidebar + content ─────────────────────────────────────────────
  Widget _buildDesktop() {
    return Row(
      children: [
        _Sidebar(current: _current, onSelect: _select),
        const VerticalDivider(width: 1, thickness: 1, color: _C.border),
        Expanded(child: _buildPage()),
      ],
    );
  }

  // ── MOBILE: bottom nav + content ───────────────────────────────────────────
  Widget _buildMobile() {
    const bottomTabs = [
      CashierTab.home,
      CashierTab.pos,
      CashierTab.orders,
      CashierTab.tables,
      CashierTab.bookFacility,
    ];
    return Column(
      children: [
        Expanded(child: _buildPage()),
        _BottomNav(tabs: bottomTabs, current: _current, onSelect: _select),
      ],
    );
  }
}

// ─── SIDEBAR ─────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final CashierTab current;
  final ValueChanged<CashierTab> onSelect;
  const _Sidebar({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: _C.sidebarBg,
      child: Column(
        children: [
          // Logo / brand header
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _C.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.park_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Zaytouna',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _C.ink,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _C.border),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navItems.length,
              itemBuilder: (_, i) {
                final item = _navItems[i];
                final isActive = item.tab == current;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.section != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                        child: Text(
                          item.section!,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _C.muted2,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    _SidebarTile(
                      item: item,
                      isActive: isActive,
                      onTap: () => onSelect(item.tab),
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1, color: _C.border),
          // Logout
          _LogoutButton(),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  const _SidebarTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: isActive ? _C.primaryL : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Active indicator bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 3,
                  height: isActive ? 20 : 0,
                  decoration: BoxDecoration(
                    color: _C.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  item.icon,
                  size: 18,
                  color: isActive ? _C.primary : _C.muted,
                ),
                const SizedBox(width: 10),
                Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? _C.primary : _C.ink,
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _C.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = RouteGuard.user;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: () => _confirmLogout(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _C.dangerBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, size: 16, color: _C.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  user?.fullName ?? 'Sign Out',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _C.danger,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _C.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (result == true && context.mounted) {
      await RouteGuard.logout();
      if (context.mounted)
        Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
    }
  }
}

// ─── BOTTOM NAV (mobile) ─────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final List<CashierTab> tabs;
  final CashierTab current;
  final ValueChanged<CashierTab> onSelect;
  const _BottomNav({
    required this.tabs,
    required this.current,
    required this.onSelect,
  });

  IconData _icon(CashierTab t) {
    switch (t) {
      case CashierTab.home:
        return Icons.home_rounded;
      case CashierTab.pos:
        return Icons.point_of_sale_rounded;
      case CashierTab.orders:
        return Icons.receipt_long_rounded;
      case CashierTab.tables:
        return Icons.table_restaurant_rounded;
      case CashierTab.bookFacility:
        return Icons.event_available_rounded;
      default:
        return Icons.circle;
    }
  }

  String _label(CashierTab t) {
    switch (t) {
      case CashierTab.home:
        return 'Home';
      case CashierTab.pos:
        return 'Terminal';
      case CashierTab.orders:
        return 'Orders';
      case CashierTab.tables:
        return 'Tables';
      case CashierTab.bookFacility:
        return 'Facilities';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: tabs.map((t) {
            final active = t == current;
            return Expanded(
              child: InkWell(
                onTap: () => onSelect(t),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _icon(t),
                        size: 22,
                        color: active ? _C.primary : _C.muted,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _label(t),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: active ? _C.primary : _C.muted,
                        ),
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
