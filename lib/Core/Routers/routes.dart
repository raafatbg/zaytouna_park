// lib/Core/Routers/routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zaytouna_park/Core/Routers/route_guard.dart';
import 'package:zaytouna_park/Features/Home/Shell/admin_shell.dart';
import 'package:zaytouna_park/Features/Home/Shell/cashier_shell.dart';
import 'package:zaytouna_park/Features/kitchen/home_kitchen.dart';
import 'package:zaytouna_park/Features/auth/login_screen.dart';

// ─── ROUTE PATHS ─────────────────────────────────────────────────────────────
class Routes {
  Routes._();

  static const String login = '/login';
  static const String adminDashboard = '/admin-dashboard';
  static const String cashierDashboard = '/cashier-dashboard'; // ← ADDED
  static const String kitchenDashboard = '/kitchen-dashboard';

  // Cashier / shared pages (pushed on top of shell)
  static const String pos = '/pos';
  static const String orders = '/orders';
  static const String customers = '/customers';
  static const String tables = '/tables';
  static const String manageTables = '/manage-tables';
  static const String bookFacility = '/book-facility';
  static const String facilityBookings = '/facility-bookings';
  static const String sales = '/sales';
  static const String expenses = '/expenses';
  static const String inventory = '/inventory';
  static const String menu = '/menu';
  static const String categories = '/categories';
  static const String suppliers = '/suppliers';
  static const String reports = '/reports';
  static const String facilities = '/facilities';
  static const String settings = '/settings';
  static const String playground = '/playground';
}

// ─── PERMISSIONS ─────────────────────────────────────────────────────────────
class AppPermissions {
  AppPermissions._();

  static const String useTerminal = 'useTerminal';
  static const String createBookings = 'createBookings';
  static const String viewKitchen = 'viewKitchenDisplay';
  static const String markReady = 'markItemsReady';
  static const String manageStaff = 'manageStaff';
  static const String viewReports = 'viewReports';
  static const String manageSettings = 'manageSettings';
  static const String manageFacilities = 'manageFacilities';
  static const String refillMatte = 'refillMatte';

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
    // Auth
    GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),

    // Admin shell
    GoRoute(
      path: Routes.adminDashboard,
      builder: (_, __) => const AdminShellScreen(),
    ),

    // Cashier shell  ← KEY FIX: this makes /cashier-dashboard work
    GoRoute(
      path: Routes.cashierDashboard,
      builder: (_, __) => const CashierShellScreen(),
    ),

    // Kitchen
    GoRoute(
      path: Routes.kitchenDashboard,
      builder: (_, __) => const KitchenScreen(),
    ),
  ],

  errorBuilder: (context, state) => Scaffold(
    backgroundColor: const Color(0xFFFFF5F0),
    body: Center(
      child: Column(
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
