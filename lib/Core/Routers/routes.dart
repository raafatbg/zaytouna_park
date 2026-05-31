// lib/Core/Routers/routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zaytouna_park/Core/Routers/route_guard.dart';

// ─── AUTH IMPORTS ────────────────────────────────────────────────────────────

import 'package:zaytouna_park/Features/Auth/pages/Login/staff_login_page.dart';

// ─── ADMIN IMPORTS ───────────────────────────────────────────────────────────
import 'package:zaytouna_park/Features/admin/admin_shell/admin_shell.dart';
import 'package:zaytouna_park/Features/admin/Widgets/Categories/categories.dart';
import 'package:zaytouna_park/Features/admin/Widgets/Facilities/facilities.dart';
import 'package:zaytouna_park/Features/admin/Widgets/Inventory/inventory.dart';
import 'package:zaytouna_park/Features/admin/Widgets/Suppliers/suppliers.dart';

// ─── CASHIER IMPORTS ─────────────────────────────────────────────────────────
import 'package:zaytouna_park/Features/cashier/Shell/appshell.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Terminal/terminalscreen.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Orders/orders.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Customers/customers.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Tables/tables.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Tables/manage_tables_page.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Facilities/facilities_booking_page.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Facilities/facility_bookings_list_page.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Sales/sales.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Expenses/expenses.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Analytics/analatics.dart';
import 'package:zaytouna_park/Features/cashier/Widgets/Settings/settings.dart';

// ─── KITCHEN & MENU IMPORTS ──────────────────────────────────────────────────
import 'package:zaytouna_park/Features/kitchen/home_kitchen.dart';
import 'package:zaytouna_park/Features/kitchen/widgets/menu%20mangement/menumanagementscreen.dart';

// ─── ROUTE PATHS ─────────────────────────────────────────────────────────────
class Routes {
  Routes._();

  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String adminDashboard = '/admin-dashboard';
  static const String cashierDashboard = '/cashier-dashboard';
  static const String shell = '/shell';
  static const String kitchenDashboard = '/kitchen-dashboard';

  // Cashier / shared pages (pushed on top of shell)
  static const String pos = '/pos';
  static const String orders = '/orders';
  static const String customers = '/customers';
  static const String tables = '/tables';
  static const String manageTables = '/manage-tables';
  static const String bookings = '/bookings';
  static const String bookFacility = '/book-facility';
  static const String facilityBookings = '/facility-bookings';
  static const String sales = '/sales';
  static const String salesReport = '/sales-report';
  static const String expenses = '/expenses';
  static const String inventory = '/inventory';
  static const String menu = '/menu';
  static const String categories = '/categories';
  static const String suppliers = '/suppliers';
  static const String reports = '/reports';
  static const String facilities = '/facilities';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String playground = '/playground';
  static const String notFound = '/404';
}

// ─── PERMISSIONS ─────────────────────────────────────────────────────────────
class AppPermissions {
  AppPermissions._();

  static const String useTerminal = 'use_terminal';
  static const String createBookings = 'create_bookings';
  static const String viewKitchen = 'view_kitchen_display';
  static const String markReady = 'mark_items_ready';
  static const String manageStaff = 'manage_staff';
  static const String viewReports = 'view_reports';
  static const String manageSettings = 'manage_settings';
  static const String manageFacilities = 'manage_facilities';
  static const String refillMatte = 'refill_matte';

  /// Returns the required permission for a route, or null if open to all.
  static String? requiredFor(String route) {
    switch (route) {
      // These are open to cashier via useTerminal
      case Routes.pos:
      case Routes.orders:
      case Routes.customers:
      case Routes.tables:
      case Routes.manageTables:
      case Routes.sales:
      case Routes.expenses:
      case Routes.inventory:
      case Routes.menu:
        return useTerminal;

      case Routes.bookFacility:
      case Routes.facilityBookings:
        return createBookings;

      case Routes.reports:
        return viewReports;

      case Routes.facilities:
      case Routes.categories:
      case Routes.suppliers:
        return manageFacilities;

      case Routes.settings:
        return manageSettings;

      default:
        return null;
    }
  }
}

// ─── ROUTER ──────────────────────────────────────────────────────────────────
final appRouter = GoRouter(
  initialLocation: Routes.login,
  redirect: (context, state) {
    final loggedIn = RouteGuard.user != null;
    final isLogin = state.matchedLocation == Routes.login;
    if (!loggedIn && !isLogin) return Routes.login;
    return null;
  },
  routes: [
    // Auth Pages
    GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),

    // Core Role Shells
    GoRoute(
      path: Routes.adminDashboard,
      builder: (_, _) => const AdminShellScreen(),
    ),
    GoRoute(
      path: Routes.cashierDashboard,
      builder: (_, _) => const CashierShellScreen(),
    ),
    GoRoute(
      path: Routes.kitchenDashboard,
      builder: (_, _) => const KitchenScreen(),
    ),

    // ─── VALIDATED SUB-ROUTES FROM DIRECTORY TREE ────────────────────────────
    GoRoute(path: Routes.pos, builder: (_, _) => const UpgradedPOS()),
    GoRoute(
      path: Routes.bookFacility,
      builder: (_, _) => const FacilitiesBookingPage(),
    ),
    GoRoute(
      path: Routes.facilityBookings,
      builder: (_, _) => const FacilityBookingsListPage(),
    ),
    GoRoute(path: Routes.orders, builder: (_, _) => const OrdersScreen()),
    GoRoute(path: Routes.menu, builder: (_, _) => const MenuManagementScreen()),
    GoRoute(path: Routes.tables, builder: (_, _) => const TablesPage()),
    GoRoute(
      path: Routes.manageTables,
      builder: (_, _) => const ManageTablesPage(),
    ),
    GoRoute(path: Routes.inventory, builder: (_, _) => const InventoryScreen()),
    GoRoute(path: Routes.expenses, builder: (_, _) => const ExpensesScreen()),
    GoRoute(
      path: Routes.facilities,
      builder: (_, _) => const FacilitiesScreen(),
    ),
    GoRoute(path: Routes.sales, builder: (_, _) => const SalesScreen()),
    GoRoute(path: Routes.customers, builder: (_, _) => const CustomersScreen()),
    GoRoute(path: Routes.categories, builder: (_, _) => const CategoryScreen()),
    GoRoute(path: Routes.suppliers, builder: (_, _) => const SuppliersScreen()),
    GoRoute(path: Routes.reports, builder: (_, _) => const AnalyticsScreen()),
    GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
  ],

  errorBuilder: (context, state) => Scaffold(
    backgroundColor: const Color(0xFFFFF5F0),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 56,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 16),
          Text(
            state.error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => context.go(Routes.login),
            child: const Text('Go to Login'),
          ),
        ],
      ),
    ),
  ),
);
